import Testing
import CoreGraphics
@testable import Capture

private let centered = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)

@Test func goodTopDownShotHasNoHint() {
    #expect(GuidanceEngine.hint(pitch: 88, roll: 1, exposureOffset: 0, subject: centered, mode: .topDown) == nil)
}

@Test func noSubjectDoesNotNag() {
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: 0, subject: nil, mode: .angle45) == nil)
}

@Test func angleComesFirst() {
    // Everything wrong at once: angle must win.
    let h = GuidanceEngine.hint(pitch: 20, roll: 30, exposureOffset: -3, subject: .zero, mode: .topDown)
    #expect(h == .tiltDown)
    #expect(GuidanceEngine.hint(pitch: 70, roll: 0, exposureOffset: 0, subject: centered, mode: .angle45) == .tiltUp)
}

@Test func levelThenLightThenFraming() {
    #expect(GuidanceEngine.hint(pitch: 45, roll: 12, exposureOffset: -3, subject: centered, mode: .angle45) == .level)
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: -3, subject: centered, mode: .angle45) == .tooDark)
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: 2, subject: centered, mode: .angle45) == .tooBright)
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: 0, isoRatio: 0.8, subject: centered, mode: .angle45) == .tooDark)
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: 0, isoRatio: 0.2, subject: centered, mode: .angle45) == nil)
    let offCenter = CGRect(x: 0.6, y: 0.4, width: 0.3, height: 0.3)
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: 0, subject: offCenter, mode: .angle45) == .center)
    let tiny = CGRect(x: 0.45, y: 0.45, width: 0.1, height: 0.1)
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: 0, subject: tiny, mode: .angle45) == .moveCloser)
    let full = CGRect(x: 0, y: 0, width: 1, height: 1)
    #expect(GuidanceEngine.hint(pitch: 45, roll: 0, exposureOffset: 0, subject: full, mode: .angle45) == .moveBack)
}
