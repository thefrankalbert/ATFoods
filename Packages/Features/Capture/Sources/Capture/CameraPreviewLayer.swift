import SwiftUI
import AVFoundation

struct CameraPreviewLayer: UIViewRepresentable {
    let holder: CaptureSessionHolder
    /// Tap location converted to device coordinates (0...1), for tap-to-focus.
    var onTapDevicePoint: (CGPoint) -> Void = { _ in }
    /// Preview rotation in degrees (90 = portrait, 0 or 180 = landscape), each time the device turns.
    var onPreviewAngle: (CGFloat) -> Void = { _ in }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = holder.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.onTap = onTapDevicePoint
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(PreviewView.handleTap(_:))))
        // The app turns with the iPad: preview, photo and framing must follow the real orientation.
        if let device = holder.device {
            let rotation = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: view.videoPreviewLayer)
            holder.rotation = rotation
            let apply: @MainActor (CGFloat) -> Void = { [weak view, onPreviewAngle] angle in
                guard let connection = view?.videoPreviewLayer.connection,
                      connection.isVideoRotationAngleSupported(angle) else { return }
                connection.videoRotationAngle = angle
                onPreviewAngle(angle)
            }
            apply(rotation.videoRotationAngleForHorizonLevelPreview)
            view.observation = rotation.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new]) { rotation, _ in
                let angle = rotation.videoRotationAngleForHorizonLevelPreview
                Task { @MainActor in apply(angle) }
            }
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.onTap = onTapDevicePoint
    }

    final class PreviewView: UIView {
        var onTap: (CGPoint) -> Void = { _ in }
        var observation: NSKeyValueObservation?
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            onTap(videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gesture.location(in: self)))
        }
    }
}
