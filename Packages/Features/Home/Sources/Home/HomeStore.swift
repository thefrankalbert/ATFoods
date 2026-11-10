import Foundation
import Models
import Networking

@MainActor @Observable public final class HomeStore {
    /// Work queues on Home, like the stock card of restaurant POS apps.
    public enum Filter: Hashable, CaseIterable, Sendable {
        case all, noPhoto, soldOut
        public var label: String {
            switch self {
            case .all: "Tous"
            case .noPhoto: "Sans photo"
            case .soldOut: "Épuisés"
            }
        }
    }

    public struct Section: Identifiable {
        public let id: String
        public let title: String
        public let items: [MenuItem]
    }

    public var restaurant: Restaurant
    public var menuItems: [MenuItem] = []
    public var categories: [MenuCategory] = []
    public var isLoading = false
    public var error: String?
    /// Failed quick action (availability toggle); the list itself is still up to date.
    public var actionError: String?
    public var selectedCategoryID: UUID? = nil
    public var filter: Filter = .all
    public var searchText = ""
    public private(set) var updatingIDs: Set<UUID> = []

    public init(restaurant: Restaurant) { self.restaurant = restaurant }

    public func load(networking: any ATFNetworking) async {
        isLoading = menuItems.isEmpty   // skeleton only on first load; later refreshes keep the list
        error = nil
        do {
            async let items = networking.fetchMenuItems(restaurantID: restaurant.id)
            async let cats = networking.fetchCategories(restaurantID: restaurant.id)
            let loadedCategories = try await cats
            categories = loadedCategories
            menuItems = MenuOrder.items(try await items, categories: loadedCategories)
        } catch {
            self.error = UserMessage.from(error)
        }
        isLoading = false
    }

    public func count(_ filter: Filter) -> Int {
        menuItems.filter { matches($0, filter) }.count
    }

    public var filteredItems: [MenuItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return menuItems.filter { item in
            (selectedCategoryID == nil || item.categoryID == selectedCategoryID)
                && matches(item, filter)
                && (query.isEmpty || item.name.localizedStandardContains(query))   // case and accent insensitive
        }
    }

    /// Consecutive runs of the same category (menuItems is already in category order).
    public var sections: [Section] {
        var result: [Section] = []
        for item in filteredItems {
            let key = item.categoryID?.uuidString ?? item.category
            if let last = result.last, last.id == key {
                result[result.count - 1] = Section(id: key, title: last.title, items: last.items + [item])
            } else {
                result.append(Section(id: key, title: item.category.isEmpty ? "Sans catégorie" : item.category, items: [item]))
            }
        }
        return result
    }

    /// Optimistic: the switch moves at once and goes back if the server refuses.
    public func setAvailable(_ itemID: UUID, _ isAvailable: Bool, networking: any ATFNetworking) async {
        guard !updatingIDs.contains(itemID),
              let index = menuItems.firstIndex(where: { $0.id == itemID }),
              menuItems[index].isAvailable != isAvailable else { return }
        menuItems[index].isAvailable = isAvailable
        updatingIDs.insert(itemID)
        defer { updatingIDs.remove(itemID) }
        do {
            try await networking.setAvailability(dishID: itemID, isAvailable: isAvailable, restaurantID: restaurant.id)
            actionError = nil
        } catch {
            if let i = menuItems.firstIndex(where: { $0.id == itemID }) { menuItems[i].isAvailable = !isAvailable }
            actionError = "Disponibilité non modifiée. \(UserMessage.from(error))"
        }
    }

    private func matches(_ item: MenuItem, _ filter: Filter) -> Bool {
        switch filter {
        case .all: true
        case .noPhoto: item.photoURL == nil
        case .soldOut: !item.isAvailable
        }
    }
}
