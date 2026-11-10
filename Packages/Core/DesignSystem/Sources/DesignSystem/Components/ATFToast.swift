// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToast.swift
import SwiftUI

public struct ATFToastData: Equatable, Sendable {
    public let message: String
    public let kind: Kind

    public enum Kind: Sendable { case success, warning, info }

    public init(_ message: String, kind: Kind = .success) {
        self.message = message
        self.kind = kind
    }
}

/// Overlay global: placer dans le ZStack racine.
public struct ATFToastOverlay: View {
    let toast: ATFToastData?

    public init(toast: ATFToastData?) {
        self.toast = toast
    }

    public var body: some View {
        if let toast {
            HStack(spacing: 10) {
                Circle()
                    .fill(toast.kind == .success ? Color.atfSuccess : Color.atfWarning)
                    .frame(width: 6, height: 6)
                Text(toast.message)
                    .font(.atfSubhead.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.atfText1)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview("ATFToast") {
    ZStack(alignment: .top) {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ATFToastOverlay(toast: ATFToastData("Plat publié sur la carte ✓"))
            .padding(.top, 64)
    }
}
