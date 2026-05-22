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
