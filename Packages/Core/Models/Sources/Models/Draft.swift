import Foundation

public struct Draft: Identifiable, Sendable {
    public let id: UUID
    public var photoURL: URL
    public var status: DraftStatus
    public var createdAt: Date
    public init(id: UUID = UUID(), photoURL: URL, status: DraftStatus = .pending, createdAt: Date = Date()) {
        self.id = id; self.photoURL = photoURL
        self.status = status; self.createdAt = createdAt
    }
}

public enum DraftStatus: Sendable { case pending, attached }

public extension Draft {
    static let mocks: [Draft] = [
        Draft(photoURL: URL(string: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200")!, status: .pending),
        Draft(photoURL: URL(string: "https://images.unsplash.com/photo-1547592180-85f173990554?w=200")!, status: .pending),
        Draft(photoURL: URL(string: "https://images.unsplash.com/photo-1574484284002-952d92456975?w=200")!, status: .attached),
        Draft(photoURL: URL(string: "https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=200")!, status: .pending),
        Draft(photoURL: URL(string: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200")!, status: .attached),
        Draft(photoURL: URL(string: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=200")!, status: .pending),
    ]
}
