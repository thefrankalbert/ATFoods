import SwiftUI
import AVFoundation
import UIKit
import Models

// MARK: - Session Holder (wraps AVCaptureSession for cross-actor use)

/// Wraps AVCaptureSession in an @unchecked Sendable so it can be passed
/// to background tasks. All access must be on the captureQueue.
final class CaptureSessionHolder: @unchecked Sendable {
    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let captureQueue = DispatchQueue(label: "com.atfoods.capture", qos: .userInitiated)

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

    /// Configure the session with the back camera. Returns true if successful.
    func configure() throws -> Bool {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            return false
        }

        let input = try AVCaptureDeviceInput(device: device)
        session.beginConfiguration()
        session.sessionPreset = .photo
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
        return true
    }
}

// MARK: - Photo Capture Coordinator

@MainActor
final class PhotoCaptureCoordinator: NSObject, AVCapturePhotoCaptureDelegate {
    var onCapture: (UIImage) -> Void = { _ in }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
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
                CameraPreviewLayer(session: holder.session)
                    .ignoresSafeArea()
            } else {
                Text("Caméra non disponible")
                    .foregroundColor(.white)
                    .font(.headline)
            }

            // Overlay controls
            VStack {
                // Top bar
                HStack {
                    Button(action: { onClose() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Button(action: { flashEnabled.toggle() }) {
                        Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(flashEnabled ? .yellow : .white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

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

                    // Shutter button
                    Button(action: { capturePhoto() }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                    .frame(width: 82, height: 82)
                            )
                    }
                    .disabled(store.isCapturing)

                    Spacer()

                    // Placeholder to balance layout
                    Spacer().frame(width: 40, height: 40)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .statusBarHidden()
        .task {
            await setupSession()
        }
        .onDisappear {
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
        do {
            let available = try h.configure()
            isCameraAvailable = available
            if available {
                h.startRunning()
            }
        } catch {
            store.error = error.localizedDescription
        }
    }

    // MARK: - Capture

    private func capturePhoto() {
        guard isCameraAvailable else { return }
        store.isCapturing = true

        coordinator.onCapture = { [store] image in
            store.setCapturedImage(image)
            onCapture()
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashEnabled ? .on : .off

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
