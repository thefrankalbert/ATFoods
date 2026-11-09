import Foundation

public struct MenuItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var price: Decimal      // in the restaurant currency (Restaurant.currency)
    public var category: String    // category name, for display
    public var categoryID: UUID?
    public var photoURL: URL?
    public var isAvailable: Bool
    public var isFeatured: Bool
    public var description: String
    public var createdAt: Date
    // Same dish sheet as the web admin (attabl-saas useItemForm.ts).
    public var nameEn: String = ""
    public var descriptionEn: String = ""
    /// EU allergen ids, as stored in menu_items.allergens (see Allergen).
    public var allergens: [String] = []
    public var calories: Int?
    /// Extra photos after the main one (menu_items.images minus image_url).
    public var gallery: [URL] = []

    public init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        category: String = "Plat",
        categoryID: UUID? = nil,
        photoURL: URL? = nil,
        isAvailable: Bool = true,
        isFeatured: Bool = false,
        description: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id; self.name = name; self.price = price
        self.category = category; self.categoryID = categoryID; self.photoURL = photoURL
        self.isAvailable = isAvailable; self.isFeatured = isFeatured
        self.description = description; self.createdAt = createdAt
    }

    public func formattedPrice(currency: String) -> String {
        Money.format(price, currency: currency)
    }
}

#if DEBUG
public extension MenuItem {
    /// Preview / UI-test data only (never compiled in Release).
    static let mocks: [MenuItem] = {
        func cat(_ name: String) -> MenuCategory { MenuCategory.mocks.first { $0.name == name }! }
        func item(_ name: String, _ price: Decimal, _ c: String, photo: String? = nil) -> MenuItem {
            MenuItem(name: name, price: price, category: c, categoryID: cat(c).id,
                     photoURL: photo.flatMap { URL(string: "https://images.unsplash.com/\($0)?w=400") })
        }
        return [
            item("Mafé bœuf", 3800, "Plat", photo: "photo-1604908176997-125f25cc6f3d"),
            item("Thieboudienne", 4500, "Plat", photo: "photo-1547928576-b822bc410bdf"),
            item("Ndolé crevettes", 4200, "Spécialité"),
            item("Brochettes mixtes", 2800, "Grillades"),
            item("Salade maison", 1500, "Entrée"),
            item("Jus de bissap", 800, "Boisson"),
            item("Koki", 1200, "Spécialité"),
        ]
    }()
}
#endif
