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
                .font(.custom("InstrumentSerif-Regular", size: size))
                .foregroundStyle(color)
            Text("food")
                .font(.custom("InstrumentSerif-Italic", size: size * 0.95))
                .foregroundStyle(color)
            if showDot {
                Circle()
                    .fill(Color.atfAccent)
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(y: -size * 0.12)
                    .padding(.leading, 2)
            }
        }
    }
}

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
