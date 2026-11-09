import SwiftUI
import Models
import Networking
import DesignSystem

// MARK: - AttachDishView (Screen S07)

public struct AttachDishView: View {
    let restaurant: Restaurant
    let networking: any ATFNetworking
    let onNewDish: () -> Void
    /// Performs the attach (fresh photo upload or draft copy). Throws to show the error.
    let attach: (MenuItem) async throws -> Void
    /// Only for a fresh capture: keep the photo as a draft and go on shooting.
    let saveDraft: (() async throws -> Void)?
    let onAttached: () -> Void
    let onBack: () -> Void
    /// Photo taken from a dish card: no list, the photo goes to this dish.
    let fixedDish: MenuItem?

    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var search = ""
    @State private var menuItems: [MenuItem] = []
    @State private var selectedItem: MenuItem? = nil
    @State private var isAttaching = false
    @State private var isSavingDraft = false
    @State private var error: String? = nil

    /// One operation at a time: attach and draft both pop the stack and must never overlap.
    private var isBusy: Bool { isAttaching || isSavingDraft }

    public init(
        restaurant: Restaurant,
        networking: any ATFNetworking,
        onNewDish: @escaping () -> Void,
        attach: @escaping (MenuItem) async throws -> Void,
        saveDraft: (() async throws -> Void)? = nil,
        onAttached: @escaping () -> Void,
        onBack: @escaping () -> Void,
        fixedDish: MenuItem? = nil
    ) {
        self.fixedDish = fixedDish
        self.restaurant = restaurant
        self.networking = networking
        self.onNewDish = onNewDish
        self.attach = attach
        self.saveDraft = saveDraft
        self.onAttached = onAttached
        self.onBack = onBack
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.atfSurface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { onBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.atfAccent)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(isBusy)
                    .accessibilityLabel("Retour")
                    Spacer()
                    Text(fixedDish == nil ? "Attacher à un plat" : "Remplacer la photo")
                        .font(.atfHeadline)
                        .foregroundStyle(Color.atfText1)
                    Spacer()
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if fixedDish == nil {
                // "+ Nouveau plat" button
                ATFButton("+ Nouveau plat", kind: .secondary, fullWidth: true, disabled: isBusy, action: { onNewDish() })
                    .padding(.horizontal, 20)
                    .padding(.bottom, saveDraft == nil ? 16 : 8)

                if saveDraft != nil {
                    ATFButton("Garder en brouillon", kind: .ghost, fullWidth: true,
                              loading: isSavingDraft, disabled: isAttaching, action: { keepAsDraft() })
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .accessibilityIdentifier("saveDraftButton")
                }

                // Divider with label
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.atfSurface2)
                        .frame(height: 1)
                    Text("ou choisir un plat existant")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText3)
                        .lineLimit(1)
                        .fixedSize()
                    Rectangle()
                        .fill(Color.atfSurface2)
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                ATFTextField(text: $search, placeholder: "Rechercher un plat", rightIcon: .search)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

                // Menu items list
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.atfAccent)
                    Spacer()
                } else if loadFailed {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("Impossible de charger vos plats.")
                            .font(.atfBody)
                            .foregroundStyle(Color.atfText2)
                        ATFButton("Réessayer", kind: .secondary) { Task { await fetchMenuItems() } }
                    }
                    Spacer()
                } else if filteredItems.isEmpty {
                    Spacer()
                    Text(menuItems.isEmpty ? "Aucun plat pour l'instant : créez-en un." : "Aucun plat ne correspond.")
                        .font(.atfBody)
                        .foregroundStyle(Color.atfText3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredItems) { item in
                                DishRow(
                                    item: item,
                                    isSelected: selectedItem?.id == item.id,
                                    onTap: { selectedItem = item }
                                )
                                Divider()
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }

                // Bottom padding for the fixed "Attacher" button
                Spacer().frame(height: 100)
            }

            // Fixed bottom button
            VStack(spacing: 0) {
                if let errorMsg = error {
                    Text(errorMsg)
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfDanger)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .multilineTextAlignment(.center)
                }

                ATFButton(
                    fixedDish == nil ? "Attacher" : "Remplacer la photo",
                    kind: .primary,
                    fullWidth: true,
                    loading: isAttaching,
                    disabled: selectedItem == nil || isSavingDraft,
                    action: { attachPhoto() }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                Color.atfSurface
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
            )
        }
        .task {
            await fetchMenuItems()
        }
    }

    // MARK: - Actions

    /// Accent- and case-insensitive name search (e.g. "mafe" finds "Mafé").
    private var filteredItems: [MenuItem] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return menuItems }
        return menuItems.filter { $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private func fetchMenuItems() async {
        if let fixedDish {
            menuItems = [fixedDish]
            selectedItem = fixedDish
            return
        }
        isLoading = true
        loadFailed = false
        do {
            menuItems = try await networking.fetchMenuItems(restaurantID: restaurant.id)
        } catch {
            loadFailed = true
        }
        isLoading = false
    }

    private func attachPhoto() {
        guard let item = selectedItem, !isBusy else { return }
        isAttaching = true
        error = nil
        Task {
            do {
                try await attach(item)
                onAttached()
            } catch {
                self.error = UserMessage.from(error)
            }
            isAttaching = false
        }
    }

    private func keepAsDraft() {
        guard let saveDraft, !isBusy else { return }
        isSavingDraft = true
        error = nil
        Task {
            do {
                try await saveDraft()
            } catch {
                self.error = UserMessage.from(error)
            }
            isSavingDraft = false
        }
    }
}

// MARK: - DishRow

private struct DishRow: View {
    let item: MenuItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: { onTap() }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.atfBody)
                        .foregroundStyle(Color.atfText1)
                    HStack(spacing: 6) {
                        if !item.category.isEmpty { ATFBadge(item.category, kind: .soft) }
                        if item.photoURL != nil {
                            Text("Remplacera la photo actuelle")
                                .font(.atfCaption)
                                .foregroundStyle(Color.atfText3)
                        }
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.atfAccent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("AttachDishView") {
    AttachDishView(
        restaurant: Restaurant.mocks[0],
        networking: MockNetworking(),
        onNewDish: {},
        attach: { _ in },
        saveDraft: {},
        onAttached: {},
        onBack: {}
    )
}
