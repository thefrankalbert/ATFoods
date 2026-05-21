// Packages/Core/DesignSystem/Sources/DesignSystem/FontRegistration.swift
import CoreText
import Foundation

/// Call once at app startup to register bundled Instrument Serif fonts with CoreText.
/// Required because fonts live in the SPM resource bundle, not the main app bundle.
public func registerDesignSystemFonts() {
    let fontNames = ["InstrumentSerif-Regular", "InstrumentSerif-Italic"]
    for name in fontNames {
        guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else { continue }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
