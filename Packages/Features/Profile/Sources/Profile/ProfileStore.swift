import Foundation
import Models
import Networking

@MainActor @Observable public final class ProfileStore {
    public var user: AppUser
    public var restaurant: Restaurant
    public var isSigningOut: Bool = false

    public init(user: AppUser, restaurant: Restaurant) {
        self.user = user
        self.restaurant = restaurant
    }

    public func signOut(networking: any ATFNetworking) async {
        isSigningOut = true
        defer { isSigningOut = false }
        try? await networking.signOut()   // local session is cleared by the caller either way
    }
}
