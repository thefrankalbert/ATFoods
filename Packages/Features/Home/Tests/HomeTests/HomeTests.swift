import Testing
import Foundation
import Models
import Networking
@testable import Home

@MainActor @Test func sameNamedCategoriesStayApart() {
    let midi = MenuCategory(name: "Entrées"), soir = MenuCategory(name: "Entrées")
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    store.menuItems = [MenuItem(name: "Salade", price: 1500, category: "Entrées", categoryID: midi.id),
                       MenuItem(name: "Soupe", price: 1800, category: "Entrées", categoryID: soir.id)]
    #expect(store.sections.map(\.id) == [midi.id.uuidString, soir.id.uuidString])
    #expect(store.sections.map { $0.items.map(\.name) } == [["Salade"], ["Soupe"]])
}

@MainActor @Test func workQueueFiltersSearchAndSections() {
    let plats = MenuCategory(name: "Plats"), grill = MenuCategory(name: "Grillades")
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    store.menuItems = [
        MenuItem(name: "Ndolé", price: 3800, category: "Plats", categoryID: plats.id, isAvailable: false),
        MenuItem(name: "Poulet DG", price: 4500, category: "Plats", categoryID: plats.id,
                 photoURL: URL(string: "https://x.test/a.jpg")),
        MenuItem(name: "Brochettes", price: 2800, category: "Grillades", categoryID: grill.id),
    ]
    #expect(store.sections.map(\.title) == ["Plats", "Grillades"])
    #expect(store.count(.noPhoto) == 2)
    #expect(store.count(.soldOut) == 1)

    store.filter = .soldOut
    #expect(store.filteredItems.map(\.name) == ["Ndolé"])

    store.filter = .all
    store.searchText = "ndole"   // accent-insensitive
    #expect(store.filteredItems.map(\.name) == ["Ndolé"])
}

@MainActor @Test func availabilityToggleUpdatesTheDish() async {
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    let dish = MenuItem(name: "Koki", price: 1200)
    store.menuItems = [dish]
    await store.setAvailable(dish.id, false, networking: MockNetworking())
    #expect(store.menuItems[0].isAvailable == false)
    #expect(store.updatingIDs.isEmpty)
    #expect(store.actionError == nil)
}
