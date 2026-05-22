// Packages/Features/Auth/Sources/Auth/OnboardingView.swift
import SwiftUI
import DesignSystem

// MARK: - Data model

private struct OnboardingSlide {
    let id: Int
    let imageURL: URL?
    let tag: String
    let title: String
    let titleItalic: String
    let body: String
}

private let slides: [OnboardingSlide] = [
    OnboardingSlide(id: 0,
        imageURL: URL(string: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800"),
        tag: "Pour les restaurateurs",
        title: "Publiez vos plats",
        titleItalic: "en 2 gestes.",
        body: "Photo, nom, prix — votre carte en ligne en moins d'une minute."),
    OnboardingSlide(id: 1,
        imageURL: URL(string: "https://images.unsplash.com/photo-1547592180-85f173990554?w=800"),
        tag: "Shoot rapide",
        title: "Photographiez",
        titleItalic: "comme un pro.",
        body: "Notre cadrage automatique met vos plats en valeur."),
    OnboardingSlide(id: 2,
        imageURL: URL(string: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800"),
        tag: "Carte numérique",
        title: "Votre menu,",
        titleItalic: "toujours à jour.",
        body: "Activez ou désactivez un plat en un tap, en temps réel."),
]

// MARK: - Local scale button style (ATFScaleButtonStyle is internal to DesignSystem)

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - OnboardingView

public struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var currentIndex = 0
    @State private var kenBurnsScale: CGFloat = 1.0

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background photo + Ken Burns
                ATFAsyncImage(
                    url: slides[currentIndex].imageURL,
                    fallback: Color(red: 0.102, green: 0.059, blue: 0.039),
                    radius: 0,
                    height: geo.size.height,
                    width: geo.size.width,
                    overlay: false,
                    contentMode: .fill
                )
                .scaleEffect(kenBurnsScale)
                .animation(.linear(duration: 8).repeatForever(autoreverses: true), value: kenBurnsScale)
                .ignoresSafeArea()
                .id(currentIndex)
                .onAppear { kenBurnsScale = 1.08 }

                // Gradient overlays
                VStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(0.55), .clear],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 180)
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.8)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 360)
                }
                .ignoresSafeArea()

                // Content overlay
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    slideContent
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                ATFWordmark(size: 22, color: .white)
                Spacer()
                Button("Passer") { onFinish() }
                    .font(.atfSubhead)
                    .foregroundStyle(.white.opacity(0.75))
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Progress bar
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Slide content

    private var slideContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tag pill
            Text(slides[currentIndex].tag.uppercased())
                .font(.atfOverline)
                .tracking(1.0)
                .foregroundStyle(Color.atfAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())

            // Title with italic accent
            Group {
                Text(slides[currentIndex].title + " ")
                    .font(.custom("InstrumentSerif-Regular", size: 42))
                + Text(slides[currentIndex].titleItalic)
                    .font(.custom("InstrumentSerif-Italic", size: 42))
                    .foregroundColor(Color.atfAccent)
            }
            .foregroundStyle(.white)

            // Body
            Text(slides[currentIndex].body)
                .font(.system(size: 16))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineSpacing(4)

            Spacer().frame(height: 8)

            // Dots + CTA
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: i == currentIndex ? 8 : 6,
                                   height: i == currentIndex ? 8 : 6)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                Spacer()
                ctaButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
    }

    // MARK: - CTA button

    private var ctaButton: some View {
        Button {
            advanceSlide()
        } label: {
            HStack(spacing: 8) {
                Text(currentIndex < 2 ? "Continuer" : "Commencer")
                    .font(.atfBodyStr)
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.atfAccent)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Helpers

    private func advanceSlide() {
        if currentIndex < 2 {
            withAnimation(.easeInOut(duration: 0.3)) { currentIndex += 1 }
        } else {
            onFinish()
        }
    }
}

// MARK: - Preview

#Preview("OnboardingView") {
    OnboardingView {}
}
