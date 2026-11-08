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
    /// Set when the camera was opened from a dish card: the photo goes straight to this dish.
    public let targetDish: MenuItem?

    public init(restaurant: Restaurant, targetDish: MenuItem? = nil) {
        self.restaurant = restaurant
        self.targetDish = targetDish
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
