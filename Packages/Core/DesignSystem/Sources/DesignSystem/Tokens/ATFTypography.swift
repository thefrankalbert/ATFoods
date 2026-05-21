// Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFTypography.swift
import SwiftUI

public extension Font {
    // Display — Instrument Serif
    static let atfDisplay: Font = .custom("InstrumentSerif-Regular", size: 34)
    static let atfDisplaySm: Font = .custom("InstrumentSerif-Regular", size: 28)
    static let atfTitle: Font = .custom("InstrumentSerif-Regular", size: 24)
    static let atfDisplayItalic: Font = .custom("InstrumentSerif-Italic", size: 34)
    static let atfDisplaySmItalic: Font = .custom("InstrumentSerif-Italic", size: 28)

    // System — Inter via -apple-system
    static let atfHeadline  = Font.system(size: 20, weight: .semibold)
    static let atfBody      = Font.system(size: 17, weight: .regular)
    static let atfBodyStr   = Font.system(size: 17, weight: .semibold)
    static let atfSubhead   = Font.system(size: 15, weight: .regular)
    static let atfCaption   = Font.system(size: 13, weight: .medium)
    static let atfOverline  = Font.system(size: 11, weight: .semibold)
    static let atfMono      = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// Convenience modifier for overline style (uppercase + tracking)
@MainActor
public struct ATFOverlineModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .font(.atfOverline)
            .textCase(.uppercase)
            .tracking(1.0)
            .foregroundStyle(Color.atfText3)
    }
}

public extension View {
    func atfOverlineStyle() -> some View {
        modifier(ATFOverlineModifier())
    }
}
