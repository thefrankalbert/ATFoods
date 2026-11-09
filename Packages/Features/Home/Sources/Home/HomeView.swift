import SwiftUI
import Models
import Networking
import DesignSystem

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

    // Same light surface as every other screen (login, dish card, drafts, profile).
    private let bgColor = Color.atfBg

    public var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                categoryFilter
                if let error = store.error, !store.menuItems.isEmpty {
                    // Refresh failed: keep the menu visible, say it may be outdated.
                    Label("Menu non actualisé : \(error)", systemImage: "wifi.exclamationmark")
                        .font(.atfCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.atfDanger.opacity(0.85))
                }
                mainContent
            }
        }
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(bgColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await store.load(networking: networking) }   // runs on every return to Home
        .refreshable { await store.load(networking: networking) }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: onProfile) {
                Image(systemName: "person.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.atfText1)
            }
            .accessibilityLabel("Profil")
            .accessibilityIdentifier("profileButton")
        }
        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                ATFWordmark(size: 18)
                Text(store.restaurant.name)
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText2)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: onDrafts) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.atfText1)
            }
            .accessibilityLabel("Brouillons")
            .accessibilityIdentifier("draftsButton")

            Button(action: onCamera) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.atfAccent)
            }
            .accessibilityLabel("Prendre une photo")
            .accessibilityIdentifier("cameraButton")
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(label: "Tous", isSelected: store.selectedCategoryID == nil) {
                    store.selectedCategoryID = nil
                }

                ForEach(store.categories) { category in
                    categoryChip(
                        label: category.name,
                        isSelected: store.selectedCategoryID == category.id
                    ) {
                        store.selectedCategoryID = category.id
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func categoryChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.atfCaption)
                .foregroundStyle(isSelected ? Color.white : Color.atfText2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? Color.atfAccent
                        : Color.atfSurface2
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if store.isLoading {
            skeletonGrid
        } else if let error = store.error, store.menuItems.isEmpty {
            errorState(error)
        } else if store.menuItems.isEmpty {
            emptyState
        } else if store.filteredItems.isEmpty {
            Text("Aucun plat dans cette catégorie")
                .font(.atfBody)
                .foregroundStyle(Color.atfText2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            foodGrid
        }
    }

    private var skeletonGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    ATFSkeleton(height: 180, radius: 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var foodGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(store.filteredItems) { item in
                    ATFFoodCard(
                        name: item.name,
                        priceFormatted: item.formattedPrice(currency: store.restaurant.currency),
                        photoURL: item.photoURL,
                        isAvailable: item.isAvailable,
                        onTap: { onDish(item) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.atfText3)
            Text("Impossible de charger le menu")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)
            Text(message)
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)
                .multilineTextAlignment(.center)
            ATFButton("Réessayer", kind: .primary) {
                Task { await store.load(networking: networking) }
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(Color.atfText3)
            Text("Aucun plat pour l'instant")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)
            Text("Touchez l'appareil photo pour ajouter votre premier plat")
                .font(.atfBody)
                .foregroundStyle(Color.atfText2)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("HomeView") {
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    store.menuItems = MenuItem.mocks
    return HomeView(store: store, networking: MockNetworking(), onCamera: {}, onDrafts: {}, onProfile: {}, onDish: { _ in })
}
