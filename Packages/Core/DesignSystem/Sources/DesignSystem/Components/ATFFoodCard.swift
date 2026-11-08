// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFFoodCard.swift
import SwiftUI

/// Food item card (fills its grid column, 170pt high). Takes raw values — no dependency on Models.
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
        onTap: @escaping () -> Void
    ) {
        self.name = name; self.priceFormatted = priceFormatted
        self.photoURL = photoURL; self.isAvailable = isAvailable; self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Fixed-size box + overlay: a scaledToFill photo can never widen the grid column.
                Color(hex: "1A1410")
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .overlay {
                        ATFAsyncImage(url: photoURL,
                                      fallback: Color(hex: "1A1410"),
                                      radius: 0,
                                      height: 170,
                                      overlay: false)
                    }
                    .clipped()

                if photoURL == nil {
                    // The app's job is photos: dishes without one stand out.
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Sans photo")
                            .font(.atfCaption)
                    }
                    .foregroundStyle(Color.atfAccent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 36)
                }

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
                            ATFBadge("Épuisé", kind: .soft).padding(8)
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
                        .font(.system(.caption, design: .monospaced, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ATFScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([name, priceFormatted, photoURL == nil ? "sans photo" : nil, isAvailable ? nil : "épuisé"]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("ATFFoodCard") {
    HStack(spacing: 12) {
        ATFFoodCard(
            name: "Mafé bœuf", priceFormatted: "3 800 FCFA",
            photoURL: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400"),
            onTap: {}
        )
        ATFFoodCard(name: "Thieboudienne", priceFormatted: "4 500 FCFA", isAvailable: false, onTap: {})
        ATFFoodCard(name: "Ndolé", priceFormatted: "4 200 FCFA", onTap: {})
    }
    .padding()
    .background(Color.atfSurface)
}
