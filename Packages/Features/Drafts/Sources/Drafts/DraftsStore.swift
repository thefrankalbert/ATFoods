import Foundation
import Models
import Networking

@MainActor @Observable public final class DraftsStore {
    public var drafts: [Draft] = []
    public var selectedIDs: Set<UUID> = []
    public var isMultiSelect: Bool = false
    public var isLoading: Bool = false
    public var isDeleting: Bool = false
    public var error: String?

    let restaurantID: UUID

    public init(restaurantID: UUID) {
        self.restaurantID = restaurantID
    }

    public func load(networking: any ATFNetworking) async {
        isLoading = drafts.isEmpty
        defer { isLoading = false }
        do {
            drafts = try await networking.fetchDrafts(restaurantID: restaurantID)
            error = nil
        } catch {
            self.error = "Brouillons : \(error.localizedDescription)"
        }
    }

    public func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) }
        else { selectedIDs.insert(id) }
    }

    /// Deletes rows and files server-side; the list only changes once that succeeded.
    public func deleteSelected(networking: any ATFNetworking) async {
        let targets = drafts.filter { selectedIDs.contains($0.id) }
        guard !targets.isEmpty else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await networking.deleteDrafts(targets)
            let deleted = Set(targets.map(\.id))   // snapshot sent, not the live selection
            drafts.removeAll { deleted.contains($0.id) }
            selectedIDs.subtract(deleted)
            isMultiSelect = false
            error = nil
        } catch {
            self.error = "Suppression : \(error.localizedDescription)"
        }
    }
}
