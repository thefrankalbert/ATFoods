@preconcurrency import AVFoundation
import Vision

/// Runs Apple's objectness saliency on live frames (~4 fps) to locate the plate.
/// Runs on the video queue; only the resulting box crosses to the main actor.
final class SubjectDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onSubject: @Sendable (CGRect?) -> Void = { _ in }
    private var lastRun = CMTime.zero
    private let interval = CMTime(value: 1, timescale: 4)
    private let orientationLock = NSLock()
    private var orientation: CGImagePropertyOrientation = .right   // portrait until the preview reports otherwise

    /// Back camera buffers are landscape; map them to the orientation shown on screen.
    func setPreviewAngle(_ angle: CGFloat) {
        let value: CGImagePropertyOrientation = switch Int(angle) {
        case 0: .up
        case 180: .down
        case 270: .left
        default: .right
        }
        orientationLock.withLock { orientation = value }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard CMTimeSubtract(now, lastRun) >= interval,
              let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastRun = now

        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixels, orientation: orientationLock.withLock { orientation })
        try? handler.perform([request])
        let box = (request.results?.first?.salientObjects ?? [])
            .max { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }?
            .boundingBox
        onSubject(box)
    }
}
