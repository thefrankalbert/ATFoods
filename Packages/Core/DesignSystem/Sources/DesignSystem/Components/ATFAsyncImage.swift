// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFAsyncImage.swift
import SwiftUI

/// Image asynchrone avec fallback couleur + vignette overlay optionnelle.
public struct ATFAsyncImage: View {
    let url: URL?
    let fallbackColor: Color
    let radius: CGFloat
    let height: CGFloat
    let width: CGFloat?
    let showOverlay: Bool
    let contentMode: ContentMode

    public init(
        url: URL?,
        fallback: Color = Color(hex: "1A1410"),
        radius: CGFloat = 14,
        height: CGFloat = 120,
        width: CGFloat? = nil,
        overlay: Bool = true,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.fallbackColor = fallback
        self.radius = radius
        self.height = height
        self.width = width
        self.showOverlay = overlay
        self.contentMode = contentMode
    }

    public var body: some View {
        ZStack {
            fallbackColor

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        EmptyView()
                    case .empty:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            if showOverlay {
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.08), location: 0),
                        .init(color: .clear, location: 0.35),
                        .init(color: .clear, location: 0.55),
                        .init(color: .black.opacity(0.28), location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
#Preview("ATFAsyncImage") {
    VStack(spacing: 12) {
        ATFAsyncImage(url: nil, fallback: Color(hex: "C9551E"), radius: 14, height: 160)
        ATFAsyncImage(
            url: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&q=80&w=640&h=800"),
            fallback: Color(hex: "C9551E"),
            radius: 14,
            height: 200
        )
    }
    .padding()
}
#endif
