import Foundation
import Models
import Networking

@MainActor @Observable public final class HomeStore {
    public var restaurant: Restaurant
    public var menuItems: [MenuItem] = []
    public var categories: [MenuCategory] = []
    public var isLoading = false
    public var error: String?
    public var selectedCategoryID: UUID? = nil

    public init(restaurant: Restaurant) { self.restaurant = restaurant }

    public func load(networking: any ATFNetworking) async {
        isLoading = menuItems.isEmpty   // skeleton only on first load; later refreshes keep the grid
        error = nil
        do {
            async let items = networking.fetchMenuItems(restaurantID: restaurant.id)
            async let cats = networking.fetchCategories(restaurantID: restaurant.id)
            menuItems = try await items
            categories = try await cats
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    public var filteredItems: [MenuItem] {
        guard let id = selectedCategoryID else { return menuItems }
        return menuItems.filter { $0.categoryID == id }
    }
}
