import Foundation
import Models
import Networking

@MainActor @Observable public final class HomeStore {
    public var restaurant: Restaurant
    public var menuItems: [MenuItem] = []
    public var categories: [String] = []
    public var isLoading = false
    public var error: String?
    public var selectedCategory: String? = nil

    public init(restaurant: Restaurant) { self.restaurant = restaurant }

    public func load(networking: any ATFNetworking) async {
        isLoading = true
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
        guard let cat = selectedCategory else { return menuItems }
        return menuItems.filter { $0.category == cat }
    }
}
