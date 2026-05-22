// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFFoodCard.swift
import SwiftUI

/// Food item card 148×170pt for horizontal lists.
/// Takes raw values — no dependency on Models package.
public struct ATFFoodCard: View {
    let name: String
    let priceFormatted: String
    let photoURL: URL?
    let isAvailable: Bool
    let onTap: () -> Void

    public init(
        name: String,
        priceFormatted: String,
        photoURL: URL? = nil,
        isAvailable: Bool = true,
        onTap: @escaping () -> Void = {}
    ) {
        self.name = name; self.priceFormatted = priceFormatted
        self.photoURL = photoURL; self.isAvailable = isAvailable; self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                ATFAsyncImage(url: photoURL,
                              fallback: Color(hex: "1A1410"),
                              radius: 12,
                              height: 170,
                              width: 148)

                // Gradient for text legibility
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.6)],
                    startPoint: .center, endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !isAvailable {
                    VStack {
                        HStack {
                            Spacer()
                            ATFBadge("Indispo", kind: .soft).padding(8)
                        }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.atfCaption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(priceFormatted)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .padding(10)
            }
            .frame(width: 148, height: 170)
        }
        .buttonStyle(ATFScaleButtonStyle())
    }
}

#Preview("ATFFoodCard") {
    HStack(spacing: 12) {
        ATFFoodCard(
            name: "Mafé bœuf", priceFormatted: "3 800 FCFA",
            photoURL: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400")
        )
        ATFFoodCard(name: "Thieboudienne", priceFormatted: "4 500 FCFA", isAvailable: false)
        ATFFoodCard(name: "Ndolé", priceFormatted: "4 200 FCFA")
    }
    .padding()
    .background(Color.atfSurface)
}
