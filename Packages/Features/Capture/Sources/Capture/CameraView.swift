import SwiftUI
import PhotosUI
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
    /// Set by the preview once the camera runs (main thread): gives the capture angle for the current orientation.
    var rotation: AVCaptureDevice.RotationCoordinator?
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
        // iPad: keep the camera running when the app is in a resizable window or Split View.
        if session.isMultitaskingCameraAccessSupported { session.isMultitaskingCameraAccessEnabled = true }
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

    @State private var holder = CaptureSessionHolder()
    @State private var coordinator = PhotoCaptureCoordinator()
    @State private var guidance = GuidanceEngine()
    @State private var flashEnabled = false
    @State private var isCameraAvailable = false
    @State private var permissionDenied = false
    @State private var didSetUp = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var isLoadingPick = false
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    public init(
        store: CaptureStore,
        onCapture: @escaping () -> Void
    ) {
        self.store = store
        self.onCapture = onCapture
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isCameraAvailable {
                CameraPreviewLayer(holder: holder, onTapDevicePoint: { holder.focus(at: $0) }, onPreviewAngle: { angle in
                    holder.detector.setPreviewAngle(angle)
                    guidance.isLandscape = angle == 0 || angle == 180
                })
                    .ignoresSafeArea()
                GuidanceOverlay(engine: guidance)
                    .ignoresSafeArea()
            } else if permissionDenied {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Accès à l'appareil photo refusé")
                        .font(.atfHeadline)
                        .foregroundStyle(.white)
                    Text("Autorisez la caméra dans les Réglages pour photographier vos plats, ou choisissez une photo dans la galerie.")
                        .font(.atfBody)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                    ATFDarkButton("Ouvrir les Réglages") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .frame(maxWidth: 260)
                }
                .padding(.horizontal, 32)
            } else if didSetUp {
                VStack(spacing: 8) {
                    Text("Caméra non disponible sur cet appareil")
                        .font(.atfHeadline)
                    Text("Choisissez une photo dans la galerie.")
                        .font(.atfBody)
                        .opacity(0.75)
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            } else {
                ProgressView().tint(.white)
            }

            // Overlay controls (inside the safe area: below the navigation bar, above the home indicator)
            VStack(spacing: 12) {
                Color.clear.frame(height: 4)   // breathing room under the navigation bar
                if let error = store.error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.atfCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.atfDanger, in: Capsule())   // error stays red: it must stand out on the preview
                        .padding(.horizontal, 20)
                        .onTapGesture { store.error = nil }
                } else if isCameraAvailable {
                    GuidanceBanner(engine: guidance)
                        .padding(.horizontal, 20)
                }

                Spacer()

                if isCameraAvailable {
                    CaptureModePicker(engine: guidance)
                }

                // Bottom bar: gallery (left), shutter (center), like the system Camera app.
                HStack {
                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        Group {
                            if isLoadingPick {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 22, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.black.opacity(0.45), in: Circle())   // readable over a white tablecloth
                    }
                    .disabled(isLoadingPick || store.isCapturing)
                    .accessibilityLabel("Choisir dans la galerie")
                    .accessibilityIdentifier("galleryButton")

                    Spacer()

                    // Shutter button: ring turns green when guidance is satisfied (never blocks).
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
                    .disabled(store.isCapturing || !isCameraAvailable)
                    .opacity(isCameraAvailable ? 1 : 0.3)
                    .accessibilityLabel("Prendre la photo")
                    .accessibilityIdentifier("shutterButton")

                    Spacer()

                    Color.clear.frame(width: 56, height: 56)   // keeps the shutter centered
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        // The dark scheme only applies to a visible bar: black bar, white title, chevron and status bar.
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .toolbar {
            // No flash on this device (most iPads) or no camera: no button that would do nothing.
            if isCameraAvailable, holder.device?.hasFlash == true {
              ToolbarItem(placement: .topBarTrailing) {
                Button { flashEnabled.toggle() } label: {
                    Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                }
                .tint(.white)
                .accessibilityLabel(flashEnabled ? "Flash activé" : "Flash désactivé")
              }
            }
        }
        .sensoryFeedback(.success, trigger: guidance.isReady) { _, ready in ready }
        .task {
            await setupSession()
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await usePicked(item) }
        }
        // Back from Settings with the camera now allowed: start without reopening the screen.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, permissionDenied,
                  AVCaptureDevice.authorizationStatus(for: .video) == .authorized else { return }
            permissionDenied = false
            Task { await setupSession() }
        }
        .onDisappear {
            guidance.stop()
            holder.stopRunning()
        }
    }

    // MARK: - Gallery

    /// Same path as a shot from the camera: preview (crop, white background) then attach.
    private func usePicked(_ item: PhotosPickerItem) async {
        isLoadingPick = true
        defer { isLoadingPick = false; pickedItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            store.error = "Impossible d'ouvrir cette photo. Choisissez-en une autre."
            return
        }
        store.error = nil
        store.setCapturedImage(image)
        onCapture()
    }

    // MARK: - Session Setup

    private func setupSession() async {
        #if DEBUG
        // The simulator has no camera: this launch argument shows the camera controls so UI tests can check their layout.
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING_CAMERA") {
            isCameraAvailable = true
            didSetUp = true
            guidance.start(device: nil)
            return
        }
        #endif
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        defer { didSetUp = true }
        switch status {
        case .authorized:
            await configureAndStart()
        case .notDetermined:
            if await AVCaptureDevice.requestAccess(for: .video) {
                await configureAndStart()
            } else {
                permissionDenied = true
            }
        default:   // denied or restricted (parental controls / MDM)
            permissionDenied = true
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
            store.error = "La caméra n'a pas pu démarrer. Fermez puis rouvrez l'appareil photo."
        }
    }

    // MARK: - Capture

    private func capturePhoto() {
        // Capturing on an inactive connection raises an NSException (e.g. tap right after a retake).
        guard isCameraAvailable else { return }
        guard holder.photoOutput.connection(with: .video)?.isActive == true else {
            store.error = "L'appareil photo démarre. Réessayez dans un instant."   // never a shutter that does nothing
            return
        }
        store.error = nil
        store.isCapturing = true

        coordinator.onCapture = { [store] image in
            store.setCapturedImage(image)
            onCapture()
        }
        coordinator.onError = { [store] in
            store.isCapturing = false
            store.error = "La photo n'a pas pu être prise. Réessayez."
        }

        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        if holder.photoOutput.supportedFlashModes.contains(.on) {
            settings.flashMode = flashEnabled ? .on : .off
        }

        if let angle = holder.rotation?.videoRotationAngleForHorizonLevelCapture,
           let connection = holder.photoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
        holder.photoOutput.capturePhoto(with: settings, delegate: coordinator)
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("CameraView") {
    CameraView(
        store: CaptureStore(restaurant: Restaurant.mocks[0]),
        onCapture: {}
    )
}
#endif
