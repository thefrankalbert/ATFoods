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

    // MARK: - Restaurants

    public func fetchRestaurants(userID: UUID) async throws -> [Restaurant] {
        struct LinkRow: Decodable, Sendable {
            let role: String
            let restaurants: RestaurantDB
            struct RestaurantDB: Decodable, Sendable {
                let id: UUID
                let name: String
                let city: String?
                let image_url: String?
            }
        }
        struct CountRow: Decodable, Sendable {
            let restaurant_id: UUID
        }

        let links: [LinkRow] = try await client
            .from("user_restaurants")
            .select("role, restaurants(id, name, city, image_url)")
            .execute()
            .value

        let restaurantIDs = links.map { $0.restaurants.id.uuidString.lowercased() }
        let counts: [CountRow] = (try? await client
            .from("menu_items")
            .select("restaurant_id")
            .in("restaurant_id", value: restaurantIDs)
            .execute()
            .value) ?? []

        let countMap = Dictionary(grouping: counts, by: { $0.restaurant_id })
            .mapValues { $0.count }

        return links.map { link in
            Restaurant(
                id: link.restaurants.id,
                name: link.restaurants.name,
                city: link.restaurants.city ?? "",
                role: RestaurantRole(rawValue: link.role) ?? .manager,
                dishCount: countMap[link.restaurants.id] ?? 0,
                photoURL: link.restaurants.image_url.flatMap(URL.init)
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
            .eq("restaurant_id", value: restaurantID.uuidString)
            .execute()
            .value

        return rows.map { row in
            MenuItem(
                id: row.id,
                name: row.name,
                price: Int(row.price),
                category: MenuCategory(rawValue: row.categories?.name ?? "") ?? .plat,
                photoURL: row.image_url.flatMap(URL.init),
                isAvailable: row.is_available ?? true,
                isFeatured: row.is_featured ?? false,
                description: row.description ?? ""
            )
        }
    }

    public func createMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem {
        let categoryID = try await findOrCreateCategory(
            name: item.category.rawValue,
            restaurantID: restaurantID
        )

        struct Payload: Encodable {
            let id: String
            let name: String
            let price: Int
            let description: String
            let is_available: Bool
            let is_featured: Bool
            let category_id: String
            let restaurant_id: String
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
                restaurant_id: restaurantID.uuidString
            ))
            .execute()

        return item
    }

    public func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        let path = "\(restaurantID.uuidString)/\(dishID.uuidString).jpg"

        try await client.storage
            .from("dishes")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage.from("dishes").getPublicURL(path: path)

        struct PhotoUpdate: Encodable { let image_url: String }
        try await client
            .from("menu_items")
            .update(PhotoUpdate(image_url: publicURL.absoluteString))
            .eq("id", value: dishID.uuidString)
            .execute()

        return publicURL
    }

    // MARK: - Drafts

    public func fetchDrafts(restaurantID: UUID) async throws -> [Draft] {
        struct DraftRow: Decodable, Sendable {
            let id: UUID
            let photo_url: String
            let status: String
        }

        let rows: [DraftRow] = try await client
            .from("drafts")
            .select("id, photo_url, status")
            .eq("restaurant_id", value: restaurantID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.compactMap { row in
            guard let url = URL(string: row.photo_url) else { return nil }
            return Draft(id: row.id, photoURL: url, status: row.status == "attached" ? .attached : .pending)
        }
    }

    // MARK: - AI Retouch

    public func applyAIRetouch(dishID: UUID, effect: AIRetouchEffect) async throws -> URL {
        // Edge function not yet deployed — returns original photo URL in the meantime
        struct ItemRow: Decodable, Sendable { let image_url: String? }
        let row: ItemRow = try await client
            .from("menu_items")
            .select("image_url")
            .eq("id", value: dishID.uuidString)
            .single()
            .execute()
            .value
        guard let str = row.image_url, let url = URL(string: str) else {
            throw URLError(.badServerResponse)
        }
        return url
    }

    // MARK: - Credits

    public func fetchCredits(userID: UUID) async throws -> Int {
        struct CreditsRow: Decodable, Sendable { let balance: Int }
        let row: CreditsRow = try await client
            .from("ai_credits")
            .select("balance")
            .eq("user_id", value: userID.uuidString)
            .single()
            .execute()
            .value
        return row.balance
    }

    // MARK: - Helpers

    private func resolveUser(_ user: User) async throws -> AppUser {
        struct ProfileRow: Decodable, Sendable { let name: String; let plan: String }
        let profile = try? await client
            .from("profiles")
            .select("name, plan")
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
            .value as ProfileRow
        let plan = AppPlan(rawValue: profile?.plan ?? "starter") ?? .starter
        let name = profile?.name.nilIfEmpty
            ?? user.email?.components(separatedBy: "@").first
            ?? "Utilisateur"
        return AppUser(id: user.id, name: name, email: user.email ?? "", plan: plan)
    }

    private func findOrCreateCategory(name: String, restaurantID: UUID) async throws -> UUID {
        struct CategoryRow: Decodable, Sendable { let id: UUID }

        let existing: [CategoryRow] = try await client
            .from("categories")
            .select("id")
            .eq("restaurant_id", value: restaurantID.uuidString)
            .eq("name", value: name)
            .execute()
            .value

        if let found = existing.first { return found.id }

        struct InsertPayload: Encodable { let name: String; let restaurant_id: String }
        let created: CategoryRow = try await client
            .from("categories")
            .insert(InsertPayload(name: name, restaurant_id: restaurantID.uuidString))
            .select("id")
            .single()
            .execute()
            .value

        return created.id
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
