// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFChip.swift
import SwiftUI

public enum ATFChipKind { case `default`, add }

public struct ATFChip: View {
    let label: String
    let icon: ATFIcon?
    let isSelected: Bool
    let kind: ATFChipKind
    let isTap: Bool
    let action: @MainActor () -> Void

    public init(
        _ label: String,
        icon: ATFIcon? = nil,
        selected: Bool = false,
        kind: ATFChipKind = .default,
        tap: Bool = false,
        action: @escaping @MainActor () -> Void = {}
    ) {
        self.label = label
        self.icon = icon
        self.isSelected = selected
        self.kind = kind
        self.isTap = tap
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    ATFIconView(icon, size: 14,
                                color: isSelected ? .atfAccentOn : .atfText1)
                }
                Text(label)
                    .font(.subheadline)
            }
            .padding(.horizontal, isTap ? 12 : 14)
            .frame(height: isTap ? 32 : 36)
            .background(chipBackground)
            .foregroundStyle(chipForeground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(chipBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ATFScaleButtonStyle())
        .frame(minHeight: 44)   // hit area even when the chip is drawn smaller
        .fixedSize()
    }

    private var chipBackground: Color {
        if isSelected { return .atfAccent }
        if kind == .add { return .clear }
        return .atfSurface2
    }

    private var chipForeground: Color {
        isSelected ? .atfAccentOn : .atfText1
    }

    private var chipBorder: Color {
        kind == .add && !isSelected ? .atfBorderStr : .clear
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
#Preview("ATFChip") {
    @Previewable @State var sel = "plat"
    let cats = ["Entrée", "Plat", "Grillades", "Spécialité"]

    ScrollView(.horizontal) {
        HStack(spacing: 8) {
            ATFChip("Sans photo · 3", icon: .cameraSlash, selected: true) {}
            ForEach(cats, id: \.self) { c in
                ATFChip(c, selected: sel == c.lowercased()) { sel = c.lowercased() }
            }
            ATFChip("Créer", icon: .plus, kind: .add) {}
        }
        .padding()
    }
}
#endif
