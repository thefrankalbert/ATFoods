import SwiftUI
import DesignSystem
import Models
import Networking

public struct ProfileView: View {
    @Bindable var store: ProfileStore
    let networking: any ATFNetworking
    @Environment(\.openURL) private var openURL
    @State private var confirmDeletion = false
    @State private var mailFallback = false
    /// nil when the user has a single restaurant (row hidden).
    let onSwitchRestaurant: (() -> Void)?
    let onSignOut: () -> Void

    public init(
        store: ProfileStore,
        networking: any ATFNetworking,
        onSwitchRestaurant: (() -> Void)? = nil,
        onSignOut: @escaping () -> Void
    ) {
        self.onSwitchRestaurant = onSwitchRestaurant
        self.store = store; self.networking = networking
        self.onSignOut = onSignOut
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                avatarSection
                restaurantCard
                settingsList
                deletionCard
                signOutButton
                    .padding(.top, 24)
                    .padding(.bottom, 48)
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .atfScreen("Profil")
        .confirmationDialog("Supprimer définitivement votre compte ?", isPresented: $confirmDeletion, titleVisibility: .visible) {
            Button("Supprimer mon compte", role: .destructive) {
                Task {
                    await store.deleteAccount(networking: networking)
                    if store.deletionOutcome == .deleted { onSignOut() }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Votre accès à tous vos restaurants et vos données personnelles sont supprimés. Les plats et photos de vos restaurants restent en ligne. Cette action est irréversible.")
        }
        .alert(deletionAlertTitle, isPresented: deletionAlertShown) {
            switch store.deletionOutcome {
            case .soleOwner, .groupOwner:
                // Apple 5.1.1(v): the deletion is started here, in the app, not by writing to support.
                Button("Demander la suppression", role: .destructive) {
                    Task { await store.requestDeletion(networking: networking) }
                }
                Button("Annuler", role: .cancel) {}
            case .requested:
                Button("OK", role: .cancel) {}
            default:
                Button("Contacter le support") { requestAccountDeletion() }
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(deletionAlertMessage)
        }
        .alert("Écrivez-nous", isPresented: $mailFallback) {
            Button("Copier l'adresse") { UIPasteboard.general.string = AttablWeb.supportEmail }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Aucune app de messagerie n'est configurée. Écrivez à \(AttablWeb.supportEmail).")
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.atfSurface2)
                    .frame(width: 80, height: 80)

                Text((store.user.name.isEmpty ? store.user.email : store.user.name).prefix(1).uppercased())
                    .font(.system(.largeTitle, design: .serif, weight: .medium))
                    .foregroundStyle(Color.atfText1)
            }
            .accessibilityHidden(true)

            if !store.user.name.isEmpty {
            Text(store.user.name)
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)

            }
            Text(store.user.email)
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)
        }
        .padding(.vertical, 28)
    }

    // MARK: - Restaurant Card

    private var restaurantCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "fork.knife")
                .font(.title3)
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
        .background(Color.atfField, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Settings List

    private var settingsList: some View {
        VStack(spacing: 0) {
            // Compte
            if let onSwitchRestaurant {
                settingsRow(icon: "arrow.left.arrow.right", label: "Changer de restaurant", action: onSwitchRestaurant)
                ATFRowDivider().padding(.leading, 36)
            }
            settingsRow(icon: "safari", label: "Tableau de bord web", action: { openURL(AttablWeb.dashboard) })
            ATFRowDivider().padding(.leading, 36)
            settingsRow(icon: "ant", label: "Signaler un bug", action: reportBug)
            ATFRowDivider().padding(.leading, 36)
            settingsRow(icon: "info.circle", label: "Aide & support", action: { openURL(AttablWeb.support) })
            ATFRowDivider().padding(.leading, 36)
            settingsRow(icon: "doc.text", label: "Conditions d'utilisation", action: { openURL(AttablWeb.legal) })
            ATFRowDivider().padding(.leading, 36)
            settingsRow(icon: "hand.raised", label: "Politique de confidentialité", action: { openURL(AttablWeb.privacy) })
            ATFRowDivider().padding(.leading, 36)
            settingsRowInfo(icon: "number", label: "Version", value: appVersion)
        }
        .modifier(SettingsCard())
    }

    /// Destructive action, apart and in red (sign-out is the ordinary action).
    private var deletionCard: some View {
        settingsRow(icon: "person.crop.circle.badge.xmark",
                    label: store.isDeleting ? "Suppression en cours…" : "Supprimer mon compte",
                    tint: Color.atfDanger,
                    action: { confirmDeletion = true })
            .accessibilityIdentifier("deleteAccountRow")   // the confirmation button has the same label
            .disabled(store.isDeleting)
            .modifier(SettingsCard())
            .padding(.top, 16)
    }

    private func settingsRowInfo(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
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

    private func reportBug() {
        sendMail(subject: "Bug Atfood", body: "\n\n\nAtfood \(appVersion) · \(store.restaurant.name)")
    }

    private var deletionAlertShown: Binding<Bool> {
        Binding(
            get: { store.deletionError != nil || store.deletionOutcome.map { $0 != .deleted } == true },
            set: { if !$0 { store.deletionError = nil; store.deletionOutcome = nil } }
        )
    }

    private var deletionAlertTitle: String {
        if store.deletionError != nil { return "Suppression impossible" }
        switch store.deletionOutcome {
        case .soleOwner, .groupOwner: return "Supprimer aussi l'établissement ?"
        case .requested: return "Demande enregistrée"
        default: return "Compte non supprimé"
        }
    }

    private var deletionAlertMessage: String {
        if let error = store.deletionError { return error }
        switch store.deletionOutcome {
        case .soleOwner(let restaurant):
            return "Vous êtes le seul propriétaire de « \(restaurant) ». Supprimer votre compte ferme aussi cet établissement : sa carte en ligne, ses plats et ses photos seront supprimés. Votre demande est traitée sous 30 jours."
        case .groupOwner:
            return "Vous êtes le propriétaire de votre établissement sur À Table. Supprimer votre compte ferme aussi l'établissement : sa carte en ligne, ses plats et ses photos seront supprimés. Votre demande est traitée sous 30 jours."
        case .requested:
            return "Votre compte et votre établissement seront supprimés sous 30 jours. Une confirmation sera envoyée à \(store.user.email). Pour annuler la demande, écrivez à \(AttablWeb.supportEmail)."
        default:
            return "Ce compte est géré par l'équipe À Table. Contactez le support pour le supprimer."
        }
    }

    private func requestAccountDeletion() {
        sendMail(subject: "Suppression de compte Atfood",
                 body: "Bonjour,\n\nJe demande la suppression de mon compte \(store.user.email) et de mes données personnelles.\n\nMerci.")
    }

    /// Opens Mail; without a mail app, shows the address (openURL would otherwise fail silently).
    private func sendMail(subject: String, body: String) {
        openURL(AttablWeb.mail(subject: subject, body: body)) { accepted in
            if !accepted { mailFallback = true }
        }
    }

    private func settingsRow(icon: String, label: String, tint: Color? = nil,
                             action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(tint ?? Color.atfText2)
                .frame(width: 22)
            Text(label)
                .font(.body)
                .foregroundStyle(tint ?? Color.atfText1)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.atfText3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .tapOnly(label, action: action)   // the whole row answers a tap, never the end of a swipe
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        ATFButton(
            "Se déconnecter",
            kind: .secondary,
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

private struct SettingsCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.atfField, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("ProfileView") {
    let store = ProfileStore(user: AppUser.mock, restaurant: Restaurant.mocks[0])
    return ProfileView(store: store, networking: MockNetworking(),
                       onSignOut: {})
}
#endif
