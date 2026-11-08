import SwiftUI
@preconcurrency import AVFoundation
import UIKit
import Models
import DesignSystem

// MARK: - Session Holder (wraps AVCaptureSession for cross-actor use)

/// Wraps AVCaptureSession in an @unchecked Sendable so it can be passed
/// to background tasks. All session access must be on the captureQueue.
final class CaptureSessionHolder: @unchecked Sendable {
    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    let detector = SubjectDetector()
    private(set) var device: AVCaptureDevice?
    let captureQueue = DispatchQueue(label: "com.atfoods.capture", qos: .userInitiated)
    private let videoQueue = DispatchQueue(label: "com.atfoods.capture.video", qos: .utility)

    func startRunning() {
        captureQueue.async { [session] in
            session.startRunning()
        }
    }

    func stopRunning() {
        captureQueue.async { [session] in
            session.stopRunning()
        }
    }

    /// Configure the session with the back camera, on the capture queue. Returns true if successful.
    func configure() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            captureQueue.async {
                continuation.resume(with: Result { try self.configureOnQueue() })
            }
        }
    }

    private func configureOnQueue() throws -> Bool {
        guard device == nil else { return true }
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            return false
        }

        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        guard session.canAddInput(input) else { return false }
        session.addInput(input)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }
        // Live frames for Vision framing guidance; late frames dropped to keep preview smooth.
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(detector, queue: videoQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        self.device = device   // only once fully configured, so a failed attempt can be retried
        return true
    }

    /// Tap-to-focus: point in device coordinates (0...1).
    func focus(at point: CGPoint) {
        guard let device else { return }
        captureQueue.async {
            guard (try? device.lockForConfiguration()) != nil else { return }
            // Continuous AF at the tapped point: keeps refocusing if the plate moves.
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        }
    }
}

// MARK: - Photo Capture Coordinator

@MainActor
final class PhotoCaptureCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
    var onCapture: (UIImage) -> Void = { _ in }
    var onError: () -> Void = {}

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in self.onError() }
            return
        }
        let img = image
        Task { @MainActor in
            self.onCapture(img)
        }
    }
}

// MARK: - CameraView

public struct CameraView: View {
    @Bindable var store: CaptureStore
    let onCapture: () -> Void
    let onClose: () -> Void

    @State private var holder = CaptureSessionHolder()
    @State private var coordinator = PhotoCaptureCoordinator()
    @State private var guidance = GuidanceEngine()
    @State private var flashEnabled = false
    @State private var isCameraAvailable = false

    public init(
        store: CaptureStore,
        onCapture: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.onCapture = onCapture
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isCameraAvailable {
                CameraPreviewLayer(session: holder.session, onTapDevicePoint: { holder.focus(at: $0) })
                    .ignoresSafeArea()
                GuidanceOverlay(engine: guidance)
                    .ignoresSafeArea()
            } else {
                Text("Caméra non disponible")
                    .foregroundColor(.white)
                    .font(.headline)
            }

            // Overlay controls
            VStack(spacing: 12) {
                // Top bar
                HStack {
                    Button(action: { onClose() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Fermer")
                    Spacer()
                    Button(action: { flashEnabled.toggle() }) {
                        Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(flashEnabled ? .yellow : .white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Flash")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if isCameraAvailable {
                    GuidanceBanner(engine: guidance)
                        .padding(.horizontal, 20)
                }

                Spacer()

                if isCameraAvailable {
                    CaptureModePicker(engine: guidance)
                }

                // Bottom bar
                HStack {
                    // Last captured thumbnail
                    if let lastPhoto = store.capturedImage {
                        Image(uiImage: lastPhoto)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Spacer().frame(width: 40, height: 40)
                    }

                    Spacer()

                    // Shutter button — ring turns green when guidance is satisfied (never blocks).
                    Button(action: { capturePhoto() }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(guidance.isReady ? Color.atfSuccess : Color.white.opacity(0.5), lineWidth: 4)
                                    .frame(width: 82, height: 82)
                            )
                    }
                    .disabled(store.isCapturing)
                    .accessibilityLabel("Prendre la photo")
                    .accessibilityIdentifier("shutterButton")

                    Spacer()

                    // Placeholder to balance layout
                    Spacer().frame(width: 40, height: 40)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden()
        .sensoryFeedback(.success, trigger: guidance.isReady) { _, ready in ready }
        .task {
            await setupSession()
        }
        .onDisappear {
            guidance.stop()
            holder.stopRunning()
        }
    }

    // MARK: - Session Setup

    private func setupSession() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            await configureAndStart()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await configureAndStart()
            }
        default:
            break
        }
    }

    private func configureAndStart() async {
        let h = holder
        let engine = guidance
        if h.device == nil {
            // Set once, before the session ever runs: never mutated while frames flow.
            h.detector.onSubject = { box in
                Task { @MainActor in engine.subject = box }
            }
        }
        do {
            let available = try await h.configure()
            isCameraAvailable = available
            if available {
                h.startRunning()
                engine.start(device: h.device)
            }
        } catch {
            store.error = error.localizedDescription
        }
    }

    // MARK: - Capture

    private func capturePhoto() {
        // Capturing on an inactive connection raises an NSException (e.g. tap right after a retake).
        guard isCameraAvailable,
              holder.photoOutput.connection(with: .video)?.isActive == true else { return }
        store.isCapturing = true

        coordinator.onCapture = { [store] image in
            store.setCapturedImage(image)
            onCapture()
        }
        coordinator.onError = { [store] in
            store.isCapturing = false
            store.error = "La photo n'a pas pu être prise. Réessaie."
        }

        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        if holder.photoOutput.supportedFlashModes.contains(.on) {
            settings.flashMode = flashEnabled ? .on : .off
        }

        holder.photoOutput.capturePhoto(with: settings, delegate: coordinator)
    }
}

// MARK: - Preview

#Preview("CameraView") {
    CameraView(
        store: CaptureStore(restaurant: Restaurant.mocks[0]),
        onCapture: {},
        onClose: {}
    )
}
