import Foundation
import Models
import Networking

public enum DraftFilter: String, CaseIterable, Sendable {
    case all      = "Tous"
    case pending  = "À publier"
    case attached = "Publiés"
}

@MainActor @Observable public final class DraftsStore {
    public var drafts: [Draft] = []
    public var filter: DraftFilter = .all
    public var selectedIDs: Set<UUID> = []
    public var isMultiSelect: Bool = false
    public var isLoading: Bool = false

    let restaurantID: UUID

    public init(restaurantID: UUID) {
        self.restaurantID = restaurantID
    }

    public var filteredDrafts: [Draft] {
        switch filter {
        case .all:      return drafts
        case .pending:  return drafts.filter { $0.status == .pending }
        case .attached: return drafts.filter { $0.status == .attached }
        }
    }

    public func load(networking: any ATFNetworking) async {
        isLoading = true
        defer { isLoading = false }
        do { drafts = try await networking.fetchDrafts(restaurantID: restaurantID) }
        catch {}
    }

    public func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) }
        else { selectedIDs.insert(id) }
    }

    public func deleteSelected() {
        drafts.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
        isMultiSelect = false
    }
}
