import Foundation
import Models

public protocol ATFNetworking: Sendable {
    func signIn(email: String, password: String) async throws -> AppUser
    func signOut() async throws
    func fetchRestaurants(userID: UUID) async throws -> [Restaurant]
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem]
    func fetchCategories(restaurantID: UUID) async throws -> [String]
    func createMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem
    func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL
    func fetchDrafts(restaurantID: UUID) async throws -> [Draft]
    func applyAIRetouch(dishID: UUID, effect: AIRetouchEffect) async throws -> URL
    func fetchCredits(userID: UUID) async throws -> Int
}

public enum AIRetouchEffect: Sendable {
    case removeBackground
    case changeBackground(id: String)
}
