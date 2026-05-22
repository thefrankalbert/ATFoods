import Foundation

public struct Restaurant: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var city: String
    public var role: RestaurantRole
    public var dishCount: Int
    public var photoURL: URL?

    public init(
        id: UUID = UUID(),
        name: String,
        city: String,
        role: RestaurantRole = .owner,
        dishCount: Int = 0,
        photoURL: URL? = nil
    ) {
        self.id = id; self.name = name; self.city = city
        self.role = role; self.dishCount = dishCount; self.photoURL = photoURL
    }
}

public enum RestaurantRole: String, Sendable { case owner = "Gérant", manager = "Manager" }

public struct AppUser: Sendable {
    public let id: UUID
    public var name: String
    public var email: String
    public var plan: AppPlan
    public init(id: UUID = UUID(), name: String, email: String, plan: AppPlan = .starter) {
        self.id = id; self.name = name; self.email = email; self.plan = plan
    }
    public static let mock = AppUser(name: "Mariam", email: "mariam@chezflora.cm")
}

public enum AppPlan: String, Sendable { case starter, pro }

public extension Restaurant {
    static let mocks: [Restaurant] = [
        Restaurant(name: "Chez Flora", city: "Douala", role: .owner, dishCount: 47,
                   photoURL: URL(string: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200")),
        Restaurant(name: "Le Maquis du Port", city: "Yaoundé", role: .manager, dishCount: 23),
    ]
}
