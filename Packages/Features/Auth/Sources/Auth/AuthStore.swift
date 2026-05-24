import Foundation
import Models
import Networking

@MainActor
@Observable
public final class AuthStore {
    public var email = ""
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
            let msg = error.localizedDescription.lowercased()
            if msg.contains("invalid") || msg.contains("credentials") || msg.contains("wrong") {
                self.error = "Email ou mot de passe incorrect."
            } else if msg.contains("network") || msg.contains("offline") || msg.contains("connect") {
                self.error = "Vérifiez votre connexion internet."
            } else {
                self.error = "Connexion impossible. Réessayez."
            }
        }
        isLoading = false
    }
}
