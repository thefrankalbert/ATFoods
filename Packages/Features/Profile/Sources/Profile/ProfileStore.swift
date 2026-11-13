import Foundation
import Models
import Networking

@MainActor @Observable public final class ProfileStore {
    public var user: AppUser
    public var restaurant: Restaurant
    public var isSigningOut: Bool = false
    public var isDeleting: Bool = false
    public var deletionOutcome: AccountDeletionResult?
    public var deletionError: String?

    public init(user: AppUser, restaurant: Restaurant) {
        self.user = user
        self.restaurant = restaurant
    }

    public func deleteAccount(networking: any ATFNetworking) async {
        isDeleting = true
        defer { isDeleting = false }
        deletionError = nil
        do {
            deletionOutcome = try await networking.deleteAccount()
        } catch {
            deletionError = UserMessage.from(error)
        }
    }

    /// Owner flow: the account cannot go alone, so the deletion is requested and confirmed on screen.
    public func requestDeletion(networking: any ATFNetworking) async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await networking.requestAccountDeletion()
            deletionOutcome = .requested
        } catch {
            deletionOutcome = nil
            deletionError = UserMessage.from(error)
        }
    }

    public func signOut(networking: any ATFNetworking) async {
        isSigningOut = true
        defer { isSigningOut = false }
        try? await networking.signOut()   // local session is cleared by the caller either way
    }
}
