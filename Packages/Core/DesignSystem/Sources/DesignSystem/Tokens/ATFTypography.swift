// Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFTypography.swift
import SwiftUI

// MARK: - Font tokens

public extension Font {
    // System fonts only: New York (serif) for titles, SF Pro for the rest. All scale with Dynamic Type.
    static let atfTitle    = Font.system(.title2, design: .serif, weight: .medium)

    // System text styles (default sizes: title3 20, body 17, subheadline 15, footnote 13, caption2 11)
    static let atfHeadline = Font.system(.title3, weight: .semibold)
    static let atfBody     = Font.system(.body)
    static let atfBodyStr  = Font.system(.body, weight: .semibold)
    static let atfSubhead  = Font.system(.subheadline)
    static let atfCaption  = Font.system(.footnote, weight: .medium)
    static let atfOverline = Font.system(.caption2, weight: .semibold)
    static let atfMono     = Font.system(.subheadline, design: .monospaced, weight: .medium)
}
