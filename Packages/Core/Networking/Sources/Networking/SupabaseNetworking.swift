import Foundation
import Models
import Supabase

public struct SupabaseNetworking: ATFNetworking {

    private let client: SupabaseClient

    public init(url: URL, anonKey: String) {
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // MARK: - Auth

    public func signIn(email: String, password: String) async throws -> AppUser {
        let session = try await client.auth.signIn(email: email, password: password)
        return try await resolveUser(session.user)
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
            let userActive = link.is_active ?? true
            let status = link.tenants.subscription_status
            let tenantActive = link.tenants.is_active ?? true
            let statusOK = status == nil || ["trial", "active", "past_due"].contains(status)
            return roleOK && userActive && tenantActive && statusOK
        }

        let tenantIDs = validLinks.map { $0.tenants.id.uuidString.lowercased() }
        struct CountRow: Decodable, Sendable { let tenant_id: UUID }
        let counts: [CountRow] = (try? await client
            .from("menu_items")
            .select("tenant_id")
            .in("tenant_id", value: tenantIDs)
            .execute()
            .value) ?? []

        let countMap = Dictionary(grouping: counts, by: { $0.tenant_id }).mapValues { $0.count }

        return validLinks.map { link in
            Restaurant(
                id: link.tenants.id,
                name: link.tenants.name,
                city: link.tenants.city ?? "",
                role: RestaurantRole(rawValue: link.role) ?? .manager,
                dishCount: countMap[link.tenants.id] ?? 0,
                photoURL: link.tenants.logo_url.flatMap(URL.init)
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
            let categories: CategoryRow?
            struct CategoryRow: Decodable, Sendable { let name: String }
        }

        let rows: [ItemRow] = try await client
            .from("menu_items")
            .select("id, name, price, description, image_url, is_available, is_featured, categories(name)")
            .eq("tenant_id", value: restaurantID.uuidString)
            .execute()
            .value

        return rows.map { row in
            MenuItem(
                id: row.id,
                name: row.name,
                price: Int(row.price),
                category: row.categories?.name ?? "Plat",
                photoURL: row.image_url.flatMap(URL.init),
                isAvailable: row.is_available ?? true,
                isFeatured: row.is_featured ?? false,
                description: row.description ?? ""
            )
        }
    }

    public func fetchCategories(restaurantID: UUID) async throws -> [String] {
        struct CatRow: Decodable, Sendable { let name: String }
        let rows: [CatRow] = try await client
            .from("categories")
            .select("name")
            .eq("tenant_id", value: restaurantID.uuidString)
            .order("display_order", ascending: true)
            .execute()
            .value
        return rows.map { $0.name }
    }

    public func createMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem {
        let categoryID = try await findOrCreateCategory(
            name: item.category,
            tenantID: restaurantID
        )

        struct Payload: Encodable {
            let id: String
            let name: String
            let price: Int
            let description: String
            let is_available: Bool
            let is_featured: Bool
            let category_id: String
            let tenant_id: String
            let image_source: String
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
                tenant_id: restaurantID.uuidString,
                image_source: "at_food_ios"
            ))
            .execute()

        return item
    }

    public func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        let path = "\(restaurantID.uuidString)/\(dishID.uuidString).jpg"

        try await client.storage
            .from("menu-items")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage.from("menu-items").getPublicURL(path: path)

        struct PhotoUpdate: Encodable { let image_url: String; let image_source: String }
        try await client
            .from("menu_items")
            .update(PhotoUpdate(image_url: publicURL.absoluteString, image_source: "at_food_ios"))
            .eq("id", value: dishID.uuidString)
            .execute()

        return publicURL
    }

    // MARK: - Drafts

    public func fetchDrafts(restaurantID: UUID) async throws -> [Draft] {
        struct DraftRow: Decodable, Sendable {
            let id: UUID
            let public_url: String?
            let status: String
        }

        // dish_photo_drafts requires AT Food V1 migration — return empty if table missing
        let rows: [DraftRow] = (try? await client
            .from("dish_photo_drafts")
            .select("id, public_url, status")
            .eq("tenant_id", value: restaurantID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []

        return rows.compactMap { row in
            guard let urlStr = row.public_url, let url = URL(string: urlStr) else { return nil }
            return Draft(id: row.id, photoURL: url, status: row.status == "attached" ? .attached : .pending)
        }
    }

    // MARK: - AI Retouch

    public func applyAIRetouch(dishID: UUID, effect: AIRetouchEffect) async throws -> URL {
        // Edge function not yet deployed
        throw URLError(.unsupportedURL)
    }

    // MARK: - Credits

    public func fetchCredits(userID: UUID) async throws -> Int {
        // ai_photo_credits uses tenant_id — returns 0 until AT Food V1 migration applied
        return 0
    }

    // MARK: - Helpers

    private func resolveUser(_ user: User) async throws -> AppUser {
        struct LinkRow: Decodable, Sendable {
            let tenants: TenantInfo
            struct TenantInfo: Decodable, Sendable {
                let subscription_plan: String?
            }
        }

        let links: [LinkRow] = (try? await client
            .from("admin_users")
            .select("tenants(subscription_plan)")
            .eq("user_id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value) ?? []

        let planStr = links.first?.tenants.subscription_plan ?? "starter"
        let plan = AppPlan(fromDB: planStr)
        let name = user.email?.components(separatedBy: "@").first ?? "Utilisateur"
        return AppUser(id: user.id, name: name, email: user.email ?? "", plan: plan)
    }

    private func findOrCreateCategory(name: String, tenantID: UUID) async throws -> UUID {
        struct CategoryRow: Decodable, Sendable { let id: UUID }

        let existing: [CategoryRow] = try await client
            .from("categories")
            .select("id")
            .eq("tenant_id", value: tenantID.uuidString)
            .eq("name", value: name)
            .execute()
            .value

        if let found = existing.first { return found.id }

        struct InsertPayload: Encodable { let name: String; let tenant_id: String }
        let created: CategoryRow = try await client
            .from("categories")
            .insert(InsertPayload(name: name, tenant_id: tenantID.uuidString))
            .select("id")
            .single()
            .execute()
            .value

        return created.id
    }
}
