import Foundation

public struct Restaurant: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var city: String
    public var role: RestaurantRole
    public var dishCount: Int
    public var photoURL: URL?
    public var plan: AppPlan

    public init(
        id: UUID = UUID(),
        name: String,
        city: String,
        role: RestaurantRole = .owner,
        dishCount: Int = 0,
        photoURL: URL? = nil,
        plan: AppPlan = .starter
    ) {
        self.id = id; self.name = name; self.city = city
        self.role = role; self.dishCount = dishCount; self.photoURL = photoURL
        self.plan = plan
    }
}

public enum RestaurantRole: String, Sendable, Hashable {
    case owner = "owner"
    case admin = "admin"
    case manager = "manager"
    public var displayName: String {
        switch self {
        case .owner: "Propriétaire"
        case .admin: "Admin"
        case .manager: "Manager"
        }
    }
}

public struct AppUser: Sendable {
    public let id: UUID
    public var name: String
    public var email: String
    public init(id: UUID = UUID(), name: String, email: String) {
        self.id = id; self.name = name; self.email = email
    }
    public static let mock = AppUser(name: "Mariam", email: "mariam@chezflora.cm")
}

public enum AppPlan: String, Sendable, Hashable {
    case starter, pro, business, enterprise
    // Map renamed legacy plans
    public init(fromDB value: String) {
        switch value {
        case "pro", "premium": self = .pro
        case "business": self = .business
        case "enterprise": self = .enterprise
        default: self = .starter
        }
    }

    public var displayName: String { rawValue.capitalized }
}

public extension Restaurant {
    static let mocks: [Restaurant] = [
        Restaurant(name: "Chez Flora", city: "Douala", role: .owner, dishCount: 47,
                   photoURL: URL(string: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200")),
        Restaurant(name: "Le Maquis du Port", city: "Yaoundé", role: .admin, dishCount: 23),
    ]
}
