// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFCard.swift
import SwiftUI

public struct ATFCard<Content: View>: View {
    let isElevated: Bool
    let content: @MainActor () -> Content

    public init(elevated: Bool = false, @ViewBuilder content: @escaping @MainActor () -> Content) {
        self.isElevated = elevated
        self.content = content
    }

    public var body: some View {
        content()
            .background(isElevated ? Color.atfBg : Color.atfSurface)
            .clipShape(RoundedRectangle(cornerRadius: ATFRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: ATFRadius.card)
                    .strokeBorder(Color.atfBorder, lineWidth: 1)
            )
            .shadow(
                color: isElevated ? Color.black.opacity(0.04) : .clear,
                radius: 7, x: 0, y: 2
            )
    }
}

#Preview("ATFCard") {
    VStack(spacing: 12) {
        ATFCard {
            Text("Surface card").padding()
        }
        ATFCard(elevated: true) {
            Text("Elevated card").padding()
        }
    }
    .padding()
}
