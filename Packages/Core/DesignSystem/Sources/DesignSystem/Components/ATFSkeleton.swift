// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSkeleton.swift
import SwiftUI

public struct ATFSkeleton: View {
    let width: CGFloat?
    let height: CGFloat
    let radius: CGFloat
    @State private var phase: CGFloat = 0

    public init(width: CGFloat? = nil, height: CGFloat = 20, radius: CGFloat = 8) {
        self.width = width; self.height = height; self.radius = radius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.atfSurface2)
            .overlay(shimmer)
            .clipped()
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }

    private var shimmer: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.45), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.55)
            .offset(x: phase * (geo.size.width + geo.size.width * 0.55) - geo.size.width * 0.55)
        }
    }
}

#Preview("ATFSkeleton") {
    VStack(alignment: .leading, spacing: 12) {
        ATFSkeleton(width: 148, height: 170, radius: 12)
        ATFSkeleton(height: 52)
        ATFSkeleton(width: 160, height: 16)
    }
    .padding()
}
