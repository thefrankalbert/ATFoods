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
        fixedDish: MenuItem? = nil
    ) {
        self.fixedDish = fixedDish
        self.restaurant = restaurant
        self.networking = networking
        self.onNewDish = onNewDish
        self.attach = attach
        self.saveDraft = saveDraft
        self.onAttached = onAttached
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    if fixedDish == nil {
                        ATFSection {
                            actionRow("Créer un nouveau plat", icon: "plus", action: onNewDish)
                            if saveDraft != nil {
                                ATFRowDivider()
                                actionRow("Garder en brouillon", icon: "square.stack", loading: isSavingDraft, action: keepAsDraft)
                                    .accessibilityIdentifier("saveDraftButton")
                            }
                        }
                        searchField
                    }
                    dishList
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: 8) {
                if let errorMsg = error {
                    Text(errorMsg)
                        .font(.footnote)
                        .foregroundStyle(Color.atfDanger)
                        .multilineTextAlignment(.center)
                }
                ATFButton(
                    attachLabel,
                    kind: .primary,
                    fullWidth: true,
                    loading: isAttaching,
                    disabled: selectedItem == nil || isSavingDraft,
                    action: { attachPhoto() }
                )
                .accessibilityIdentifier("attachButton")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.atfBg)
        }
        .background(Color.atfBg.ignoresSafeArea())
        .atfScreen(fixedDish == nil ? "Cette photo, c'est pour…" : "Remplacer la photo")
        .navigationBarBackButtonHidden(isBusy)   // attach and draft pop the stack themselves
        .sensoryFeedback(.selection, trigger: selectedItem?.id)
        .sensoryFeedback(.error, trigger: error) { _, new in new != nil }
        .task {
            await fetchMenuItems()
        }
    }

    private var attachLabel: String {
        if fixedDish != nil { return "Remplacer la photo" }
        guard let selectedItem else { return "Attacher" }
        return "Attacher à \(selectedItem.name)"
    }

    private func actionRow(_ title: String, icon: String, loading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Group {
                    if loading { ProgressView().tint(Color.atfText2) } else { Image(systemName: icon) }
                }
                .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.atfText3)
            }
            .foregroundStyle(Color.atfText1)
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.atfText3)
            TextField("Rechercher un plat", text: $search)
                .autocorrectionDisabled()
                .foregroundStyle(Color.atfText1)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color.atfField, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var dishList: some View {
        if isLoading {
            ProgressView().tint(Color.atfText2).padding(.top, 32)
        } else if loadFailed {
            VStack(spacing: 12) {
                Text("Impossible de charger vos plats.")
                    .font(.subheadline)
                    .foregroundStyle(Color.atfText2)
                ATFButton("Réessayer", kind: .secondary) { Task { await fetchMenuItems() } }
            }
            .padding(.top, 32)
        } else if filteredItems.isEmpty {
            Text(menuItems.isEmpty ? "Aucun plat pour l'instant : créez-en un." : "Aucun plat ne correspond.")
                .font(.subheadline)
                .foregroundStyle(Color.atfText2)
                .multilineTextAlignment(.center)
                .padding(.top, 32)
        } else {
            ATFSection(fixedDish == nil ? "Ou un plat de votre carte" : nil) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 { ATFRowDivider() }
                        DishRow(item: item, isSelected: selectedItem?.id == item.id) { selectedItem = item }
                    }
                }
            }
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
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: Thumbnail.url(item.photoURL, points: 44)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.atfSurface2.overlay(
                            Image(systemName: item.photoURL == nil ? "camera" : "photo").foregroundStyle(Color.atfText3)
                        )
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(isSelected ? .body.weight(.semibold) : .body)
                        .foregroundStyle(Color.atfText1)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.atfText2)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.atfText1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var subtitle: String {
        [item.category.isEmpty ? nil : item.category,
         item.photoURL == nil ? "Sans photo" : "Remplacera la photo actuelle"]
            .compactMap { $0 }.joined(separator: " · ")
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("AttachDishView") {
    AttachDishView(
        restaurant: Restaurant.mocks[0],
        networking: MockNetworking(),
        onNewDish: {},
        attach: { _ in },
        saveDraft: {},
        onAttached: {}
    )
}
#endif
