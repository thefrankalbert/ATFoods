import Foundation
import Models
import Networking

@MainActor
@Observable
public final class AuthStore {
    public var email = ""
    public var password = ""
    public enum SignInMethod: Sendable { case password, google, apple }
    /// Sign-in in progress, and which button started it (that one shows the spinner, the others wait).
    public var pending: SignInMethod?
    public var isLoading: Bool { pending != nil }
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
        // Autofill / QuickType often adds a trailing space: never let it fail a valid login.
        let email = trimmedEmail, password = password
        await signIn(.password, networking: networking) { try await networking.signIn(email: email, password: password) }
    }

    public func signInWithGoogle(networking: any ATFNetworking) async {
        await signIn(.google, networking: networking) { try await networking.signInWithGoogle() }
    }

    public func signInWithApple(idToken: String, nonce: String, networking: any ATFNetworking) async {
        await signIn(.apple, networking: networking) { try await networking.signInWithApple(idToken: idToken, nonce: nonce) }
    }

    /// Shared by every sign-in method. `authenticate` returns nil when the user gave up (closed the Google sheet).
    private func signIn(_ method: SignInMethod, networking: any ATFNetworking,
                        authenticate: () async throws -> AppUser?) async {
        guard pending == nil else { return }
        pending = method
        defer { pending = nil }
        error = nil
        let user: AppUser
        do {
            guard let signedIn = try await authenticate() else { return }
            user = signedIn
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
