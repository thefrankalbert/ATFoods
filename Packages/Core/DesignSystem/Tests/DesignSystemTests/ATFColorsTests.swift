// Packages/Core/DesignSystem/Tests/DesignSystemTests/ATFColorsTests.swift
import Testing
import SwiftUI
@testable import DesignSystem

@Suite("ATFColors")
struct ATFColorsTests {
    @Test("hex initializer parses F97316 to orange")
    func hexParserOrange() {
        let c = Color(hex: "F97316")
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 0.976) < 0.01)
        #expect(abs(g - 0.451) < 0.01)
        #expect(abs(b - 0.086) < 0.01)
    }

    @Test("atfAccent is non-clear")
    func accentNonClear() {
        let ui = UIColor(Color.atfAccent)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(a - 1.0) < 0.001)
    }
}
