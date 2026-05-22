import Foundation

public struct MenuItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var price: Int          // FCFA
    public var category: MenuCategory
    public var photoURL: URL?
    public var isAvailable: Bool
    public var isFeatured: Bool
    public var description: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        price: Int,
        category: MenuCategory,
        photoURL: URL? = nil,
        isAvailable: Bool = true,
        isFeatured: Bool = false,
        description: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id; self.name = name; self.price = price
        self.category = category; self.photoURL = photoURL
        self.isAvailable = isAvailable; self.isFeatured = isFeatured
        self.description = description; self.createdAt = createdAt
    }

    public var priceFormatted: String {
        let t = price / 1000
        let r = price % 1000
        if t > 0, r > 0 { return "\(t) \(String(format: "%03d", r)) FCFA" }
        if t > 0 { return "\(t) 000 FCFA" }
        return "\(price) FCFA"
    }
}

public enum MenuCategory: String, CaseIterable, Sendable, Hashable {
    case entree     = "Entrée"
    case plat       = "Plat"
    case grillades  = "Grillades"
    case specialite = "Spécialité"
    case boisson    = "Boisson"
    case dessert    = "Dessert"
    public var displayName: String { rawValue }
}

public extension MenuItem {
    static let mocks: [MenuItem] = [
        MenuItem(name: "Mafé bœuf",      price: 3800, category: .plat,
                 photoURL: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400"),
                 isFeatured: true),
        MenuItem(name: "Thieboudienne",  price: 4500, category: .plat,
                 photoURL: URL(string: "https://images.unsplash.com/photo-1547928576-b822bc410bdf?w=400")),
        MenuItem(name: "Ndolé crevettes", price: 4200, category: .specialite),
        MenuItem(name: "Brochettes mixtes", price: 2800, category: .grillades),
        MenuItem(name: "Salade maison",  price: 1500, category: .entree),
        MenuItem(name: "Jus de bissap", price: 800,  category: .boisson),
        MenuItem(name: "Koki", price: 1200, category: .specialite),
    ]
}
