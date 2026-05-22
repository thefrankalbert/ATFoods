import SwiftUI
import Models
import Networking
import DesignSystem

public struct HomeView: View {
    @Bindable var store: HomeStore
    let networking: any ATFNetworking
    let onCamera: () -> Void

    public init(store: HomeStore, networking: any ATFNetworking, onCamera: @escaping () -> Void) {
        self.store = store
        self.networking = networking
        self.onCamera = onCamera
    }

    private let bgColor = Color(red: 0.059, green: 0.035, blue: 0.024)

    public var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                categoryFilter
                mainContent
            }
        }
        .task { await store.load(networking: networking) }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            ATFWordmark(size: 20, color: .white)

            Spacer()

            Text(store.restaurant.name)
                .font(.atfCaption)
                .foregroundStyle(Color.white.opacity(0.7))

            Spacer()

            Button(action: onCamera) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(label: "Tous", isSelected: store.selectedCategory == nil) {
                    store.selectedCategory = nil
                }

                ForEach(MenuCategory.allCases, id: \.self) { category in
                    categoryChip(
                        label: category.displayName,
                        isSelected: store.selectedCategory == category
                    ) {
                        store.selectedCategory = category
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
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? Color.atfAccent
                        : Color.white.opacity(0.12)
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if store.isLoading {
            skeletonGrid
        } else if store.menuItems.isEmpty {
            emptyState
        } else {
            foodGrid
        }
    }

    private var skeletonGrid: some View {
        let columns = [
            GridItem(.fixed(148), spacing: 12),
            GridItem(.fixed(148), spacing: 12)
        ]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    ATFSkeleton(width: 148, height: 170, radius: 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var foodGrid: some View {
        let columns = [
            GridItem(.fixed(148), spacing: 12),
            GridItem(.fixed(148), spacing: 12)
        ]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.filteredItems) { item in
                    ATFFoodCard(
                        name: item.name,
                        priceFormatted: item.priceFormatted,
                        photoURL: item.photoURL,
                        isAvailable: item.isAvailable
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(Color.white.opacity(0.5))
            Text("Aucun plat pour l'instant")
                .font(.atfHeadline)
                .foregroundStyle(.white)
            Text("Ajoutez votre premier plat")
                .font(.atfBody)
                .foregroundStyle(Color.white.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("HomeView") {
    let store = HomeStore(restaurant: Restaurant.mocks[0])
    store.menuItems = MenuItem.mocks
    return HomeView(store: store, networking: MockNetworking()) {}
}
