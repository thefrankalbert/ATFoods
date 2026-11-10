import Foundation
import Models
import Supabase

public enum SupabaseNetworkingError: UserFacingError {
    case notAllowed
    case notFound

    public var errorDescription: String? {
        switch self {
        case .notAllowed: "Modification refusée : vos droits sur ce restaurant ne le permettent pas."
        case .notFound: "Ce plat n'existe plus. Actualisez le menu."
        }
    }
}

public struct SupabaseNetworking: ATFNetworking {

    private let client: SupabaseClient
    private static let bucket = "menu-items"

    /// Storage sometimes answers a one-off 5xx (seen: 520): try once more before showing an error.
    private func uploadPhoto(_ data: Data, to path: String) async throws {
        let options = FileOptions(contentType: "image/jpeg")
        do {
            try await client.storage.from(Self.bucket).upload(path, data: data, options: options)
        } catch {
            try await Task.sleep(for: .seconds(1))
            try await client.storage.from(Self.bucket).upload(path, data: data, options: options)
        }
    }

    public init(url: URL, anonKey: String) {
        // 20 s without data = failure: a dead network shows an error instead of a minute-long spinner.
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true),
                global: .init(session: URLSession(configuration: config))
            )
        )
    }

    // MARK: - Auth

    public func signIn(email: String, password: String) async throws -> AppUser {
        let session = try await client.auth.signIn(email: email, password: password)
        return await resolveUser(session.user)
    }

    public func restoreSession() async -> AppUser? {
        // Keychain session from a previous launch, refreshed by the SDK if the token expired.
        do {
            return await resolveUser(try await client.auth.session.user)
        } catch where UserMessage.isOffline(error) {
            // Offline: keep the user signed in with the stored session; screens show retry states.
            return client.auth.currentSession.map { localUser($0.user) }
        } catch {
            return nil   // no session, or refresh token revoked: real sign-out
        }
    }

    public func signOut() async throws {
        // .local: leaving the app must not sign the owner out of the web dashboard (default is .global).
        // The SDK forgets the session on this device before calling the server, so a network error changes nothing.
        try? await client.auth.signOut(scope: .local)
    }

    public func deleteAccount() async throws -> AccountDeletionResult {
        guard let userID = client.auth.currentUser?.id else { throw SupabaseNetworkingError.notAllowed }
        // Remove this user's drafts through the API first so their photo files go too
        // (the database function only deletes rows).
        struct DraftRow: Decodable, Sendable { let id: UUID; let storage_path: String; let public_url: String? }
        let rows: [DraftRow] = try await client
            .from("dish_photo_drafts").select("id, storage_path, public_url")
            .eq("created_by", value: userID.uuidString)
            .execute().value
        let drafts = rows.compactMap { row in
            row.public_url.flatMap(URL.init).map { Draft(id: row.id, photoURL: $0, storagePath: row.storage_path) }
        }
        try? await deleteDrafts(drafts)

        let status: String = try await client.rpc("delete_my_account").execute().value
        switch status {
        case "deleted":
            try? await client.auth.signOut()   // session already invalid server-side; clear the keychain
            return .deleted
        case let s where s.hasPrefix("sole_owner:"):
            return .soleOwner(restaurant: String(s.dropFirst("sole_owner:".count)))
        case "group_owner":
            return .groupOwner
        default:
            return .needsSupport
        }
    }

    // MARK: - Restaurants (= Tenants in À Table SaaS)

    public func fetchRestaurants(userID: UUID) async throws -> [Restaurant] {
        struct LinkRow: Decodable, Sendable {
            let role: String
            let is_active: Bool?
            let tenants: TenantDB
            struct TenantDB: Decodable, Sendable {
                let id: UUID
                let name: String
                let city: String?
                let logo_url: String?
                let subscription_plan: String?
                let subscription_status: String?
                let is_active: Bool?
                let currency: String?
                let at_food_enabled: Bool?
            }
        }

        let links: [LinkRow] = try await client
            .from("admin_users")
            .select("role, is_active, tenants(id, name, city, logo_url, subscription_plan, subscription_status, is_active, currency, at_food_enabled)")
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value

        let validLinks = links.filter { link in
            let roleOK = ["owner", "admin", "manager"].contains(link.role)
            // RLS on drafts/categories requires is_active = true exactly (NULL is rejected).
            let userActive = link.is_active == true
            let status = link.tenants.subscription_status
            let tenantActive = link.tenants.is_active ?? true
            let statusOK = status == nil || ["trial", "active", "past_due"].contains(status)
            let atFoodOK = link.tenants.at_food_enabled ?? true   // tenants.at_food_enabled (default true)
            return roleOK && userActive && tenantActive && statusOK && atFoodOK
        }

        // Per tenant, in parallel: can this user edit the menu (same rule as the database policies)?
        // and how many live dishes (head COUNT, exact beyond PostgREST's 1000-row page).
        struct PermissionParams: Encodable, Sendable { let p_tenant: String; let p_perm: String }
        let details = await withTaskGroup(of: (UUID, Bool, Int).self) { group in
            for link in validLinks {
                let tenantID = link.tenants.id
                group.addTask {
                    async let canEdit: Bool? = try? await client
                        .rpc("has_tenant_write_permission",
                             params: PermissionParams(p_tenant: tenantID.uuidString, p_perm: "menu.edit"))
                        .execute()
                        .value
                    async let count = try? await client
                        .from("menu_items")
                        .select("id", head: true, count: .exact)
                        .eq("tenant_id", value: tenantID.uuidString)
                        .is("deleted_at", value: nil)
                        .execute()
                        .count
                    // Unknown permission (network blip) → keep the restaurant; writes still enforce RLS.
                    return (tenantID, await canEdit ?? true, await count ?? 0)
                }
            }
            var map: [UUID: (canEdit: Bool, count: Int)] = [:]
            for await (id, canEdit, count) in group { map[id] = (canEdit, count) }
            return map
        }

        return validLinks.filter { details[$0.tenants.id]?.canEdit ?? true }.map { link in
            Restaurant(
                id: link.tenants.id,
                name: link.tenants.name,
                city: link.tenants.city ?? "",
                role: RestaurantRole(rawValue: link.role) ?? .manager,
                dishCount: details[link.tenants.id]?.count ?? 0,
                photoURL: link.tenants.logo_url.flatMap(URL.init),
                plan: AppPlan(fromDB: link.tenants.subscription_plan ?? "starter"),
                currency: link.tenants.currency ?? "XAF"
            )
        }
    }

    // MARK: - Menu Items

    public func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem] {
        struct ItemRow: Decodable, Sendable {
            let id: UUID
            let name: String
            let price: Decimal
            let description: String?
            let image_url: String?
            let is_available: Bool?
            let is_featured: Bool?
            let category_id: UUID?
            let name_en: String?
            let description_en: String?
            let allergens: [String]?
            let calories: Int?
            let images: [String]?
            let created_at: Date?
            let categories: CategoryRow?
            struct CategoryRow: Decodable, Sendable { let name: String }
        }

        let rows: [ItemRow] = try await client
            .from("menu_items")
            .select("id, name, price, description, image_url, is_available, is_featured, category_id, name_en, description_en, allergens, calories, images, created_at, categories(name)")
            .eq("tenant_id", value: restaurantID.uuidString)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: true)   // web storefront order inside a category
            .execute()
            .value

        return rows.map { row in
            var item = MenuItem(
                id: row.id,
                name: row.name,
                price: row.price,
                category: row.categories?.name ?? "",
                categoryID: row.category_id,
                photoURL: row.image_url.flatMap(URL.init),
                isAvailable: row.is_available ?? true,
                isFeatured: row.is_featured ?? false,
                description: row.description ?? "",
                createdAt: row.created_at ?? Date()
            )
            item.nameEn = row.name_en ?? ""
            item.descriptionEn = row.description_en ?? ""
            item.allergens = row.allergens ?? []
            item.calories = row.calories
            item.gallery = (row.images ?? []).filter { $0 != row.image_url }.compactMap(URL.init)
            return item
        }
    }

    public func fetchCategories(restaurantID: UUID) async throws -> [MenuCategory] {
        struct CatRow: Decodable, Sendable { let id: UUID; let name: String; let menu_id: UUID? }
        async let rows: [CatRow] = client
            .from("categories")
            .select("id, name, menu_id")
            .eq("tenant_id", value: restaurantID.uuidString)
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value
        async let menus = menuNodes(restaurantID: restaurantID)
        let categories = try await rows.map { MenuCategory(id: $0.id, name: $0.name, menuID: $0.menu_id) }
        return MenuOrder.categories(categories, menus: try await menus.map(\.node))
    }

    public func fetchMenus(restaurantID: UUID) async throws -> [MenuRef] {
        let rows = try await menuNodes(restaurantID: restaurantID)
        let byID = Dictionary(uniqueKeysWithValues: rows.map { ($0.node.id, $0) })
        return MenuOrder.menuIDs(rows.map(\.node)).compactMap { id in
            guard let row = byID[id] else { return nil }
            let parent = row.node.parentID.flatMap { byID[$0]?.name }
            return MenuRef(id: id, name: parent.map { "\($0) › \(row.name)" } ?? row.name)
        }
    }

    private func menuNodes(restaurantID: UUID) async throws -> [(node: MenuOrder.MenuNode, name: String)] {
        struct MenuRow: Decodable, Sendable {
            let id: UUID; let name: String; let parent_menu_id: UUID?
            let display_order: Int?; let is_transversal_menu: Bool?
        }
        let rows: [MenuRow] = try await client
            .from("menus")
            .select("id, name, parent_menu_id, display_order, is_transversal_menu")
            .eq("tenant_id", value: restaurantID.uuidString)
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value
        return rows.map {
            (MenuOrder.MenuNode(id: $0.id, parentID: $0.parent_menu_id, displayOrder: $0.display_order ?? 0,
                                isTransversal: $0.is_transversal_menu ?? false), $0.name)
        }
    }

    public func createCategory(name: String, menuID: UUID?, restaurantID: UUID) async throws -> MenuCategory {
        struct OrderRow: Decodable, Sendable { let display_order: Int? }
        let last: [OrderRow] = try await client
            .from("categories")
            .select("display_order")
            .eq("tenant_id", value: restaurantID.uuidString)
            .order("display_order", ascending: false)
            .limit(1)
            .execute()
            .value

        struct InsertPayload: Encodable {
            let name: String
            let tenant_id: String
            let menu_id: String?
            let display_order: Int
        }
        struct CreatedRow: Decodable, Sendable { let id: UUID; let name: String; let menu_id: UUID? }
        let created: CreatedRow = try await client
            .from("categories")
            .insert(InsertPayload(
                name: name,
                tenant_id: restaurantID.uuidString,
                menu_id: menuID?.uuidString,
                display_order: (last.first?.display_order ?? -1) + 1   // appended at the end, like the web admin
            ))
            .select("id, name, menu_id")
            .single()
            .execute()
            .value
        return MenuCategory(id: created.id, name: created.name, menuID: created.menu_id)
    }

    public func createMenuItem(_ item: MenuItem, categoryID: UUID, restaurantID: UUID) async throws -> MenuItem {
        try await client
            .from("menu_items")
            .insert(DishFields(item, categoryID: categoryID, id: item.id, tenantID: restaurantID))
            .execute()

        var created = item
        created.categoryID = categoryID
        return created
    }

    public func updateMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem {
        guard let categoryID = item.categoryID else { throw SupabaseNetworkingError.notFound }
        struct UpdatedRow: Decodable, Sendable { let id: UUID }
        let updated: [UpdatedRow] = try await client
            .from("menu_items")
            .update(DishFields(item, categoryID: categoryID))
            .eq("id", value: item.id.uuidString)
            .eq("tenant_id", value: restaurantID.uuidString)
            .is("deleted_at", value: nil)
            .select("id")
            .execute()
            .value
        // 0 rows: dish deleted on the web meanwhile, or rights revoked.
        guard !updated.isEmpty else { throw SupabaseNetworkingError.notAllowed }
        return item
    }

    public func setAvailability(dishID: UUID, isAvailable: Bool, restaurantID: UUID) async throws {
        struct Payload: Encodable { let is_available: Bool }
        struct UpdatedRow: Decodable, Sendable { let id: UUID }
        let updated: [UpdatedRow] = try await client
            .from("menu_items")
            .update(Payload(is_available: isAvailable))
            .eq("id", value: dishID.uuidString)
            .eq("tenant_id", value: restaurantID.uuidString)
            .is("deleted_at", value: nil)
            .select("id")
            .execute()
            .value
        // 0 rows: dish deleted on the web meanwhile, or rights revoked.
        guard !updated.isEmpty else { throw SupabaseNetworkingError.notAllowed }
    }

    // MARK: - Photos

    public func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        let path = Self.dishPhotoPath(dishID: dishID, restaurantID: restaurantID)
        try await uploadPhoto(imageData, to: path)
        return try await setDishImage(dishID: dishID, newPath: path)
    }

    // MARK: - Drafts

    public func saveDraft(imageData: Data, restaurantID: UUID) async throws -> Draft {
        guard let userID = client.auth.currentUser?.id else { throw SupabaseNetworkingError.notAllowed }
        let id = UUID()
        let path = "\(restaurantID.uuidString.lowercased())/drafts/\(id.uuidString.lowercased()).jpg"
        try await uploadPhoto(imageData, to: path)
        let publicURL = try client.storage.from(Self.bucket).getPublicURL(path: path)

        struct Payload: Encodable {
            let id: String
            let tenant_id: String
            let created_by: String
            let storage_path: String
            let public_url: String
            let status: String
        }
        do {
            try await client
                .from("dish_photo_drafts")
                .insert(Payload(
                    id: id.uuidString,
                    tenant_id: restaurantID.uuidString,
                    created_by: userID.uuidString,
                    storage_path: path,
                    public_url: publicURL.absoluteString,
                    status: "pending"
                ))
                .execute()
        } catch {
            _ = try? await client.storage.from(Self.bucket).remove(paths: [path])   // no orphan file
            throw error
        }
        return Draft(id: id, photoURL: publicURL, storagePath: path)
    }

    public func fetchDrafts(restaurantID: UUID) async throws -> [Draft] {
        struct DraftRow: Decodable, Sendable {
            let id: UUID
            let storage_path: String
            let public_url: String?
            let created_at: Date?
        }
        let rows: [DraftRow] = try await client
            .from("dish_photo_drafts")
            .select("id, storage_path, public_url, created_at")
            .eq("tenant_id", value: restaurantID.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.compactMap { row in
            guard let url = row.public_url.flatMap(URL.init) else { return nil }
            return Draft(id: row.id, photoURL: url, storagePath: row.storage_path, createdAt: row.created_at ?? Date())
        }
    }

    public func attachDraft(_ draft: Draft, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        // Server-side copy: no re-upload, and the dish owns its own file (draft cleanup can't break it).
        let path = Self.dishPhotoPath(dishID: dishID, restaurantID: restaurantID)
        try await client.storage.from(Self.bucket).copy(from: draft.storagePath, to: path)
        let url = try await setDishImage(dishID: dishID, newPath: path)
        // Dish is updated: the draft is consumed. A failure here only leaves a draft to delete by hand.
        try? await deleteDrafts([draft])
        return url
    }

    public func deleteDrafts(_ drafts: [Draft]) async throws {
        guard !drafts.isEmpty else { return }
        struct DeletedRow: Decodable, Sendable { let id: UUID }
        // RLS-denied deletes affect 0 rows without erroring: only remove files of rows really deleted,
        // so a draft can never point at a missing file.
        let deleted: [DeletedRow] = try await client
            .from("dish_photo_drafts")
            .delete()
            .in("id", values: drafts.map { $0.id.uuidString })
            .select("id")
            .execute()
            .value
        let deletedIDs = Set(deleted.map(\.id))
        let paths = drafts.filter { deletedIDs.contains($0.id) }.map(\.storagePath)
        if !paths.isEmpty {
            _ = try? await client.storage.from(Self.bucket).remove(paths: paths)
        }
        guard deletedIDs.count == drafts.count else { throw SupabaseNetworkingError.notAllowed }
    }

    // MARK: - Helpers

    /// Storage RLS compares the first folder to tenant uuid::text (lowercase).
    /// Unique suffix per upload: busts CDN cache and never collides on fast retries.
    private static func dishPhotoPath(dishID: UUID, restaurantID: UUID) -> String {
        "\(restaurantID.uuidString.lowercased())/\(dishID.uuidString.lowercased())-\(UUID().uuidString.prefix(8).lowercased()).jpg"
    }

    /// Points the dish at an uploaded file. On failure the new file is removed; on success the
    /// previous photo is removed if it lives in our bucket and no other dish uses it.
    private func setDishImage(dishID: UUID, newPath: String) async throws -> URL {
        let storage = client.storage.from(Self.bucket)
        let publicURL = try storage.getPublicURL(path: newPath)

        struct CurrentRow: Decodable, Sendable { let image_url: String?; let images: [String]? }
        struct PhotoUpdate: Encodable {
            let image_url: String
            let images: [String]
            let image_source: String
            let image_uploaded_at: String
            let image_uploaded_by: String?
        }
        struct UpdatedRow: Decodable, Sendable { let id: UUID }

        let previous: String?
        let updated: [UpdatedRow]
        do {
            let current: [CurrentRow] = try await client
                .from("menu_items").select("image_url, images").eq("id", value: dishID.uuidString)
                .execute().value
            guard let row = current.first else { throw SupabaseNetworkingError.notFound }
            previous = row.image_url
            // RLS-denied updates affect 0 rows without erroring: select back to detect it.
            updated = try await client
                .from("menu_items")
                .update(PhotoUpdate(
                    image_url: publicURL.absoluteString,
                    // The storefront detail sheet shows `images` first: keep the gallery in sync.
                    images: Self.gallery(row.images ?? [], replacing: previous, with: publicURL.absoluteString),
                    image_source: "at_food_ios",
                    image_uploaded_at: ISO8601DateFormatter().string(from: Date()),
                    image_uploaded_by: client.auth.currentUser?.id.uuidString
                ))
                .eq("id", value: dishID.uuidString)
                .select("id")
                .execute()
                .value
        } catch {
            _ = try? await storage.remove(paths: [newPath])
            throw error
        }
        guard !updated.isEmpty else {
            _ = try? await storage.remove(paths: [newPath])
            throw SupabaseNetworkingError.notAllowed
        }

        if let previous, previous != publicURL.absoluteString {
            await removeFileIfUnused(previous)
        }
        return publicURL
    }

    /// Deletes a photo file from our bucket once no dish references it (unsure → keep it).
    private func removeFileIfUnused(_ url: String) async {
        let storage = client.storage.from(Self.bucket)
        // External URL or another bucket: never ours to delete.
        guard let probe = try? storage.getPublicURL(path: "x").absoluteString,
              let path = Self.storagePath(fromPublicURL: url, newURL: probe, newPath: "x") else { return }
        struct Ref: Decodable, Sendable { let id: UUID }
        async let byURL: [Ref]? = try? await client
            .from("menu_items").select("id").eq("image_url", value: url).limit(1)
            .execute().value
        async let byGallery: [Ref]? = try? await client
            .from("menu_items").select("id")
            .filter("images", operator: "cs", value: Self.jsonArray([url])).limit(1)
            .execute().value
        if let a = await byURL, let b = await byGallery, a.isEmpty, b.isEmpty {
            _ = try? await storage.remove(paths: [path])
        }
    }

    // MARK: - Gallery (extra photos)

    public func addGalleryPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> [URL] {
        let path = Self.dishPhotoPath(dishID: dishID, restaurantID: restaurantID)
        try await uploadPhoto(imageData, to: path)
        let url = try client.storage.from(Self.bucket).getPublicURL(path: path).absoluteString
        do {
            return try await setGallery(dishID: dishID, restaurantID: restaurantID) { $0 + [url] }
        } catch {
            _ = try? await client.storage.from(Self.bucket).remove(paths: [path])
            throw error
        }
    }

    public func removeGalleryPhoto(_ url: URL, fromDishID dishID: UUID, restaurantID: UUID) async throws -> [URL] {
        let gallery = try await setGallery(dishID: dishID, restaurantID: restaurantID) {
            $0.filter { $0 != url.absoluteString }
        }
        await removeFileIfUnused(url.absoluteString)
        return gallery
    }

    /// Rewrites menu_items.images as the web does: [main photo] + extras.
    private func setGallery(dishID: UUID, restaurantID: UUID,
                            change: ([String]) -> [String]) async throws -> [URL] {
        struct Row: Decodable, Sendable { let image_url: String?; let images: [String]? }
        struct Update: Encodable { let images: [String] }
        struct UpdatedRow: Decodable, Sendable { let id: UUID }
        let rows: [Row] = try await client
            .from("menu_items").select("image_url, images")
            .eq("id", value: dishID.uuidString).eq("tenant_id", value: restaurantID.uuidString)
            .execute().value
        guard let row = rows.first else { throw SupabaseNetworkingError.notFound }
        let extras = change((row.images ?? []).filter { $0 != row.image_url })
        let updated: [UpdatedRow] = try await client
            .from("menu_items")
            .update(Update(images: (row.image_url.map { [$0] } ?? []) + extras))
            .eq("id", value: dishID.uuidString).eq("tenant_id", value: restaurantID.uuidString)
            .select("id")
            .execute().value
        guard !updated.isEmpty else { throw SupabaseNetworkingError.notAllowed }
        return extras.compactMap(URL.init)
    }

    /// Gallery after a photo change: previous primary replaced in place, else new photo first.
    /// An empty gallery stays empty (the storefront then falls back to image_url).
    /// Same rule as the web (attabl-saas useItemForm.ts): main photo first, then the extras, no duplicates.
    static func gallery(_ images: [String], replacing previous: String?, with new: String) -> [String] {
        var extras: [String] = []
        for url in images where url != previous && url != new && !extras.contains(url) { extras.append(url) }
        return [new] + extras
    }

    static func jsonArray(_ values: [String]) -> String {
        (try? String(data: JSONEncoder().encode(values), encoding: .utf8)) ?? "[]"
    }

    /// Old public URL → storage path, using the new URL's prefix as the bucket base.
    /// nil for files outside our bucket (external URLs are never deleted).
    static func storagePath(fromPublicURL url: String, newURL: String, newPath: String) -> String? {
        guard newURL.hasSuffix(newPath) else { return nil }
        let prefix = String(newURL.dropLast(newPath.count))   // ".../object/public/menu-items/"
        guard url.hasPrefix(prefix), url.count > prefix.count else { return nil }
        let path = String(url.dropFirst(prefix.count))
        return path.removingPercentEncoding ?? path
    }

    /// Display name from admin_users.full_name (as on the web); empty when unknown.
    private func resolveUser(_ user: User) async -> AppUser {
        struct NameRow: Decodable, Sendable { let full_name: String? }
        let rows: [NameRow] = (try? await client
            .from("admin_users").select("full_name")
            .eq("user_id", value: user.id.uuidString)
            .not("full_name", operator: .is, value: "null")
            .limit(1)
            .execute().value) ?? []
        var resolved = localUser(user)
        resolved.name = rows.first?.full_name?.trimmingCharacters(in: .whitespaces) ?? ""
        return resolved
    }

    private func localUser(_ user: User) -> AppUser {
        AppUser(id: user.id, name: "", email: user.email ?? "")
    }
}
