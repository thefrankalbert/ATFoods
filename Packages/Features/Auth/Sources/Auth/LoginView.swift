import SwiftUI
import DesignSystem
import Networking

public struct LoginView: View {
    @Bindable var store: AuthStore
    let networking: any ATFNetworking
    @Environment(\.openURL) private var openURL
    let onSuccess: () -> Void

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
                        .shadow(color: Color.atfAccent.opacity(0.45), radius: 16, y: 6)
                    ATFIconView(.fork, size: 32, color: .white)
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
                                 placeholder: "mariam@chezflora.cm",
                                 rightIcon: .user)

                    ATFTextField("Mot de passe", text: $store.password,
                                 placeholder: "••••••••",
                                 error: store.error,
                                 secure: true)

                    HStack {
                        Spacer()
                        // Web flow already handles the reset email + new password page.
                        Button("Mot de passe oublié ?") { openURL(URL(string: "https://attabl.com/forgot-password")!) }
                            .font(.atfSubhead)
                            .foregroundStyle(Color.atfAccent)
                    }

                    ATFButton("Se connecter", kind: .primary, fullWidth: true,
                              loading: store.isLoading) {
                        Task {
                            await store.signIn(networking: networking)
                            if store.currentUser != nil { onSuccess() }
                        }
                    }
                }

                Spacer().frame(height: 32)

                HStack(spacing: 4) {
                    Text("Pas encore À Table ?")
                        .font(.atfSubhead)
                        .foregroundStyle(Color.atfText3)
                    Button("Découvrir") { openURL(URL(string: "https://attabl.com")!) }
                        .font(.atfSubhead.weight(.semibold))
                        .foregroundStyle(Color.atfAccent)
                }

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.atfBg.ignoresSafeArea())
    }
}

#Preview("LoginView") {
    LoginView(store: AuthStore(), networking: MockNetworking()) {}
}
