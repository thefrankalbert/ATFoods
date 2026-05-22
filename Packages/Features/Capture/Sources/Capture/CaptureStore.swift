import AVFoundation
import UIKit
import Models
import Networking

@MainActor @Observable public final class CaptureStore {
    public var capturedImage: UIImage? = nil
    public var isCapturing = false
    public var error: String? = nil
    // selectedRestaurant passed in so CaptureView knows which restaurant to attach to
    public let restaurant: Restaurant

    public init(restaurant: Restaurant) {
        self.restaurant = restaurant
    }

    // Called by CameraView after capture
    public func setCapturedImage(_ image: UIImage) {
        capturedImage = image
        isCapturing = false
    }

    public func reset() {
        capturedImage = nil
        isCapturing = false
        error = nil
    }
}
