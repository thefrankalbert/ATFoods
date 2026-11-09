import Foundation

/// Same order as the Attabl web menu (attabl-saas src/lib/cache.ts + client-menu-detail):
/// cartes by display_order, each followed by its sub-cartes; transversal cartes last;
/// categories by display_order inside their carte; dishes by creation date inside their category.
public enum MenuOrder {
    public struct MenuNode: Sendable {
        public let id: UUID
        public let parentID: UUID?
        public let displayOrder: Int
        public let isTransversal: Bool
        public init(id: UUID, parentID: UUID?, displayOrder: Int, isTransversal: Bool) {
            self.id = id; self.parentID = parentID; self.displayOrder = displayOrder; self.isTransversal = isTransversal
        }
    }

    /// Menu ids in display order: top cartes (each followed by its sub-cartes), then transversal cartes.
    public static func menuIDs(_ menus: [MenuNode]) -> [UUID] {
        let byOrder = menus.enumerated().sorted { ($0.element.displayOrder, $0.offset) < ($1.element.displayOrder, $1.offset) }.map(\.element)
        let ids = Set(menus.map(\.id))
        let tops = byOrder.filter { $0.parentID == nil || !ids.contains($0.parentID!) }
        var result: [UUID] = []
        for top in tops.filter({ !$0.isTransversal }) + tops.filter(\.isTransversal) {
            result.append(top.id)
            result += byOrder.filter { $0.parentID == top.id }.map(\.id)
        }
        return result
    }

    /// Categories already sorted by display_order, regrouped by carte; categories without a carte stay last.
    /// With at most one carte the web shows every category in display_order, so nothing moves.
    public static func categories(_ categories: [MenuCategory], menus: [MenuNode]) -> [MenuCategory] {
        let tops = menus.filter { $0.parentID == nil }
        guard tops.count > 1 || menus.contains(where: \.isTransversal) else { return categories }
        let rank = Dictionary(uniqueKeysWithValues: menuIDs(menus).enumerated().map { ($1, $0) })
        return categories.enumerated().sorted { a, b in
            let ra = a.element.menuID.flatMap { rank[$0] } ?? Int.max
            let rb = b.element.menuID.flatMap { rank[$0] } ?? Int.max
            return (ra, a.offset) < (rb, b.offset)
        }.map(\.element)
    }

    /// Dishes (already by creation date) regrouped in category order; uncategorised dishes last.
    public static func items(_ items: [MenuItem], categories: [MenuCategory]) -> [MenuItem] {
        let rank = Dictionary(uniqueKeysWithValues: categories.enumerated().map { ($1.id, $0) })
        return items.enumerated().sorted { a, b in
            let ra = a.element.categoryID.flatMap { rank[$0] } ?? Int.max
            let rb = b.element.categoryID.flatMap { rank[$0] } ?? Int.max
            return (ra, a.offset) < (rb, b.offset)
        }.map(\.element)
    }
}
