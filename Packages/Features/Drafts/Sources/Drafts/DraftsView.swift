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

    @State private var confirmDelete = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            if let error = store.error, !store.drafts.isEmpty {
                Text(error)
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfDanger)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            if store.isLoading {
                skeletonGrid
            } else if let error = store.error, store.drafts.isEmpty {
                // Load failed: say so, never pretend there is nothing.
                VStack(spacing: 12) {
                    Spacer()
                    Text(error)
                        .font(.atfBody)
                        .foregroundStyle(Color.atfText2)
                        .multilineTextAlignment(.center)
                    ATFButton("Réessayer", kind: .secondary) {
                        Task { await store.load(networking: networking) }
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)
            } else if store.drafts.isEmpty {
                // Scrollable so pull-to-refresh works on the empty state too.
                ScrollView { emptyState.containerRelativeFrame(.vertical) }
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
        .confirmationDialog(
            store.selectedIDs.count > 1 ? "Supprimer \(store.selectedIDs.count) brouillons ?" : "Supprimer ce brouillon ?",
            isPresented: $confirmDelete, titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                Task { await store.deleteSelected(networking: networking) }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Les photos seront définitivement effacées.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ATFHeader("Brouillons", onBack: onBack) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.isMultiSelect.toggle()
                    store.selectedIDs.removeAll()
                }
            } label: {
                Text(store.isMultiSelect ? "Annuler" : "Sélectionner")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.atfText1)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Grid

    private var draftGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var skeletonGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<9, id: \.self) { _ in
                    ATFSkeleton(height: 104, radius: 8)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
            Text("Après une photo, touchez « Garder en brouillon » pour enchaîner les plats, puis attachez-les ici.")
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
                confirmDelete = true
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
            // The cell sets the size; a .fill image laid out directly would push the grid column wider.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 104)
                .overlay {
                    ATFAsyncImage(
                        url: Thumbnail.url(draft.photoURL, points: 120),
                        fallback: Color.atfSurface2,
                        radius: 0,
                        height: 104,
                        overlay: false,
                        contentMode: .fill
                    )
                }
                .clipped()

            if isMultiSelect {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(isSelected ? Color.atfAccentOn : Color.white, isSelected ? Color.atfAccent : Color.black.opacity(0.35))
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.atfAccent : Color.clear, lineWidth: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Brouillon du \(draft.createdAt.formatted(date: .abbreviated, time: .shortened))")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isMultiSelect ? "Sélectionner" : "Choisir le plat à illustrer")
        .accessibilityAction(named: "Sélectionner", onLongPress)
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("DraftsView") {
    let store = DraftsStore(restaurantID: UUID())
    store.drafts = Draft.mocks
    return DraftsView(store: store, networking: MockNetworking(), onSelect: { _ in }, onBack: {})
}
#endif
