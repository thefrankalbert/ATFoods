import Foundation

/// A photo taken in a batch session, waiting to be attached to a dish (table `dish_photo_drafts`).
public struct Draft: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var photoURL: URL
    public var storagePath: String
    public var createdAt: Date

    public init(id: UUID = UUID(), photoURL: URL, storagePath: String, createdAt: Date = Date()) {
        self.id = id; self.photoURL = photoURL
        self.storagePath = storagePath; self.createdAt = createdAt
    }
}

public extension Draft {
    static let mocks: [Draft] = [
        "photo-1512621776951-a57141f2eefd", "photo-1547592180-85f173990554",
        "photo-1565299507177-b0ac66763828", "photo-1540420773420-3366772f4999",
    ].map { Draft(photoURL: URL(string: "https://images.unsplash.com/\($0)?w=200")!, storagePath: "mock/\($0).jpg") }
}
