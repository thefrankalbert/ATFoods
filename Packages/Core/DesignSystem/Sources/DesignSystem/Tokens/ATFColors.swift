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
    // Palette from the Claude color system (Ivory, Slate, warm greys): actions are Slate, no coloured buttons.
    static let atfAccent      = Color(hex: "141413")   // Slate: primary buttons, selection, toggles
    static let atfAccentHover = Color(hex: "30302E")
    static let atfAccentMuted = Color(hex: "F0EEE6")   // secondary button / soft fill
    static let atfAccentOn    = Color(hex: "FAF9F5")
    static let atfClay        = Color(hex: "D97757")   // Claude accent: tiny indicators only (badge dot)

    // Surfaces (light only: Info.plist pins the light appearance)
    static let atfBg          = Color(hex: "FAF9F5")   // Ivory
    static let atfSurface     = Color(hex: "F5F4ED")
    static let atfField       = Color.white            // text fields and grouped rows on Ivory
    static let atfSurface2    = Color(hex: "F0EEE6")
    static let atfBorder      = Color(hex: "1F1E1D").opacity(0.15)
    static let atfBorderStr   = Color(hex: "1F1E1D").opacity(0.30)
    static let atfText1       = Color(hex: "141413")
    static let atfText2       = Color(hex: "5E5D59")
    static let atfText3       = Color(hex: "73726C")
    static let atfOverlay     = Color.black.opacity(0.32)

    // Semantic
    static let atfSuccess     = Color(hex: "4A7A39")
    static let atfSuccessBg   = Color(hex: "4A7A39").opacity(0.12)
    static let atfWarning     = Color(hex: "C9A82D")
    static let atfWarningBg   = Color(hex: "C9A82D").opacity(0.14)
    static let atfDanger      = Color(hex: "B3261E")
    static let atfDangerBg    = Color(hex: "B3261E").opacity(0.10)
}
