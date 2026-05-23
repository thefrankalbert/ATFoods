import Foundation
import Models
import Networking

public struct CreditEntry: Identifiable, Sendable {
    public let id: UUID
    public let description: String
    public let amount: Int
    public let date: Date

    public init(id: UUID = UUID(), description: String, amount: Int, date: Date = Date()) {
        self.id = id; self.description = description; self.amount = amount; self.date = date
    }

    static let mocks: [CreditEntry] = [
        CreditEntry(description: "Allocation mensuelle", amount: +20,
                    date: Date().addingTimeInterval(-86400 * 30)),
        CreditEntry(description: "Suppression fond", amount: -1,
                    date: Date().addingTimeInterval(-86400 * 2)),
        CreditEntry(description: "Changement fond", amount: -2,
                    date: Date().addingTimeInterval(-86400 * 1)),
        CreditEntry(description: "Suppression fond", amount: -1,
                    date: Date().addingTimeInterval(-3600 * 5)),
        CreditEntry(description: "Changement fond", amount: -2,
                    date: Date().addingTimeInterval(-3600 * 2)),
        CreditEntry(description: "Suppression fond", amount: -1,
                    date: Date().addingTimeInterval(-1800)),
        CreditEntry(description: "Suppression fond", amount: -1,
                    date: Date().addingTimeInterval(-900)),
        CreditEntry(description: "Changement fond", amount: -2,
                    date: Date().addingTimeInterval(-300)),
    ]
}

@MainActor @Observable public final class ProfileStore {
    public var user: AppUser
    public var restaurant: Restaurant
    public var creditsBalance: Int = 5
    public var creditsTotal: Int = 20
    public var creditHistory: [CreditEntry] = CreditEntry.mocks
    public var isSigningOut: Bool = false

    public init(user: AppUser, restaurant: Restaurant) {
        self.user = user
        self.restaurant = restaurant
    }

    public func loadCredits(networking: any ATFNetworking) async {
        do { creditsBalance = try await networking.fetchCredits(userID: user.id) }
        catch {}
    }

    public func signOut(networking: any ATFNetworking) async {
        isSigningOut = true
        defer { isSigningOut = false }
        try? await networking.signOut()
    }
}
