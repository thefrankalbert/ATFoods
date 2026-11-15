import Foundation
import CoreGraphics
import CoreMotion
@preconcurrency import AVFoundation
import Observation

// MARK: - Mode & hints

public enum CaptureMode: String, CaseIterable, Sendable {
    case topDown = "Vue de dessus"
    case angle45 = "45°"

    /// Target camera tilt in degrees (90 = pointing straight down at the table).
    var targetPitch: Double { self == .topDown ? 90 : 45 }
    var pitchTolerance: Double { self == .topDown ? 8 : 10 }
}

public enum GuidanceHint: Equatable, Sendable {
    case tiltDown, tiltUp, level, tooDark, tooBright, center, moveCloser, moveBack

    public var message: String {
        switch self {
        case .tiltDown:   "Inclinez le téléphone vers le plat"
        case .tiltUp:     "Redressez un peu le téléphone"
        case .level:      "Tenez le téléphone bien droit"
        case .tooDark:    "Trop sombre : rapprochez-vous d'une fenêtre"
        case .tooBright:  "Trop de lumière : évitez le soleil direct"
        case .center:     "Centrez l'assiette dans le cercle"
        case .moveCloser: "Rapprochez-vous du plat"
        case .moveBack:   "Reculez un peu"
        }
    }
}

// MARK: - Engine

/// Combines device tilt (CoreMotion), exposure (AVFoundation) and subject box (Vision)
/// into ONE prioritized hint. Advises only: never blocks the shutter.
@MainActor @Observable public final class GuidanceEngine {
    public var mode: CaptureMode = .topDown
    public private(set) var pitch: Double = 0   // degrees, 0 = upright, 90 = flat over table
    public private(set) var roll: Double = 0    // degrees, left/right tilt
    public private(set) var exposureOffset: Float = 0
    public private(set) var isoRatio: Float = 0    // current ISO / max ISO: high = dim room, grainy photo
    public var subject: CGRect? = nil           // Vision normalized box (origin bottom-left)

    public var hint: GuidanceHint? {
        Self.hint(pitch: pitch, roll: roll, exposureOffset: exposureOffset, isoRatio: isoRatio, subject: subject, mode: mode)
    }
    public var isReady: Bool { hint == nil }

    @ObservationIgnored private let motion = CMMotionManager()
    @ObservationIgnored private var exposureObservation: NSKeyValueObservation?
    @ObservationIgnored private var isoObservation: NSKeyValueObservation?

    public init() {}

    public func start(device: AVCaptureDevice?) {
        if motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive {
            motion.deviceMotionUpdateInterval = 1.0 / 15
            motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let g = data?.gravity else { return }
                MainActor.assumeIsolated { self?.updateTilt(gravity: g) }
            }
        }
        exposureObservation = device?.observe(\.exposureTargetOffset, options: [.new]) { [weak self] dev, _ in
            let offset = dev.exposureTargetOffset
            Task { @MainActor in self?.exposureOffset = offset }
        }
        isoObservation = device?.observe(\.iso, options: [.new]) { [weak self] dev, _ in
            let ratio = dev.iso / max(dev.activeFormat.maxISO, 1)
            Task { @MainActor in self?.isoRatio = ratio }
        }
    }

    public func stop() {
        motion.stopDeviceMotionUpdates()
        exposureObservation = nil
        isoObservation = nil
        // Stale readings would otherwise show a wrong hint when the camera reopens (retake).
        subject = nil
        exposureOffset = 0
        isoRatio = 0
    }

    private func updateTilt(gravity g: CMAcceleration) {
        let newPitch = asin(max(-1, min(1, -g.z))) * 180 / .pi
        let newRoll = asin(max(-1, min(1, g.x))) * 180 / .pi
        // ponytail: simple low-pass to stop the hint flickering; tune alpha if it feels laggy.
        let alpha = 0.25
        pitch += alpha * (newPitch - pitch)
        roll += alpha * (newRoll - roll)
    }

    // MARK: Pure decision logic (unit-tested)

    /// Priority: angle → level → light → framing. Returns nil when the shot is good.
    public nonisolated static func hint(
        pitch: Double,
        roll: Double,
        exposureOffset: Float,
        isoRatio: Float = 0,
        subject: CGRect?,
        mode: CaptureMode
    ) -> GuidanceHint? {
        let delta = pitch - mode.targetPitch
        if delta < -mode.pitchTolerance { return .tiltDown }
        if delta > mode.pitchTolerance { return .tiltUp }
        if abs(roll) > 5 { return .level }
        // Auto-exposure compensates dim light by raising ISO (offset stays ~0), so check both.
        // ponytail: 0.5 of max ISO is a first guess; calibrate on real restaurant lighting.
        if exposureOffset < -1 || isoRatio > 0.5 { return .tooDark }
        if exposureOffset > 1 { return .tooBright }
        guard let box = subject else { return nil }   // no subject detected: don't nag
        if abs(box.midX - 0.5) > 0.15 || abs(box.midY - 0.5) > 0.15 { return .center }
        let area = box.width * box.height
        if area < 0.15 { return .moveCloser }
        if box.width > 0.95 && box.height > 0.95 { return .moveBack }
        return nil
    }
}
