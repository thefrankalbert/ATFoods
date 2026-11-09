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

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Login is pointless (and the error misleading) until both fields are filled.
    public var canSubmit: Bool { trimmedEmail.contains("@") && !password.isEmpty }

    public func signIn(networking: any ATFNetworking) async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        let user: AppUser
        do {
            // Autofill / QuickType often adds a trailing space: never let it fail a valid login.
            user = try await networking.signIn(email: trimmedEmail, password: password)
        } catch {
            self.error = UserMessage.from(error)
            return
        }
        // currentUser only set once restaurants loaded: a failure stays visible on the login screen.
        do {
            restaurants = try await networking.fetchRestaurants(userID: user.id)
            restaurantsError = nil
            currentUser = user
        } catch {
            try? await networking.signOut()
            self.error = UserMessage.from(error)
        }
    }

    /// Used after a restored session or from the picker's retry button.
    public func loadRestaurants(networking: any ATFNetworking) async {
        guard let user = currentUser else { return }
        do {
            restaurants = try await networking.fetchRestaurants(userID: user.id)
            restaurantsError = nil
        } catch {
            restaurantsError = UserMessage.from(error)
        }
    }
}
