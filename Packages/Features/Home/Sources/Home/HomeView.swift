import SwiftUI
import Models
import Networking
import DesignSystem

/// Menu board: native list with search, work-queue filters and an availability switch on every dish.
public struct HomeView: View {
    @Bindable var store: HomeStore
    let networking: any ATFNetworking
    let onCamera: () -> Void
    let onDrafts: () -> Void
    let onProfile: () -> Void
    let onDish: (MenuItem) -> Void

    public init(
        store: HomeStore,
        networking: any ATFNetworking,
        onCamera: @escaping () -> Void,
        onDrafts: @escaping () -> Void,
        onProfile: @escaping () -> Void,
        onDish: @escaping (MenuItem) -> Void
    ) {
        self.onDish = onDish
        self.store = store
        self.networking = networking
        self.onCamera = onCamera
        self.onDrafts = onDrafts
        self.onProfile = onProfile
    }

    public var body: some View {
        content
            .safeAreaInset(edge: .bottom) { cameraButton }
            .background(Color.atfBg.ignoresSafeArea())
            .navigationTitle(store.restaurant.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.atfBg, for: .navigationBar)
            .toolbar { toolbarContent }
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
        List {
            Section {
                filterBar
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                if let message = store.error ?? store.actionError {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.atfText1)
                        .listRowBackground(Color.atfSurface2)
                        .onTapGesture { store.actionError = nil }
                }
            }

            if store.sections.isEmpty {
                Text(emptyFilterMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color.atfText2)
                    .listRowBackground(Color.clear)
            }

            ForEach(store.sections) { section in
                Section {
                    ForEach(section.items) { item in
                        DishRow(
                            item: item,
                            price: item.formattedPrice(currency: store.restaurant.currency),
                            isUpdating: store.updatingIDs.contains(item.id),
                            onOpen: { onDish(item) },
                            onToggle: { on in Task { await store.setAvailable(item.id, on, networking: networking) } }
                        )
                        .listRowBackground(Color.atfBg)
                    }
                } header: {
                    Text(section.title)
                        .font(.footnote)
                        .foregroundStyle(Color.atfText2)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.default, value: store.filter)
        .animation(.default, value: store.selectedCategoryID)
    }

    private var emptyFilterMessage: String {
        if !store.searchText.trimmingCharacters(in: .whitespaces).isEmpty { return "Aucun plat ne correspond à « \(store.searchText) »." }
        switch store.filter {
        case .noPhoto: return "Tous les plats ont une photo."
        case .soldOut: return "Aucun plat épuisé."
        case .all: return "Aucun plat dans cette catégorie."
        }
    }

    // MARK: - Filters

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HomeStore.Filter.allCases, id: \.self) { filter in
                    chip(filter == .all ? filter.label : "\(filter.label) · \(store.count(filter))",
                         isOn: store.filter == filter) { store.filter = filter }
                }
                if store.categories.count > 1 { categoryMenu }
            }
            .padding(.horizontal, 16)
        }
        .sensoryFeedback(.selection, trigger: store.filter)
    }

    private var categoryMenu: some View {
        Menu {
            Picker("Catégorie", selection: $store.selectedCategoryID) {
                Text("Toutes les catégories").tag(UUID?.none)
                ForEach(store.categories) { category in
                    Text(category.name).tag(UUID?.some(category.id))
                }
            }
        } label: {
            let name = store.categories.first { $0.id == store.selectedCategoryID }?.name
            HStack(spacing: 4) {
                Text(name ?? "Catégories")
                Image(systemName: "chevron.down").font(.caption.weight(.semibold))
            }
            .chipStyle(isOn: name != nil)
        }
        .accessibilityLabel("Catégorie")
    }

    private func chip(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).chipStyle(isOn: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
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
                .frame(height: 44)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(Color.atfAccent)
        .foregroundStyle(Color.atfAccentOn)
        .padding(.bottom, 8)
        .accessibilityIdentifier("cameraButton")
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
        AsyncImage(url: item.photoURL) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    Color.atfSurface2
                    Image(systemName: item.photoURL == nil ? "camera" : "photo")
                        .foregroundStyle(Color.atfText3)
                }
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
            .frame(height: 36)
            .background(isOn ? Color.atfAccent : Color.atfSurface2, in: Capsule())
            .frame(minHeight: 44)
    }
}

// MARK: - Preview

#Preview("HomeView") {
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    store.menuItems = MenuItem.mocks
    return NavigationStack {
        HomeView(store: store, networking: MockNetworking(), onCamera: {}, onDrafts: {}, onProfile: {}, onDish: { _ in })
    }
}
