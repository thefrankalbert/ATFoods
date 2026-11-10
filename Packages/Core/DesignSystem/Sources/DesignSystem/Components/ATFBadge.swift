// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFBadge.swift
import SwiftUI

public enum ATFBadgeKind { case pro, pending, attached, danger, soft }

public struct ATFBadge: View {
    let label: String
    let kind: ATFBadgeKind
    let icon: ATFIcon?

    public init(_ label: String, kind: ATFBadgeKind = .soft, icon: ATFIcon? = nil) {
        self.label = label
        self.kind = kind
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                ATFIconView(icon, size: 10, color: foreground)
            }
            Text(label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(background)
        .foregroundStyle(foreground)
        .clipShape(Capsule())
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .pro:      return AnyShapeStyle(Color.atfAccent)
        case .pending, .attached: return AnyShapeStyle(Color.atfSurface2)
        case .danger:   return AnyShapeStyle(Color.atfDangerBg)
        case .soft:     return AnyShapeStyle(Color.atfSurface2)
        }
    }

    private var foreground: Color {
        switch kind {
        case .pro:      return .atfAccentOn
        case .pending, .attached: return .atfText1
        case .danger:   return .atfDanger
        case .soft:     return .atfText2
        }
    }
}

#Preview("ATFBadge") {
    HStack(spacing: 8) {
        ATFBadge("Pro", kind: .pro, icon: .star)
        ATFBadge("En attente", kind: .pending)
        ATFBadge("Rattaché", kind: .attached)
        ATFBadge("Erreur", kind: .danger)
        ATFBadge("Manager", kind: .soft)
    }
    .padding()
}
