import Testing
import Foundation
import UIKit
import Models
import Networking
@testable import Form

/// Counts writes; the first photo upload fails to simulate a flaky network.
private final class FlakyNetworking: ATFNetworking, @unchecked Sendable {
    private let lock = NSLock()
    private var _created = 0, _uploads = 0
    private var _updated: MenuItem?
    var updated: MenuItem? { lock.withLock { _updated } }
    var created: Int { lock.withLock { _created } }
    var uploads: Int { lock.withLock { _uploads } }

    func signIn(email: String, password: String) async throws -> AppUser { AppUser.mock }
    func restoreSession() async -> AppUser? { nil }
    func signOut() async throws {}
    func deleteAccount() async throws -> AccountDeletionResult { .deleted }
    func fetchRestaurants(userID: UUID) async throws -> [Restaurant] { [] }
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem] { [] }
    func fetchCategories(restaurantID: UUID) async throws -> [MenuCategory] { [] }
    func fetchMenus(restaurantID: UUID) async throws -> [MenuRef] { [] }
    func createCategory(name: String, menuID: UUID?, restaurantID: UUID) async throws -> MenuCategory {
        MenuCategory(name: name, menuID: menuID)
    }
    func createMenuItem(_ item: MenuItem, categoryID: UUID, restaurantID: UUID) async throws -> MenuItem {
        lock.withLock { _created += 1 }
        return item
    }
    func updateMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem {
        lock.withLock { _updated = item }
        return item
    }
    func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        let attempt = lock.withLock { _uploads += 1; return _uploads }
        if attempt == 1 { throw URLError(.timedOut) }
        return URL(string: "https://x/p.jpg")!
    }
    func saveDraft(imageData: Data, restaurantID: UUID) async throws -> Draft { throw URLError(.unsupportedURL) }
    func fetchDrafts(restaurantID: UUID) async throws -> [Draft] { [] }
    func attachDraft(_ draft: Draft, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL { draft.photoURL }
    func deleteDrafts(_ drafts: [Draft]) async throws {}
    func addGalleryPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> [URL] { [] }
    func removeGalleryPhoto(_ url: URL, fromDishID dishID: UUID, restaurantID: UUID) async throws -> [URL] { [] }
}

private func photo() -> UIImage {
    UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { ctx in
        UIColor.orange.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
}

@MainActor @Test func retryAfterFailedUploadDoesNotDuplicateDish() async {
    let net = FlakyNetworking()
    let store = FormStore(restaurant: Restaurant.mocks[0], photo: .captured(photo()))
    store.categories = [MenuCategory(name: "Plat")]
    store.selectedCategoryID = store.categories[0].id
    store.name = "Mafé"
    store.priceText = "3 800"

    await store.submit(networking: net)
    #expect(store.error != nil)
    #expect(store.isDishCreated)

    await store.submit(networking: net)
    #expect(store.error == nil)
    #expect(net.created == 1)
    #expect(net.uploads == 2)
}

@MainActor @Test func dishNeedsNamePriceAndCategory() {
    let store = FormStore(restaurant: Restaurant.mocks[0])
    store.name = "Mafé"
    store.priceText = "3 800"
    #expect(!store.isValid)   // no category yet
    store.categories = [MenuCategory(name: "Plat")]
    store.selectedCategoryID = store.categories[0].id
    #expect(store.isValid)
    #expect(store.price == 3800)
    store.priceText = "38,50"   // XAF restaurant: no cents
    #expect(!store.isValid)
    #expect(store.priceError != nil)
}

@MainActor @Test func editingUpdatesTheDishWithoutCreatingOne() async {
    let net = FlakyNetworking()
    let category = MenuCategory(name: "Plat")
    let dish = MenuItem(name: "Mafé", price: 3800, category: "Plat", categoryID: category.id)
    let store = FormStore(restaurant: Restaurant.mocks[0], editing: dish)
    store.categories = [category]
    #expect(store.priceText == "3800")
    store.priceText = "4 200"
    store.isAvailable = false
    await store.submit(networking: net)
    #expect(store.error == nil)
    #expect(net.created == 0)
    #expect(net.updated?.price == 4200)
    #expect(net.updated?.isAvailable == false)
}

@MainActor @Test func duplicateCategoryNamesShowTheirMenu() {
    let midi = MenuRef(name: "Midi"), soir = MenuRef(name: "Soir")
    let store = FormStore(restaurant: Restaurant.mocks[0])
    store.menus = [midi, soir]
    store.categories = [MenuCategory(name: "Entrées", menuID: midi.id), MenuCategory(name: "Entrées", menuID: soir.id),
                        MenuCategory(name: "Desserts", menuID: soir.id)]
    #expect(store.label(for: store.categories[0]) == "Entrées · Midi")
    #expect(store.label(for: store.categories[2]) == "Desserts")
}
