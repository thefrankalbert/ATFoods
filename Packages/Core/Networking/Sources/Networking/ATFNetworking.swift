import Foundation
import Models

public protocol ATFNetworking: Sendable {
    // Auth
    func signIn(email: String, password: String) async throws -> AppUser
    /// Session saved in the keychain by a previous launch, refreshed if needed. nil = must log in.
    func restoreSession() async -> AppUser?
    func signOut() async throws

    // Menu
    func fetchRestaurants(userID: UUID) async throws -> [Restaurant]
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem]
    func fetchCategories(restaurantID: UUID) async throws -> [MenuCategory]
    func fetchMenus(restaurantID: UUID) async throws -> [MenuRef]
    func createCategory(name: String, menuID: UUID?, restaurantID: UUID) async throws -> MenuCategory
    func createMenuItem(_ item: MenuItem, categoryID: UUID, restaurantID: UUID) async throws -> MenuItem

    // Photos
    func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL

    // Drafts (batch shooting)
    func saveDraft(imageData: Data, restaurantID: UUID) async throws -> Draft
    func fetchDrafts(restaurantID: UUID) async throws -> [Draft]
    /// Sets the draft photo on the dish, then removes the draft.
    func attachDraft(_ draft: Draft, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL
    func deleteDrafts(_ drafts: [Draft]) async throws
}
