import Foundation
import Models
import Networking

public struct BackgroundOption: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let colorHex: String
    public let previewURL: URL?

    public init(id: String, name: String, colorHex: String, previewURL: URL? = nil) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.previewURL = previewURL
    }

    public static let options: [BackgroundOption] = [
        BackgroundOption(id: "plain_white", name: "Blanc", colorHex: "FFFFFF"),
        BackgroundOption(id: "plain_black", name: "Noir", colorHex: "111111"),
        BackgroundOption(id: "warm_orange", name: "Chaud", colorHex: "F97316"),
        BackgroundOption(id: "marble", name: "Marbre", colorHex: "E8E4DF",
            previewURL: URL(string: "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=200")),
        BackgroundOption(id: "wood", name: "Bois", colorHex: "8B6914",
            previewURL: URL(string: "https://images.unsplash.com/photo-1541123437800-1bb1317badc2?w=200")),
        BackgroundOption(id: "linen", name: "Lin", colorHex: "D4C5A9"),
    ]
}

@MainActor @Observable public final class AIRetouchStore {
    public var dishID: UUID
    public var originalURL: URL?
    public var retouchedURL: URL?
    public var creditsBalance: Int = 5
    public var isProcessing: Bool = false
    public var selectedBackgroundID: String?

    public init(dishID: UUID, originalURL: URL? = nil, creditsBalance: Int = 5) {
        self.dishID = dishID
        self.originalURL = originalURL
        self.creditsBalance = creditsBalance
    }

    public func removeBackground(networking: any ATFNetworking) async {
        guard creditsBalance >= 1 else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            retouchedURL = try await networking.applyAIRetouch(dishID: dishID, effect: .removeBackground)
            creditsBalance = max(0, creditsBalance - 1)
        } catch {}
    }

    public func changeBackground(_ backgroundID: String, networking: any ATFNetworking) async {
        guard creditsBalance >= 2 else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            retouchedURL = try await networking.applyAIRetouch(dishID: dishID, effect: .changeBackground(id: backgroundID))
            creditsBalance = max(0, creditsBalance - 2)
        } catch {}
    }
}
