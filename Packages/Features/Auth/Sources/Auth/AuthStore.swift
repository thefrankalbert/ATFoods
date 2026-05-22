import Foundation
import Models
import Networking

@MainActor
@Observable
public final class AuthStore {
    public var email = "mariam@chezflora.cm"
    public var password = ""
    public var isLoading = false
    public var error: String?
    public var currentUser: AppUser?
    public var selectedRestaurant: Restaurant?
    public var restaurants: [Restaurant] = []

    public init() {}

    public func signIn(networking: any ATFNetworking) async {
        isLoading = true
        error = nil
        do {
            currentUser = try await networking.signIn(email: email, password: password)
            if let user = currentUser {
                restaurants = try await networking.fetchRestaurants(userID: user.id)
            }
        } catch {
            self.error = (error as? ATFError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
