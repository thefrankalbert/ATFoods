import AuthenticationServices
import CryptoKit
import SwiftUI
import DesignSystem
import Networking

public struct LoginView: View {
    @Bindable var store: AuthStore
    let networking: any ATFNetworking
    @Environment(\.openURL) private var openURL
    let onSuccess: () -> Void
    /// Raw nonce of the Apple request in flight: Supabase checks it against the hash inside Apple's token.
    @State private var appleNonce = ""

    /// Sign in with Apple needs the paid Apple Developer Program (entitlement) and the Apple provider on Supabase.
    /// Project.swift turns both the entitlement and this flag on together.
    private let appleSignInEnabled = Bundle.main.object(forInfoDictionaryKey: "ATFSignInWithApple") as? Bool == true

    public init(store: AuthStore, networking: any ATFNetworking, onSuccess: @escaping () -> Void) {
        self.store = store
        self.networking = networking
        self.onSuccess = onSuccess
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                // App icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.atfAccent)
                        .frame(width: 72, height: 72)
                    ATFIconView(.fork, size: 32, color: .atfAccentOn)
                }

                Spacer().frame(height: 20)

                ATFWordmark(size: 32)

                Text("Vos plats, en deux gestes.")
                    .font(.atfSubhead)
                    .foregroundStyle(Color.atfText3)
                    .padding(.top, 6)

                Spacer().frame(height: 48)

                VStack(spacing: 16) {
                    ATFTextField("Adresse e-mail", text: $store.email,
                                 placeholder: "vous@restaurant.com",
                                 rightIcon: .user)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    ATFTextField("Mot de passe", text: $store.password,
                                 placeholder: "••••••••",
                                 secure: true)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit(signIn)

                    if let error = store.error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.atfCaption)
                            .foregroundStyle(Color.atfDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Spacer()
                        // The web flow handles the reset email and the new-password page.
                        Button { openURL(AttablWeb.forgotPassword) } label: {
                            Text("Mot de passe oublié ?")
                                .font(.atfSubhead)
                                .foregroundStyle(Color.atfText1)
                                .underline()
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                    }

                    ATFButton("Se connecter", kind: .primary, fullWidth: true,
                              loading: store.pending == .password, disabled: !store.canSubmit || store.isLoading,
                              action: signIn)

                    HStack(spacing: 12) {
                        Rectangle().fill(Color.atfBorder).frame(height: 1)
                        Text("ou").font(.atfCaption).foregroundStyle(Color.atfText3)
                        Rectangle().fill(Color.atfBorder).frame(height: 1)
                    }
                    .accessibilityHidden(true)

                    ATFButton("Continuer avec Google", kind: .outline, fullWidth: true,
                              loading: store.pending == .google, disabled: store.isLoading, action: signInWithGoogle)
                        .accessibilityIdentifier("googleSignIn")

                    if appleSignInEnabled {
                        SignInWithAppleButton(.continue, onRequest: prepareApple, onCompletion: finishApple)
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 52)
                            .clipShape(Capsule())
                            .disabled(store.isLoading)
                            .accessibilityIdentifier("appleSignIn")
                    }
                }

                Spacer().frame(height: 32)

                Text("Votre compte se crée depuis le tableau de bord À Table de votre restaurant.")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText3)
                    .multilineTextAlignment(.center)

                // Legal links reachable before sign-in (App Store guideline 5.1.1).
                HStack(spacing: 20) {
                    legalLink("Conditions d'utilisation", AttablWeb.legal)
                    legalLink("Confidentialité", AttablWeb.privacy)
                }

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        // Opaque status bar area: with the keyboard up, the logo scrolled under the clock.
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.atfBg.frame(height: 0).background(Color.atfBg.ignoresSafeArea(edges: .top))
        }
        .background(Color.atfBg.ignoresSafeArea())
    }

    private func signIn() {
        guard store.canSubmit, !store.isLoading else { return }
        Task {
            await store.signIn(networking: networking)
            if store.currentUser != nil { onSuccess() }
        }
    }

    private func signInWithGoogle() {
        Task {
            await store.signInWithGoogle(networking: networking)
            if store.currentUser != nil { onSuccess() }
        }
    }

    private func prepareApple(_ request: ASAuthorizationAppleIDRequest) {
        appleNonce = UUID().uuidString + UUID().uuidString
        request.requestedScopes = [.fullName, .email]
        request.nonce = SHA256.hash(data: Data(appleNonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func finishApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let token = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
                store.error = "Connexion avec Apple impossible. Réessayez."
                return
            }
            let nonce = appleNonce
            Task {
                await store.signInWithApple(idToken: token, nonce: nonce, networking: networking)
                if store.currentUser != nil { onSuccess() }
            }
        case .failure(let error):
            // Closing the Apple sheet is a choice, not an error.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            store.error = "Connexion avec Apple impossible. Réessayez."
        }
    }

    private func legalLink(_ title: String, _ url: URL) -> some View {
        Button { openURL(url) } label: {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color.atfText2)
                .underline()
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
#Preview("LoginView") {
    LoginView(store: AuthStore(), networking: MockNetworking()) {}
}
#endif
