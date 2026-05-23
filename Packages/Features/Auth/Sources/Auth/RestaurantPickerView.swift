import SwiftUI
import DesignSystem
import Models

public struct RestaurantPickerView: View {
    @Bindable var store: AuthStore
    let onContinue: () -> Void

    public init(store: AuthStore, onContinue: @escaping () -> Void) {
        self.store = store
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                if let user = store.currentUser {
                    Text("Bonjour, \(user.name) 👋")
                        .font(.atfSubhead)
                        .foregroundStyle(Color.atfText2)
                }
                Text("Quel établissement ?")
                    .font(.atfTitle)
                    .foregroundStyle(Color.atfText1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 52)
            .padding(.bottom, 24)

            // Restaurant list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.restaurants) { restaurant in
                        Button {
                            store.selectedRestaurant = restaurant
                        } label: {
                            RestaurantRow(
                                restaurant: restaurant,
                                isSelected: store.selectedRestaurant?.id == restaurant.id
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("restaurant_\(restaurant.name)")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            Spacer(minLength: 0)

            // Bottom button
            VStack(spacing: 0) {
                Divider()
                    .background(Color.atfBorder)
                ATFButton("Continuer", kind: .primary, fullWidth: true) {
                    onContinue()
                }
                .disabled(store.selectedRestaurant == nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(Color.atfSurface)
        }
        .background(Color.atfSurface.ignoresSafeArea())
    }
}

// MARK: - Restaurant Row

private struct RestaurantRow: View {
    let restaurant: Restaurant
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            ATFAsyncImage(
                url: restaurant.photoURL,
                fallback: Color.atfAccent.opacity(0.18),
                radius: 10,
                height: 48,
                width: 48,
                overlay: false,
                contentMode: .fill
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.atfBodyStr)
                    .foregroundStyle(Color.atfText1)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(restaurant.city)
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText2)

                    Text("·")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText3)

                    Text("\(restaurant.dishCount) plats")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText2)
                }
            }

            Spacer()

            // Role badge
            ATFBadge(restaurant.role.rawValue, kind: .soft)

            // Selected checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.atfAccent)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.atfText3)
            }
        }
        .padding(14)
        .background(Color.atfBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isSelected ? Color.atfAccent : Color.atfBorder,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

// MARK: - Preview

#Preview("RestaurantPickerView") {
    let store = AuthStore()
    store.restaurants = Restaurant.mocks
    store.currentUser = AppUser.mock
    return RestaurantPickerView(store: store) {}
}
