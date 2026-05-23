import Foundation
import Models

public final class MockNetworking: ATFNetworking {
    public init() {}

    public func signIn(email: String, password: String) async throws -> AppUser {
        try await Task.sleep(for: .milliseconds(700))
        guard email.contains("@"), !password.isEmpty else { throw ATFError.invalidCredentials }
        return AppUser.mock
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

    public func createMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem {
        try await Task.sleep(for: .milliseconds(600))
        return item
    }

    public func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        try await Task.sleep(for: .milliseconds(400))
        guard let url = URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400") else {
            throw ATFError.networkUnavailable
        }
        return url
    }

    public func fetchDrafts(restaurantID: UUID) async throws -> [Draft] {
        try await Task.sleep(for: .milliseconds(400))
        return Draft.mocks
    }

    public func applyAIRetouch(dishID: UUID, effect: AIRetouchEffect) async throws -> URL {
        try await Task.sleep(for: .seconds(1.5))
        guard let url = URL(string: "https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=600") else {
            throw ATFError.networkUnavailable
        }
        return url
    }

    public func fetchCredits(userID: UUID) async throws -> Int {
        try await Task.sleep(for: .milliseconds(200))
        return 5
    }
}

public enum ATFError: Error, LocalizedError, Sendable {
    case invalidCredentials
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Identifiants invalides."
        case .networkUnavailable: return "Pas de connexion réseau."
        }
    }
}
