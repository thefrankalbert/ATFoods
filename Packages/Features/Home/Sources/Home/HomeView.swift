import SwiftUI
import Models
import Networking
import DesignSystem

/// Menu board: native list grouped by category, with a pinned category bar (tap to jump, follows the scroll),
/// search, work-queue filters and an availability switch on every dish.
public struct HomeView: View {
    @Bindable var store: HomeStore
    let networking: any ATFNetworking
    let onCamera: () -> Void
    let onDrafts: () -> Void
    let onProfile: () -> Void
    let onDish: (MenuItem) -> Void
    /// Several restaurants: the title opens a menu to switch (nil hides it).
    let onSwitchRestaurant: (() -> Void)?

    /// Category shown as current in the bar: the first one with a dish on screen.
    @State private var activeSectionID: String?
    @State private var visibleItemIDs: Set<UUID> = []
    /// While a tap scrolls to a category, rows passing by must not move the highlight.
    @State private var jumpTarget: String?

    public init(
        store: HomeStore,
        networking: any ATFNetworking,
        onCamera: @escaping () -> Void,
        onDrafts: @escaping () -> Void,
        onProfile: @escaping () -> Void,
        onDish: @escaping (MenuItem) -> Void,
        onSwitchRestaurant: (() -> Void)? = nil
    ) {
        self.onDish = onDish
        self.onSwitchRestaurant = onSwitchRestaurant
        self.store = store
        self.networking = networking
        self.onCamera = onCamera
        self.onDrafts = onDrafts
        self.onProfile = onProfile
    }

    public var body: some View {
        content
            .safeAreaInset(edge: .bottom) { CameraBar(button: cameraButton) }
            .background(Color.atfBg.ignoresSafeArea())
            .navigationTitle(store.restaurant.name)
            .toolbarBackground(Color.atfBg, for: .navigationBar)
            .toolbar { toolbarContent }
            .modifier(RestaurantSwitchMenu(onSwitch: onSwitchRestaurant))
            .searchable(text: $store.searchText, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Rechercher un plat")
            .task { await store.load(networking: networking) }   // runs on every return to Home
            .refreshable { await store.load(networking: networking) }
            .sensoryFeedback(.error, trigger: store.actionError) { _, new in new != nil }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView().tint(Color.atfText2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = store.error, store.menuItems.isEmpty {
            ContentUnavailableView {
                Label("Menu non chargé", systemImage: "wifi.exclamationmark")
            } description: {
                Text(error)
            } actions: {
                Button("Réessayer") { Task { await store.load(networking: networking) } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color.atfAccent)
            }
        } else if store.menuItems.isEmpty {
            ContentUnavailableView("Aucun plat pour l'instant", systemImage: "fork.knife",
                                   description: Text("Prenez une photo pour ajouter votre premier plat."))
        } else {
            list
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List {
                if let message = store.error ?? store.actionError {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.atfText1)
                        .listRowBackground(Color.atfSurface2)
                        .onTapGesture { store.actionError = nil }
                }

                if store.sections.isEmpty {
                    Text(emptyFilterMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.atfText2)
                        .listRowBackground(Color.clear)
                }

                ForEach(store.sections) { section in
                    // Title as a plain row, not a pinned header: the category bar already shows where you are, and a
                    // pinned header would sit over the first dish.
                    Text(section.title)
                        .font(.footnote)
                        .foregroundStyle(Color.atfText2)
                        .accessibilityAddTraits(.isHeader)
                        .listRowBackground(Color.atfBg)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
                        .id(section.id)
                    ForEach(section.items) { item in
                        DishRow(
                            item: item,
                            price: item.formattedPrice(currency: store.restaurant.currency),
                            isUpdating: store.updatingIDs.contains(item.id),
                            onOpen: { onDish(item) },
                            onToggle: { on in Task { await store.setAvailable(item.id, on, networking: networking) } }
                        )
                        .listRowBackground(Color.atfBg)
                        .onAppear { visibleItemIDs.insert(item.id); updateActiveSection() }
                        .onDisappear { visibleItemIDs.remove(item.id); updateActiveSection() }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .animation(.default, value: store.filter)
            .safeAreaInset(edge: .top, spacing: 0) { categoryBar(list: proxy) }
        }
    }

    private func updateActiveSection() {
        guard jumpTarget == nil else { return }
        let id = store.sections.first { $0.items.contains { visibleItemIDs.contains($0.id) } }?.id
        if id != activeSectionID { activeSectionID = id }
    }

    private func jump(to section: HomeStore.Section, list: ScrollViewProxy) {
        jumpTarget = section.id
        activeSectionID = section.id
        withAnimation { list.scrollTo(section.id, anchor: .top) }
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            jumpTarget = nil
        }
    }

    private var emptyFilterMessage: String {
        if !store.searchText.trimmingCharacters(in: .whitespaces).isEmpty { return "Aucun plat ne correspond à « \(store.searchText) »." }
        switch store.filter {
        case .noPhoto: return "Tous les plats ont une photo."
        case .soldOut: return "Aucun plat épuisé."
        case .all: return "Aucun plat."
        }
    }

    // MARK: - Category bar & filters

    /// Pinned under the search field: the filter button, then one chip per category (with its dish count).
    private func categoryBar(list: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            filterMenu
            if store.sections.count > 1 {
                ScrollViewReader { chips in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.sections) { section in
                                categoryChip(section, isOn: section.id == activeSectionID) { jump(to: section, list: list) }
                                    .id(section.id)
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    .accessibilityIdentifier("categoryBar")
                    .onChange(of: activeSectionID) { _, id in
                        guard let id else { return }
                        withAnimation { chips.scrollTo(id, anchor: .center) }
                    }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, 16)
        .padding(.vertical, 6)
        .background(Color.atfBg)
        .sensoryFeedback(.selection, trigger: activeSectionID)
    }

    private func categoryChip(_ section: HomeStore.Section, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(section.title)
                Text("\(section.items.count)")
                    .monospacedDigit()
                    .opacity(0.6)
            }
            .chipStyle(isOn: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(section.title), \(section.items.count) \(section.items.count > 1 ? "plats" : "plat")")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("category_\(section.title)")
    }

    /// Work queues (no photo, sold out) behind one button: a second row of chips would crowd the categories.
    private var filterMenu: some View {
        Menu {
            Picker("Afficher", selection: $store.filter) {
                ForEach(HomeStore.Filter.allCases, id: \.self) { filter in
                    Text(filter == .all ? "Tous les plats" : "\(filter.label) · \(store.count(filter))").tag(filter)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                if store.filter != .all { Text("\(store.filter.label) · \(store.count(store.filter))") }
            }
            .chipStyle(isOn: store.filter != .all)
        }
        .accessibilityLabel(store.filter == .all ? "Filtrer" : "Filtre : \(store.filter.label)")
        .accessibilityIdentifier("filterMenu")
        .sensoryFeedback(.selection, trigger: store.filter)
    }

    // MARK: - Toolbar & camera

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: onDrafts) {
                Image(systemName: "square.stack")
            }
            .accessibilityLabel("Brouillons")
            .accessibilityIdentifier("draftsButton")

            Button(action: onProfile) {
                Image(systemName: "person.crop.circle")
            }
            .accessibilityLabel("Profil")
            .accessibilityIdentifier("profileButton")
        }
    }

    private var cameraButton: some View {
        Button(action: onCamera) {
            Label("Prendre une photo", systemImage: "camera")
                .font(.headline)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Color.atfAccent)
        .foregroundStyle(Color.atfAccentOn)
        .accessibilityIdentifier("cameraButton")
        // Full-width opaque bar: rows never show beside the button and the scroll indicator ends above it.
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.atfBg)
    }
}

/// Several restaurants: the title reads "Chez Flora ⌄" and opens the switch (iOS puts title menus on the compact
/// title only; a large title would be plain text nobody knows to tap). One restaurant: large title.
private struct RestaurantSwitchMenu: ViewModifier {
    let onSwitch: (() -> Void)?
    func body(content: Content) -> some View {
        if let onSwitch {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbarTitleMenu {
                Button(action: onSwitch) {
                    Label("Changer d'établissement", systemImage: "arrow.left.arrow.right")
                }
            }
        } else {
            content.navigationBarTitleDisplayMode(.large)
        }
    }
}

/// The camera button leaves the screen while the user searches: it would float above the keyboard.
private struct CameraBar<Content: View>: View {
    @Environment(\.isSearching) private var isSearching
    let button: Content
    var body: some View {
        if !isSearching { button }
    }
}

// MARK: - Dish row

private struct DishRow: View {
    let item: MenuItem
    let price: String
    let isUpdating: Bool
    let onOpen: () -> Void
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    thumbnail
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.body)
                            .foregroundStyle(item.isAvailable ? Color.atfText1 : Color.atfText2)
                            .lineLimit(2)
                        Text(subtitle)
                            .font(.footnote)
                            .monospacedDigit()
                            .foregroundStyle(Color.atfText2)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("Disponible", isOn: Binding(get: { item.isAvailable }, set: onToggle))
                .labelsHidden()
                .tint(Color.atfAccent)
                .disabled(isUpdating)
                .accessibilityLabel("\(item.name) disponible")
                .sensoryFeedback(.impact(weight: .light), trigger: item.isAvailable)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        var parts = [price]
        if item.photoURL == nil { parts.append("Sans photo") }
        if !item.isAvailable { parts.append("Épuisé") }
        return parts.joined(separator: " · ")
    }

    private var thumbnail: some View {
        ATFRemoteImage(Thumbnail.url(item.photoURL, points: 56), fallback: item.photoURL) {
            ZStack {
                Color.atfSurface2
                Image(systemName: item.photoURL == nil ? "camera" : "photo")
                    .foregroundStyle(Color.atfText3)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(item.isAvailable ? 1 : 0.5)
        .accessibilityHidden(true)
    }
}

private extension View {
    func chipStyle(isOn: Bool) -> some View {
        font(.subheadline)
            .foregroundStyle(isOn ? Color.atfAccentOn : Color.atfText1)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(isOn ? Color.atfAccent : Color.atfSurface2, in: Capsule())
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("HomeView") {
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    store.menuItems = MenuItem.mocks
    return NavigationStack {
        HomeView(store: store, networking: MockNetworking(), onCamera: {}, onDrafts: {}, onProfile: {}, onDish: { _ in })
    }
}
#endif
