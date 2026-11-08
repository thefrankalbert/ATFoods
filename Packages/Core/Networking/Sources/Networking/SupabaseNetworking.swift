import Foundation
import Models
import Supabase

public enum SupabaseNetworkingError: LocalizedError {
    case notAllowed

    public var errorDescription: String? {
        "Modification refusée : vérifie tes droits sur ce restaurant."
    }
}

public struct SupabaseNetworking: ATFNetworking {

    private let client: SupabaseClient
    private static let bucket = "menu-items"

    public init(url: URL, anonKey: String) {
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(auth: .init(emitLocalSessionAsInitialSession: true))
        )
    }

    // MARK: - Auth

    public func signIn(email: String, password: String) async throws -> AppUser {
        let session = try await client.auth.signIn(email: email, password: password)
        return resolveUser(session.user)
    }

    public func restoreSession() async -> AppUser? {
        // Keychain session from a previous launch; refreshed by the SDK if the token expired.
        guard let session = try? await client.auth.session else { return nil }
        return resolveUser(session.user)
    }

    public func signOut() async throws {
        try await client.auth.signOut()
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
            }
        }

        let links: [LinkRow] = try await client
            .from("admin_users")
            .select("role, is_active, tenants(id, name, city, logo_url, subscription_plan, subscription_status, is_active)")
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
            return roleOK && userActive && tenantActive && statusOK
        }

        // One COUNT per tenant (head request, no rows): exact even beyond PostgREST's 1000-row page.
        var countMap: [UUID: Int] = [:]
        for link in validLinks {
            let response = try await client
                .from("menu_items")
                .select("id", head: true, count: .exact)
                .eq("tenant_id", value: link.tenants.id.uuidString)
                .is("deleted_at", value: nil)
                .execute()
            countMap[link.tenants.id] = response.count ?? 0
        }

        return validLinks.map { link in
            Restaurant(
                id: link.tenants.id,
                name: link.tenants.name,
                city: link.tenants.city ?? "",
                role: RestaurantRole(rawValue: link.role) ?? .manager,
                dishCount: countMap[link.tenants.id] ?? 0,
                photoURL: link.tenants.logo_url.flatMap(URL.init),
                plan: AppPlan(fromDB: link.tenants.subscription_plan ?? "starter")
            )
        }
    }

    // MARK: - Menu Items

    public func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem] {
        struct ItemRow: Decodable, Sendable {
            let id: UUID
            let name: String
            let price: Double
            let description: String?
            let image_url: String?
            let is_available: Bool?
            let is_featured: Bool?
            let category_id: UUID?
            let categories: CategoryRow?
            struct CategoryRow: Decodable, Sendable { let name: String }
        }

        let rows: [ItemRow] = try await client
            .from("menu_items")
            .select("id, name, price, description, image_url, is_available, is_featured, category_id, categories(name)")
            .eq("tenant_id", value: restaurantID.uuidString)
            .is("deleted_at", value: nil)
            .order("name", ascending: true)
            .execute()
            .value

        return rows.map { row in
            MenuItem(
                id: row.id,
                name: row.name,
                price: Int(row.price.rounded()),
                category: row.categories?.name ?? "",
                categoryID: row.category_id,
                photoURL: row.image_url.flatMap(URL.init),
                isAvailable: row.is_available ?? true,
                isFeatured: row.is_featured ?? false,
                description: row.description ?? ""
            )
        }
    }

    public func fetchCategories(restaurantID: UUID) async throws -> [MenuCategory] {
        struct CatRow: Decodable, Sendable { let id: UUID; let name: String; let menu_id: UUID? }
        let rows: [CatRow] = try await client
            .from("categories")
            .select("id, name, menu_id")
            .eq("tenant_id", value: restaurantID.uuidString)
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value
        return rows.map { MenuCategory(id: $0.id, name: $0.name, menuID: $0.menu_id) }
    }

    public func fetchMenus(restaurantID: UUID) async throws -> [MenuRef] {
        struct MenuRow: Decodable, Sendable { let id: UUID; let name: String; let parent_menu_id: UUID? }
        let rows: [MenuRow] = try await client
            .from("menus")
            .select("id, name, parent_menu_id")
            .eq("tenant_id", value: restaurantID.uuidString)
            .eq("is_active", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value
        let names = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.name) })
        return rows.map { row in
            let label = row.parent_menu_id.flatMap { names[$0] }.map { "\($0) › \(row.name)" } ?? row.name
            return MenuRef(id: row.id, name: label)
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
        struct Payload: Encodable {
            let id: String
            let name: String
            let price: Int
            let description: String
            let is_available: Bool
            let is_featured: Bool
            let category_id: String
            let tenant_id: String
        }

        try await client
            .from("menu_items")
            .insert(Payload(
                id: item.id.uuidString,
                name: item.name,
                price: item.price,
                description: item.description,
                is_available: item.isAvailable,
                is_featured: item.isFeatured,
                category_id: categoryID.uuidString,
                tenant_id: restaurantID.uuidString
            ))
            .execute()

        var created = item
        created.categoryID = categoryID
        return created
    }

    // MARK: - Photos

    public func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        let path = Self.dishPhotoPath(dishID: dishID, restaurantID: restaurantID)
        try await client.storage
            .from(Self.bucket)
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        return try await setDishImage(dishID: dishID, newPath: path)
    }

    // MARK: - Drafts

    public func saveDraft(imageData: Data, restaurantID: UUID) async throws -> Draft {
        guard let userID = client.auth.currentUser?.id else { throw SupabaseNetworkingError.notAllowed }
        let id = UUID()
        let path = "\(restaurantID.uuidString.lowercased())/drafts/\(id.uuidString.lowercased()).jpg"
        try await client.storage
            .from(Self.bucket)
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
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
        try await client
            .from("dish_photo_drafts")
            .delete()
            .in("id", values: drafts.map { $0.id.uuidString })
            .execute()
        _ = try? await client.storage.from(Self.bucket).remove(paths: drafts.map(\.storagePath))
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

        struct CurrentRow: Decodable, Sendable { let image_url: String? }
        struct PhotoUpdate: Encodable {
            let image_url: String
            let image_source: String
            let image_uploaded_at: String
            let image_uploaded_by: String?
        }
        struct UpdatedRow: Decodable, Sendable { let id: UUID }

        let previous: String?
        let updated: [UpdatedRow]
        do {
            let current: [CurrentRow] = try await client
                .from("menu_items").select("image_url").eq("id", value: dishID.uuidString)
                .execute().value
            previous = current.first?.image_url
            // RLS-denied updates affect 0 rows without erroring: select back to detect it.
            updated = try await client
                .from("menu_items")
                .update(PhotoUpdate(
                    image_url: publicURL.absoluteString,
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

        if let previous, previous != publicURL.absoluteString,
           let oldPath = Self.storagePath(fromPublicURL: previous, newURL: publicURL.absoluteString, newPath: newPath) {
            struct Ref: Decodable, Sendable { let id: UUID }
            let others: [Ref] = (try? await client
                .from("menu_items").select("id").eq("image_url", value: previous).limit(1)
                .execute().value) ?? [Ref(id: dishID)]   // unsure → keep the file
            if others.isEmpty {
                _ = try? await storage.remove(paths: [oldPath])
            }
        }
        return publicURL
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

    private func resolveUser(_ user: User) -> AppUser {
        let name = user.email?.components(separatedBy: "@").first ?? "Utilisateur"
        return AppUser(id: user.id, name: name, email: user.email ?? "")
    }
}
