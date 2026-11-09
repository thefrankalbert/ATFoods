import Testing
import Foundation
import Models
@testable import Home

@MainActor @Test func categoryFilterUsesIDsNotNames() {
    let midi = MenuCategory(name: "Entrées"), soir = MenuCategory(name: "Entrées")
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    store.menuItems = [MenuItem(name: "Salade", price: 1500, category: "Entrées", categoryID: midi.id),
                       MenuItem(name: "Soupe", price: 1800, category: "Entrées", categoryID: soir.id)]
    store.selectedCategoryID = soir.id
    #expect(store.filteredItems.map(\.name) == ["Soupe"])
    store.selectedCategoryID = nil
    #expect(store.filteredItems.count == 2)
}
