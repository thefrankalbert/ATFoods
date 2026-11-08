import Testing
import Foundation
import Models
import Networking
@testable import Drafts

private final class FailingDelete: ATFNetworking, @unchecked Sendable {
    func signIn(email: String, password: String) async throws -> AppUser { AppUser.mock }
    func restoreSession() async -> AppUser? { nil }
    func signOut() async throws {}
    func fetchRestaurants(userID: UUID) async throws -> [Restaurant] { [] }
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem] { [] }
    func fetchCategories(restaurantID: UUID) async throws -> [MenuCategory] { [] }
    func fetchMenus(restaurantID: UUID) async throws -> [MenuRef] { [] }
    func createCategory(name: String, menuID: UUID?, restaurantID: UUID) async throws -> MenuCategory { MenuCategory(name: name) }
    func createMenuItem(_ item: MenuItem, categoryID: UUID, restaurantID: UUID) async throws -> MenuItem { item }
    func updateMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem { item }
    func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL { URL(string: "https://x")! }
    func saveDraft(imageData: Data, restaurantID: UUID) async throws -> Draft { Draft.mocks[0] }
    func fetchDrafts(restaurantID: UUID) async throws -> [Draft] { Draft.mocks }
    func attachDraft(_ draft: Draft, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL { draft.photoURL }
    func deleteDrafts(_ drafts: [Draft]) async throws { throw URLError(.notConnectedToInternet) }
}

@MainActor @Test func failedDeleteKeepsDraftsAndShowsError() async {
    let net = FailingDelete()
    let store = DraftsStore(restaurantID: UUID())
    await store.load(networking: net)
    store.toggleSelection(store.drafts[0].id)
    await store.deleteSelected(networking: net)
    #expect(store.drafts.count == Draft.mocks.count)
    #expect(store.error != nil)
}

@MainActor @Test func successfulDeleteRemovesOnlySelection() async {
    let store = DraftsStore(restaurantID: UUID())
    await store.load(networking: MockNetworking())
    store.isMultiSelect = true
    store.toggleSelection(store.drafts[0].id)
    await store.deleteSelected(networking: MockNetworking())
    #expect(store.drafts.count == Draft.mocks.count - 1)
    #expect(!store.isMultiSelect)
    #expect(store.error == nil)
}
