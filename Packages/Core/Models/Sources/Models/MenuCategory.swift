import Foundation

/// Row of `categories`. `menuID` matters: with several menus, the web storefront hides categories without one.
public struct MenuCategory: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var menuID: UUID?

    public init(id: UUID = UUID(), name: String, menuID: UUID? = nil) {
        self.id = id; self.name = name; self.menuID = menuID
    }
}

/// Active row of `menus` (sub-menus labelled "Parent › Child").
public struct MenuRef: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id; self.name = name
    }
}

#if DEBUG
public extension MenuCategory {
    static let mocks: [MenuCategory] = ["Plat", "Spécialité", "Grillades", "Entrée", "Boisson"].map { MenuCategory(name: $0) }
}
#endif
