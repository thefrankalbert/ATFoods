// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFButton.swift
import SwiftUI

public enum ATFButtonKind {
    case primary, outline, ghost, secondary, danger
}

public struct ATFButton: View {
    let label: String
    let kind: ATFButtonKind
    let isFullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let icon: ATFIcon?
    let iconRight: ATFIcon?
    let action: @MainActor () -> Void

    public init(
        _ label: String,
        kind: ATFButtonKind = .primary,
        fullWidth: Bool = false,
        loading: Bool = false,
        disabled: Bool = false,
        icon: ATFIcon? = nil,
        iconRight: ATFIcon? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.label = label
        self.kind = kind
        self.isFullWidth = fullWidth
        self.isLoading = loading
        self.isDisabled = disabled
        self.icon = icon
        self.iconRight = iconRight
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                } else if let icon {
                    ATFIconView(icon, size: 18, color: foregroundColor)
                }
                Text(label)
                    .font(kind == .secondary ? .atfSubhead.weight(.medium) : .atfBodyStr)
                if let iconRight {
                    ATFIconView(iconRight, size: 18, color: foregroundColor)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: kind == .secondary ? 48 : 56)
            .padding(.horizontal, kind == .secondary ? 20 : 24)
            .background(background)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: kind == .outline ? 1.5 : 0)
            )
        }
        .opacity(isDisabled || isLoading ? 0.5 : 1)
        .disabled(isDisabled || isLoading)
        .buttonStyle(ATFScaleButtonStyle())
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .primary:  return AnyShapeStyle(Color.atfAccent)
        case .danger:   return AnyShapeStyle(Color.atfDanger)
        case .secondary: return AnyShapeStyle(Color.atfSurface)
        case .outline, .ghost: return AnyShapeStyle(Color.clear)
        }
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary, .danger: return .white
        case .outline, .ghost:  return .atfAccent
        case .secondary:        return .atfText1
        }
    }

    private var borderColor: Color {
        kind == .outline ? .atfAccent : .clear
    }
}

// Scale press animation — matches prototype `.atf-btn:active { transform: scale(.96) }`
public struct ATFScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

#Preview("ATFButton variants") {
    VStack(spacing: 12) {
        ATFButton("Se connecter", kind: .primary, fullWidth: true) {}
        ATFButton("Découvrir", kind: .outline, fullWidth: true) {}
        ATFButton("Annuler", kind: .ghost) {}
        ATFButton("Shoot rapide", kind: .secondary, icon: .scan) {}
        ATFButton("Supprimer", kind: .danger, fullWidth: true) {}
        ATFButton("Chargement…", kind: .primary, fullWidth: true, loading: true) {}
        ATFButton("Désactivé", kind: .primary, fullWidth: true, disabled: true) {}
    }
    .padding()
}
