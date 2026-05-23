import SwiftUI
import DesignSystem
import Models
import Networking

public struct ProfileView: View {
    @Bindable var store: ProfileStore
    let networking: any ATFNetworking
    let onCredits: () -> Void
    let onUpgrade: () -> Void
    let onOffline: () -> Void
    let onSignOut: () -> Void
    let onBack: () -> Void

    public init(
        store: ProfileStore,
        networking: any ATFNetworking,
        onCredits: @escaping () -> Void,
        onUpgrade: @escaping () -> Void,
        onOffline: @escaping () -> Void,
        onSignOut: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.store = store; self.networking = networking
        self.onCredits = onCredits; self.onUpgrade = onUpgrade
        self.onOffline = onOffline; self.onSignOut = onSignOut; self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                avatarSection
                planCard
                creditsCard
                restaurantCard
                settingsList
                signOutButton
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .task { await store.loadCredits(networking: networking) }
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
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 8)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack {
                LinearGradient(
                    colors: [Color.atfAccent, Color.atfAccentHover],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Circle())
                .frame(width: 80, height: 80)

                Text(store.user.name.prefix(1).uppercased())
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(store.user.name)
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)

            Text(store.user.email)
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)

            ATFBadge(
                store.user.plan == .pro ? "Pro" : "Gratuit",
                kind: store.user.plan == .pro ? .pro : .soft
            )
        }
        .padding(.vertical, 28)
    }

    // MARK: - Plan Card

    private var planCard: some View {
        Group {
            if store.user.plan != .pro {
                Button(action: onUpgrade) {
                    HStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.atfAccent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Passer au Pro")
                                .font(.atfBodyStr)
                                .foregroundStyle(Color.atfText1)
                            Text("IA illimitée, fonds personnalisés…")
                                .font(.atfCaption)
                                .foregroundStyle(Color.atfText2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.atfText3)
                    }
                    .padding(16)
                    .background(Color.atfSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.atfAccent.opacity(0.5), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Credits Card

    private var creditsCard: some View {
        Button(action: onCredits) {
            HStack(spacing: 14) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.atfAccent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Crédits IA")
                        .font(.atfBodyStr)
                        .foregroundStyle(Color.atfText1)
                    Text("\(store.creditsBalance) / \(store.creditsTotal) disponibles")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.atfText3)
            }
            .padding(16)
            .background(Color.atfSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.atfBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Restaurant Card

    private var restaurantCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "fork.knife")
                .font(.system(size: 20))
                .foregroundStyle(Color.atfText2)
            VStack(alignment: .leading, spacing: 3) {
                Text("Restaurant actif")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText2)
                Text(store.restaurant.name)
                    .font(.atfBodyStr)
                    .foregroundStyle(Color.atfText1)
            }
            Spacer()
            ATFBadge(store.restaurant.role.rawValue, kind: .soft)
        }
        .padding(16)
        .background(Color.atfSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.atfBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Settings List

    private var settingsList: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "bell", label: "Notifications", action: {})
            Divider().padding(.leading, 52)
            settingsRow(icon: "globe", label: "Langue", action: {})
            Divider().padding(.leading, 52)
            settingsRow(icon: "wifi.slash", label: "Mode hors-ligne", action: onOffline)
            Divider().padding(.leading, 52)
            settingsRow(icon: "info.circle", label: "Aide & Support", action: {})
            Divider().padding(.leading, 52)
            settingsRow(icon: "doc.text", label: "Conditions d'utilisation", action: {})
        }
        .background(Color.atfSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.atfBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func settingsRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.atfText2)
                    .frame(width: 22)
                Text(label)
                    .font(.atfSubhead)
                    .foregroundStyle(Color.atfText1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.atfText3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        ATFButton(
            "Se déconnecter",
            kind: .danger,
            fullWidth: true,
            loading: store.isSigningOut
        ) {
            Task {
                await store.signOut(networking: networking)
                onSignOut()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("ProfileView") {
    let store = ProfileStore(user: AppUser.mock, restaurant: Restaurant.mocks[0])
    return ProfileView(store: store, networking: MockNetworking(),
                       onCredits: {}, onUpgrade: {}, onOffline: {}, onSignOut: {}, onBack: {})
}
