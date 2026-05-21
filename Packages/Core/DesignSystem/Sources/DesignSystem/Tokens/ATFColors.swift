// Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFColors.swift
import SwiftUI

extension Color {
    @usableFromInline
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - ATF Design Tokens

public extension Color {
    // Accent
    static let atfAccent      = Color(hex: "F97316")
    static let atfAccentHover = Color(hex: "EA6E0A")
    static let atfAccentMuted = Color(hex: "F97316").opacity(0.12)
    static let atfAccentOn    = Color.white

    // Surfaces — light (default)
    static let atfBg          = Color(hex: "FFFFFF")
    static let atfSurface     = Color(hex: "F7F7F7")
    static let atfSurface2    = Color(hex: "EFEFEF")
    static let atfBorder      = Color.black.opacity(0.08)
    static let atfBorderStr   = Color.black.opacity(0.14)
    static let atfText1       = Color(hex: "0A0A0A")
    static let atfText2       = Color(hex: "535353")
    static let atfText3       = Color(hex: "9A9A9A")
    static let atfOverlay     = Color.black.opacity(0.32)

    // Semantic
    static let atfSuccess     = Color(hex: "16A34A")
    static let atfSuccessBg   = Color(hex: "16A34A").opacity(0.12)
    static let atfWarning     = Color(hex: "EAB308")
    static let atfWarningBg   = Color(hex: "EAB308").opacity(0.14)
    static let atfDanger      = Color(hex: "DC2626")
    static let atfDangerBg    = Color(hex: "DC2626").opacity(0.12)
}

// MARK: - Dark mode adaptive tokens

public extension Color {
    // UIKit-backed dynamic color — resolves correctly on device and in UIHostingController.
    // In pure SwiftUI Previews using .preferredColorScheme(), use colorScheme env var directly.
    static func atfAdaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    // Dark surface tokens
    static let atfBgDark       = Color(hex: "0E0E0E")
    static let atfSurfaceDark  = Color(hex: "1A1A1A")
    static let atfSurface2Dark = Color(hex: "252525")
    static let atfText1Dark    = Color(hex: "FAFAFA")
    static let atfText2Dark    = Color(hex: "A1A1A1")
    static let atfText3Dark    = Color(hex: "6B6B6B")
}
