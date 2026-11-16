import Foundation
import Models

#if DEBUG

public final class MockNetworking: ATFNetworking {
    public init() {}

    public func signIn(email: String, password: String) async throws -> AppUser {
        try await Task.sleep(for: .milliseconds(700))
        guard email.contains("@"), !password.isEmpty else { throw ATFError.invalidCredentials }
        return AppUser.mock
    }

    public func signInWithGoogle() async throws -> AppUser? {
        try await Task.sleep(for: .milliseconds(700))
        return AppUser.mock
    }

    public func signInWithApple(idToken: String, nonce: String) async throws -> AppUser {
        try await Task.sleep(for: .milliseconds(700))
        return AppUser.mock
    }

    public func restoreSession() async -> AppUser? { nil }   // UI tests always start logged out

    public func deleteAccount() async throws -> AccountDeletionResult {
        try await Task.sleep(for: .milliseconds(300))
        return .soleOwner(restaurant: "Chez Flora")
    }

    public func requestAccountDeletion() async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    public func signOut() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    public func fetchRestaurants(userID: UUID) async throws -> [Restaurant] {
        try await Task.sleep(for: .milliseconds(400))
        return Restaurant.mocks
    }

    public func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem] {
        try await Task.sleep(for: .milliseconds(500))
        return MenuItem.mocks
    }

    public func fetchCategories(restaurantID: UUID) async throws -> [MenuCategory] {
        try await Task.sleep(for: .milliseconds(200))
        return MenuCategory.mocks
    }

    public func fetchMenus(restaurantID: UUID) async throws -> [MenuRef] {
        [MenuRef(name: "Carte"), MenuRef(name: "Boissons")]
    }

    public func createCategory(name: String, menuID: UUID?, restaurantID: UUID) async throws -> MenuCategory {
        try await Task.sleep(for: .milliseconds(300))
        return MenuCategory(name: name, menuID: menuID)
    }

    public func createMenuItem(_ item: MenuItem, categoryID: UUID, restaurantID: UUID) async throws -> MenuItem {
        try await Task.sleep(for: .milliseconds(600))
        var created = item
        created.categoryID = categoryID
        return created
    }

    public func updateMenuItem(_ item: MenuItem, from original: MenuItem, restaurantID: UUID) async throws -> MenuItem {
        try await Task.sleep(for: .milliseconds(300))
        return item
    }

    public func setAvailability(dishID: UUID, isAvailable: Bool, restaurantID: UUID) async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    public func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        try await Task.sleep(for: .milliseconds(400))
        return Self.mockPhotoURL
    }

    public func saveDraft(imageData: Data, restaurantID: UUID) async throws -> Draft {
        try await Task.sleep(for: .milliseconds(300))
        return Draft(photoURL: Self.mockPhotoURL, storagePath: "mock/draft.jpg")
    }

    public func fetchDrafts(restaurantID: UUID) async throws -> [Draft] {
        try await Task.sleep(for: .milliseconds(400))
        return Draft.mocks
    }

    public func attachDraft(_ draft: Draft, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        try await Task.sleep(for: .milliseconds(300))
        return draft.photoURL
    }

    public func deleteDrafts(_ drafts: [Draft]) async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    public func addGalleryPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> [URL] {
        try await Task.sleep(for: .milliseconds(300))
        return [Self.mockPhotoURL]
    }

    public func removeGalleryPhoto(_ url: URL, fromDishID dishID: UUID, restaurantID: UUID) async throws -> [URL] {
        return []
    }

    private static let mockPhotoURL = URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400")!
}

public enum ATFError: UserFacingError, Sendable {
    case invalidCredentials

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Email ou mot de passe incorrect."
        }
    }
}
#endif
