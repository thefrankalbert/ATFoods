// Packages/Core/DesignSystem/Sources/DesignSystem/Wordmark/ATFWordmark.swift
import SwiftUI

/// Logo "Atfood" avec point orange.
/// Usage: ATFWordmark(size: 22)  |  ATFWordmark(size: 18, color: .white)
public struct ATFWordmark: View {
    let size: CGFloat
    let color: Color
    let showDot: Bool

    public init(size: CGFloat = 22, color: Color = .atfText1, showDot: Bool = true) {
        self.size = size
        self.color = color
        self.showDot = showDot
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("At")
                .font(.system(size: size, weight: .medium, design: .serif))
                .foregroundStyle(color)
            Text("food")
                .font(.system(size: size * 0.95, weight: .medium, design: .serif).italic())
                .foregroundStyle(color)
            if showDot {
                Circle()
                    .fill(Color.atfClay)
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(y: -size * 0.12)
                    .padding(.leading, 2)
            }
        }
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
#Preview("ATFWordmark") {
    VStack(spacing: 24) {
        ATFWordmark(size: 32)
        ATFWordmark(size: 22)
        ATFWordmark(size: 18, color: .white)
            .padding()
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}
#endif
