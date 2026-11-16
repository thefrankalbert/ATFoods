import Foundation
import Models

public protocol ATFNetworking: Sendable {
    // Auth
    func signIn(email: String, password: String) async throws -> AppUser
    /// Google in the system sign-in sheet: the same Google account as on the À Table dashboard.
    /// nil = the user closed the sheet.
    func signInWithGoogle() async throws -> AppUser?
    /// Identity token from Sign in with Apple. `nonce` is the raw value whose SHA-256 went into the Apple request.
    func signInWithApple(idToken: String, nonce: String) async throws -> AppUser
    /// Session saved in the keychain by a previous launch, refreshed if needed. nil = must log in.
    func restoreSession() async -> AppUser?
    func signOut() async throws
    /// Deletes the signed-in account (server-side checks). Signs out locally on success.
    func deleteAccount() async throws -> AccountDeletionResult
    /// Owner whose account cannot be removed at once (the restaurant goes with it): records a deletion request,
    /// processed within 30 days. Calling it again keeps the same request.
    func requestAccountDeletion() async throws
    /// Fires when the session ends outside the app's own sign-out (revoked, password changed on the web).
    func signedOutEvents() -> AsyncStream<Void>

    // Menu
    func fetchRestaurants(userID: UUID) async throws -> [Restaurant]
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem]
    func fetchCategories(restaurantID: UUID) async throws -> [MenuCategory]
    func fetchMenus(restaurantID: UUID) async throws -> [MenuRef]
    func createCategory(name: String, menuID: UUID?, restaurantID: UUID) async throws -> MenuCategory
    func createMenuItem(_ item: MenuItem, categoryID: UUID, restaurantID: UUID) async throws -> MenuItem
    /// Name, price, availability and category. Throws if the dish no longer exists or rights are missing.
    /// Writes only the fields that differ from `original` (the dish as loaded), so edits made on the web meanwhile survive.
    func updateMenuItem(_ item: MenuItem, from original: MenuItem, restaurantID: UUID) async throws -> MenuItem
    /// Writes only is_available (quick toggle from Home): never overwrites other fields edited on the web.
    func setAvailability(dishID: UUID, isAvailable: Bool, restaurantID: UUID) async throws

    // Photos
    func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL

    // Drafts (batch shooting)
    func saveDraft(imageData: Data, restaurantID: UUID) async throws -> Draft
    func fetchDrafts(restaurantID: UUID) async throws -> [Draft]
    /// Sets the draft photo on the dish, then removes the draft.
    func attachDraft(_ draft: Draft, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL
    func deleteDrafts(_ drafts: [Draft]) async throws
    /// Extra photos of a dish (web "Photos supplémentaires"); each returns the new list.
    func addGalleryPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> [URL]
    func removeGalleryPhoto(_ url: URL, fromDishID dishID: UUID, restaurantID: UUID) async throws -> [URL]
}

public extension ATFNetworking {
    func signedOutEvents() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

public enum AccountDeletionResult: Equatable, Sendable {
    case deleted
    /// Deletion request recorded (owner): account and restaurant are removed within 30 days.
    case requested
    /// Sole owner of this restaurant: it must be handed over or closed first.
    case soleOwner(restaurant: String)
    /// Owner of the restaurant group the web signup creates for every new owner: closing it goes through support.
    case groupOwner
    /// Platform operator (À Table team account): handled by support.
    case needsSupport
}
