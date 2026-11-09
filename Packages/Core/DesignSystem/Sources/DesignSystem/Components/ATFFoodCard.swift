// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFFoodCard.swift
import SwiftUI

/// Food item card: photo on top, name and price below (fills its grid column). Takes raw values — no dependency on Models.
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
            VStack(alignment: .leading, spacing: 8) {
                // Fixed-size box + overlay: a scaledToFill photo can never widen the grid column.
                Color.atfSurface2
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .overlay {
                        if photoURL != nil {
                            ATFAsyncImage(url: photoURL, fallback: Color.atfSurface2,
                                          radius: 0, height: 130, overlay: false)
                                .opacity(isAvailable ? 1 : 0.45)
                        } else {
                            // The app's job is photos: dishes without one stand out.
                            VStack(spacing: 6) {
                                Image(systemName: "camera.fill").font(.title3)
                                Text("Ajouter une photo").font(.atfCaption)
                            }
                            .foregroundStyle(Color.atfAccent)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if !isAvailable { ATFBadge("Épuisé", kind: .soft).padding(8) }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.atfBody)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.atfText1)
                        .lineLimit(1)
                    Text(priceFormatted)
                        .font(.atfCaption)
                        .monospacedDigit()
                        .foregroundStyle(isAvailable ? Color.atfText2 : Color.atfText3)
                        .lineLimit(1)
                }
                .padding(.horizontal, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
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
