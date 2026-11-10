// Packages/Features/Auth/Sources/Auth/OnboardingView.swift
import SwiftUI
import DesignSystem

// MARK: - Data model

private struct OnboardingSlide {
    let id: Int
    let imageName: String   // bundled: onboarding works offline
    let tag: String
    let title: String
    let titleItalic: String
    let body: String
}

// Photos: Unsplash License (free commercial use, no attribution required), cropped to 1320x2868.
// 1: Keesha's Kitchen (unsplash.com/photos/b4Ht8TQ1JGo) · 2: VK bro (al9eh9QkdPA) · 3: Victoria Shes (UC0HZdUitWY)
private let slides: [OnboardingSlide] = [
    OnboardingSlide(id: 0,
        imageName: "onboarding-1",
        tag: "Pour les restaurateurs",
        title: "Publiez vos plats",
        titleItalic: "en 2 gestes.",
        body: "Une photo, un nom, un prix : votre carte en ligne en moins d'une minute."),
    OnboardingSlide(id: 1,
        imageName: "onboarding-2",
        tag: "Photo guidée",
        title: "Photographiez",
        titleItalic: "comme un pro.",
        body: "L'appli vous guide : angle, lumière, cadrage."),
    OnboardingSlide(id: 2,
        imageName: "onboarding-3",
        tag: "Carte numérique",
        title: "Votre menu,",
        titleItalic: "toujours à jour.",
        body: "Changez un prix ou marquez un plat épuisé en un geste, en temps réel."),
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
                Group {
                    if let path = Bundle.module.path(forResource: slides[currentIndex].imageName, ofType: "jpg"),
                       let image = UIImage(contentsOfFile: path) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Color(red: 0.102, green: 0.059, blue: 0.039)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .accessibilityHidden(true)
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
                    // Tall, dark scrim: the text sits on busy food photos and must stay readable.
                    LinearGradient(colors: [.clear, .black.opacity(0.65), .black.opacity(0.92)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 520)
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
        // Swipe between slides, like any onboarding.
        .gesture(DragGesture(minimumDistance: 30).onEnded { value in
            if value.translation.width < -50 { advanceSlide() }
            else if value.translation.width > 50, currentIndex > 0 {
                withAnimation(.easeInOut(duration: 0.3)) { currentIndex -= 1 }
            }
        })
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
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())

            // Title with italic accent (system serif: New York)
            Group {
                Text(slides[currentIndex].title + " ")
                    .font(.system(size: 38, weight: .medium, design: .serif))
                + Text(slides[currentIndex].titleItalic)
                    .font(.system(size: 38, weight: .medium, design: .serif).italic())
                    .foregroundColor(Color.white.opacity(0.75))
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
            .foregroundStyle(Color.atfText1)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.atfBg)   // Ivory on the dark photo: Slate would disappear
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

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("OnboardingView") {
    OnboardingView {}
}
#endif
