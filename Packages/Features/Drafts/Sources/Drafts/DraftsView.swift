import SwiftUI
import DesignSystem
import Models
import Networking

public struct DraftsView: View {
    @Bindable var store: DraftsStore
    let networking: any ATFNetworking
    /// Tap on a draft: pick the dish to attach it to.
    let onSelect: (Draft) -> Void
    let onBack: () -> Void

    public init(
        store: DraftsStore,
        networking: any ATFNetworking,
        onSelect: @escaping (Draft) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.store = store; self.networking = networking
        self.onSelect = onSelect; self.onBack = onBack
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            if let error = store.error {
                Text(error)
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfDanger)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            if store.isLoading {
                skeletonGrid
            } else if store.drafts.isEmpty {
                emptyState
            } else {
                draftGrid
            }
            if store.isMultiSelect && !store.selectedIDs.isEmpty {
                actionBar
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .task { await store.load(networking: networking) }
        .refreshable { await store.load(networking: networking) }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.atfText1)
            }
            Spacer()
            Text("Brouillons")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.isMultiSelect.toggle()
                    store.selectedIDs.removeAll()
                }
            } label: {
                Text(store.isMultiSelect ? "Annuler" : "Sélect.")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfAccent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 14)
        .background(Color.atfBg)
    }

    // MARK: - Grid

    private var draftGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(store.drafts) { draft in
                    DraftCard(
                        draft: draft,
                        isSelected: store.selectedIDs.contains(draft.id),
                        isMultiSelect: store.isMultiSelect,
                        onTap: {
                            if store.isMultiSelect { store.toggleSelection(draft.id) }
                            else { onSelect(draft) }
                        },
                        onLongPress: {
                            withAnimation(.easeInOut(duration: 0.2)) { store.isMultiSelect = true }
                            store.toggleSelection(draft.id)
                        }
                    )
                }
            }
            .padding(4)
            .padding(.bottom, 16)
        }
    }

    private var skeletonGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<9, id: \.self) { _ in
                    ATFSkeleton(height: 104, radius: 8)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(4)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 52))
                .foregroundStyle(Color.atfText3)
            Text("Aucun brouillon")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)
            Text("Après une photo, touche « Garder en brouillon » pour enchaîner les plats, puis attache-les ici.")
                .font(.atfBody)
                .foregroundStyle(Color.atfText2)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            ATFButton("Supprimer (\(store.selectedIDs.count))", kind: .danger, fullWidth: true,
                      loading: store.isDeleting) {
                Task { await store.deleteSelected(networking: networking) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.atfSurface)
        .overlay(Divider(), alignment: .top)
    }
}

// MARK: - DraftCard

private struct DraftCard: View {
    let draft: Draft
    let isSelected: Bool
    let isMultiSelect: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ATFAsyncImage(
                url: draft.photoURL,
                fallback: Color.atfSurface2,
                radius: 0,
                height: 104,
                overlay: false,
                contentMode: .fill
            )
            .frame(maxWidth: .infinity, minHeight: 104, maxHeight: 104)
            .clipped()

            if isMultiSelect {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.atfAccent : Color.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.atfAccent : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
    }
}

// MARK: - Preview

#Preview("DraftsView") {
    let store = DraftsStore(restaurantID: UUID())
    store.drafts = Draft.mocks
    return DraftsView(store: store, networking: MockNetworking(), onSelect: { _ in }, onBack: {})
}
