import SwiftUI
import DesignSystem
import Models
import Networking

public struct AIRetouchView: View {
    @Bindable var store: AIRetouchStore
    let networking: any ATFNetworking
    let onSelectBackground: () -> Void
    let onBack: () -> Void
    let onUpgrade: () -> Void

    @State private var sliderPos: CGFloat = 0.5

    public init(
        store: AIRetouchStore,
        networking: any ATFNetworking,
        onSelectBackground: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onUpgrade: @escaping () -> Void
    ) {
        self.store = store; self.networking = networking
        self.onSelectBackground = onSelectBackground
        self.onBack = onBack; self.onUpgrade = onUpgrade
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            comparisonView
            creditsRow
            Divider()
            toolsSection
            Spacer(minLength: 0)
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
            Text("Retouche IA")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)
            Spacer()
            Color.clear.frame(width: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 14)
    }

    // MARK: - Before/After Comparison

    private var comparisonView: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                originalLayer(width: geo.size.width)
                retouchedLayer(width: geo.size.width)
                dividerLine(width: geo.size.width)
                sliderHandle(width: geo.size.width)
                if store.isProcessing { processingOverlay }
                labels(width: geo.size.width)
            }
        }
        .frame(height: 280)
        .clipped()
    }

    private func originalLayer(width: CGFloat) -> some View {
        ATFAsyncImage(
            url: store.originalURL,
            fallback: Color.atfSurface2,
            radius: 0, height: 280, overlay: false, contentMode: .fill
        )
        .frame(width: width, height: 280)
        .clipped()
    }

    private func retouchedLayer(width: CGFloat) -> some View {
        ATFAsyncImage(
            url: store.retouchedURL,
            fallback: Color.atfAccent.opacity(0.15),
            radius: 0, height: 280, overlay: false, contentMode: .fill
        )
        .frame(width: width, height: 280)
        .clipped()
        .mask(
            HStack(spacing: 0) {
                Color.clear.frame(width: width * sliderPos)
                Color.black.frame(maxWidth: .infinity)
            }
            .frame(width: width, height: 280)
        )
    }

    private func dividerLine(width: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 2, height: 280)
            .offset(x: width * sliderPos - 1)
    }

    private func sliderHandle(width: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.atfText1)
            )
            .shadow(color: .black.opacity(0.25), radius: 4)
            .offset(x: width * sliderPos - 18, y: 280 / 2 - 18)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        sliderPos = max(0.05, min(0.95, value.location.x / width))
                    }
            )
    }

    private var processingOverlay: some View {
        Color.black.opacity(0.45)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Text("Traitement en cours…")
                        .font(.atfCaption)
                        .foregroundStyle(.white)
                }
            )
    }

    private func labels(width: CGFloat) -> some View {
        VStack {
            HStack {
                Text("Avant")
                    .font(.atfOverline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(8)
                Spacer()
                Text("Après")
                    .font(.atfOverline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(8)
            }
            Spacer()
        }
    }

    // MARK: - Credits Row

    private var creditsRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.atfAccent)
            Text("\(store.creditsBalance) crédit\(store.creditsBalance > 1 ? "s" : "") disponible\(store.creditsBalance > 1 ? "s" : "")")
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)
            Spacer()
            if store.creditsBalance < 3 {
                Button(action: onUpgrade) {
                    Text("Obtenir plus →")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfAccent)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.atfSurface)
    }

    // MARK: - Tools

    private var toolsSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                toolCard(
                    title: "Supprimer fond",
                    subtitle: "Supprime l'arrière-plan du plat",
                    credits: 1,
                    icon: "wand.and.rays",
                    disabled: store.creditsBalance < 1 || store.isProcessing
                ) {
                    Task { await store.removeBackground(networking: networking) }
                }

                toolCard(
                    title: "Changer fond",
                    subtitle: "Choisissez parmi nos arrière-plans",
                    credits: 2,
                    icon: "photo.fill.on.rectangle.fill",
                    disabled: store.creditsBalance < 2 || store.isProcessing,
                    buttonLabel: "Choisir"
                ) {
                    onSelectBackground()
                }
            }
            .padding(16)
        }
    }

    private func toolCard(
        title: String,
        subtitle: String,
        credits: Int,
        icon: String,
        disabled: Bool,
        buttonLabel: String = "Appliquer",
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.atfAccent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.atfBodyStr)
                        .foregroundStyle(Color.atfText1)
                    Text(subtitle)
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText2)
                }
                Spacer()
                ATFBadge("\(credits) crédit\(credits > 1 ? "s" : "")", kind: disabled ? .soft : .pending)
            }
            ATFButton(buttonLabel, kind: .outline, fullWidth: true, disabled: disabled, action: action)
        }
        .padding(16)
        .background(Color.atfSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.atfBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("AIRetouchView") {
    let store = AIRetouchStore(
        dishID: UUID(),
        originalURL: URL(string: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600"),
        creditsBalance: 5
    )
    return AIRetouchView(store: store, networking: MockNetworking(),
                         onSelectBackground: {}, onBack: {}, onUpgrade: {})
}
