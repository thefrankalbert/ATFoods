import Foundation
import Models

public protocol ATFNetworking: Sendable {
    func signIn(email: String, password: String) async throws -> AppUser
    func signOut() async throws
    func fetchRestaurants(userID: UUID) async throws -> [Restaurant]
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem]
    func createMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem
    func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL
}
