import SwiftUI
import DesignSystem
import Models
import Networking

public struct ProfileView: View {
    @Bindable var store: ProfileStore
    let networking: any ATFNetworking
    @Environment(\.openURL) private var openURL
    /// nil when the user has a single restaurant (row hidden).
    let onSwitchRestaurant: (() -> Void)?
    let onSignOut: () -> Void
    let onBack: () -> Void

    public init(
        store: ProfileStore,
        networking: any ATFNetworking,
        onSwitchRestaurant: (() -> Void)? = nil,
        onSignOut: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.onSwitchRestaurant = onSwitchRestaurant
        self.store = store; self.networking = networking
        self.onSignOut = onSignOut; self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                avatarSection
                restaurantCard
                settingsList
                signOutButton
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
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
                store.restaurant.plan.displayName,
                kind: store.restaurant.plan == .starter ? .soft : .pro
            )
        }
        .padding(.vertical, 28)
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
            ATFBadge(store.restaurant.role.displayName, kind: .soft)
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
            // Compte
            if let onSwitchRestaurant {
                settingsRow(icon: "arrow.left.arrow.right", label: "Changer de restaurant", action: onSwitchRestaurant)
                Divider().padding(.leading, 52)
            }
            settingsRow(icon: "safari", label: "Ouvrir le dashboard web", action: openDashboard)

            Divider().padding(.leading, 16).padding(.vertical, 8)

            // À propos
            settingsRow(icon: "ant", label: "Signaler un bug", action: reportBug)
            Divider().padding(.leading, 52)
            settingsRow(icon: "info.circle", label: "Aide & Support", action: openSupport)
            Divider().padding(.leading, 52)
            settingsRow(icon: "doc.text", label: "Conditions d'utilisation", action: openTerms)
            Divider().padding(.leading, 52)
            settingsRowInfo(icon: "number", label: "Version", value: appVersion)
        }
        .background(Color.atfSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.atfBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func settingsRowInfo(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.atfText2)
                .frame(width: 22)
            Text(label)
                .font(.atfSubhead)
                .foregroundStyle(Color.atfText1)
            Spacer()
            Text(value)
                .font(.atfCaption)
                .foregroundStyle(Color.atfText3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    private func openDashboard() {
        openURL(URL(string: "https://attabl.com")!)
    }

    private func reportBug() {
        openURL(URL(string: "mailto:support@attabl.com?subject=Bug%20At%20Food")!)
    }

    private func openSupport() {
        openURL(URL(string: "https://attabl.com/support")!)
    }

    private func openTerms() {
        openURL(URL(string: "https://attabl.com/legal")!)
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
                       onSignOut: {}, onBack: {})
}
