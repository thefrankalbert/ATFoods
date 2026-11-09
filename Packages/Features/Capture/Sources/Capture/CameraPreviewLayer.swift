import SwiftUI
import AVFoundation

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    /// Tap location converted to device coordinates (0...1), for tap-to-focus.
    var onTapDevicePoint: (CGPoint) -> Void = { _ in }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.onTap = onTapDevicePoint
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(PreviewView.handleTap(_:))))
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.onTap = onTapDevicePoint
    }

    final class PreviewView: UIView {
        var onTap: (CGPoint) -> Void = { _ in }
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            onTap(videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gesture.location(in: self)))
        }
    }
}
