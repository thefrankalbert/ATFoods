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
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(background)
        .foregroundStyle(foreground)
        .clipShape(Capsule())
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .pro:      return AnyShapeStyle(LinearGradient(colors: [Color(hex: "F5D76E"), Color(hex: "D4AF37")], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .pending:  return AnyShapeStyle(Color.atfWarningBg)
        case .attached: return AnyShapeStyle(Color.atfSuccessBg)
        case .danger:   return AnyShapeStyle(Color.atfDangerBg)
        case .soft:     return AnyShapeStyle(Color.atfSurface2)
        }
    }

    private var foreground: Color {
        switch kind {
        case .pro:      return Color(hex: "4A3500")
        case .pending:  return Color(hex: "92660A")
        case .attached: return .atfSuccess
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
