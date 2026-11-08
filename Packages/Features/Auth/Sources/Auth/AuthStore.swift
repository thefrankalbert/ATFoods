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
    /// Set when the restaurant list could not be fetched (vs. genuinely empty).
    public var restaurantsError: String?

    public init() {}

    public func signIn(networking: any ATFNetworking) async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        let user: AppUser
        do {
            user = try await networking.signIn(email: email, password: password)
        } catch {
            self.error = Self.message(for: error, credentials: true)
            return
        }
        // currentUser only set once restaurants loaded: a failure stays visible on the login screen.
        do {
            restaurants = try await networking.fetchRestaurants(userID: user.id)
            restaurantsError = nil
            currentUser = user
        } catch {
            try? await networking.signOut()
            self.error = Self.message(for: error, credentials: false)
        }
    }

    /// Used after a restored session or from the picker's retry button.
    public func loadRestaurants(networking: any ATFNetworking) async {
        guard let user = currentUser else { return }
        do {
            restaurants = try await networking.fetchRestaurants(userID: user.id)
            restaurantsError = nil
        } catch {
            restaurantsError = Self.message(for: error, credentials: false)
        }
    }

    private static func message(for error: Error, credentials: Bool) -> String {
        let msg = error.localizedDescription.lowercased()
        if credentials, msg.contains("invalid") || msg.contains("credentials") || msg.contains("wrong") || msg.contains("identifiants") {
            return "Email ou mot de passe incorrect."
        }
        if error is URLError || msg.contains("network") || msg.contains("offline") || msg.contains("connect") {
            return "Vérifiez votre connexion internet."
        }
        return "Connexion impossible. Réessayez."
    }
}
