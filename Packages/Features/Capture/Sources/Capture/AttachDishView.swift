import SwiftUI
import Models
import Networking
import DesignSystem

// MARK: - AttachDishView (Screen S07)

public struct AttachDishView: View {
    @Bindable var store: CaptureStore
    let networking: any ATFNetworking
    let onNewDish: () -> Void
    let onAttached: () -> Void
    let onBack: () -> Void

    @State private var isLoading = false
    @State private var menuItems: [MenuItem] = []
    @State private var selectedItem: MenuItem? = nil
    @State private var isAttaching = false
    @State private var error: String? = nil

    public init(
        store: CaptureStore,
        networking: any ATFNetworking,
        onNewDish: @escaping () -> Void,
        onAttached: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.store = store
        self.networking = networking
        self.onNewDish = onNewDish
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
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.atfText1)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Attacher à un plat")
                        .font(.atfHeadline)
                        .foregroundStyle(Color.atfText1)
                    Spacer()
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // "+ Nouveau plat" button
                ATFButton("+ Nouveau plat", kind: .secondary, fullWidth: true, action: { onNewDish() })
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // Divider with label
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.atfSurface2)
                        .frame(height: 1)
                    Text("ou choisir un plat existant")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText3)
                        .lineLimit(1)
                    Rectangle()
                        .fill(Color.atfSurface2)
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                // Menu items list
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.atfAccent)
                    Spacer()
                } else if menuItems.isEmpty {
                    Spacer()
                    Text("Aucun plat trouvé")
                        .font(.atfBody)
                        .foregroundStyle(Color.atfText3)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(menuItems) { item in
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
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .multilineTextAlignment(.center)
                }

                ATFButton(
                    "Attacher",
                    kind: .primary,
                    fullWidth: true,
                    loading: isAttaching,
                    disabled: selectedItem == nil,
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

    private func fetchMenuItems() async {
        isLoading = true
        error = nil
        do {
            let items = try await networking.fetchMenuItems(restaurantID: store.restaurant.id)
            menuItems = items
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func attachPhoto() {
        guard let item = selectedItem else { return }
        guard let data = store.capturedImage?.jpegData(compressionQuality: 0.85) else { return }
        isAttaching = true
        error = nil
        let restaurantID = store.restaurant.id
        let dishID = item.id
        Task {
            do {
                _ = try await networking.attachPhoto(
                    imageData: data,
                    toDishID: dishID,
                    restaurantID: restaurantID
                )
                onAttached()
            } catch {
                self.error = error.localizedDescription
            }
            isAttaching = false
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
                    ATFBadge(item.category, kind: .soft)
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
        store: CaptureStore(restaurant: Restaurant.mocks[0]),
        networking: MockNetworking(),
        onNewDish: {},
        onAttached: {},
        onBack: {}
    )
}
