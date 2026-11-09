import UIKit

public extension UIImage {
    /// Upright copy with the longest edge capped (scale 1). Shared by upload and background removal.
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        let factor = min(1, maxDimension / longest)
        let target = CGSize(width: (size.width * factor).rounded(), height: (size.height * factor).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// JPEG ready for upload (12 MP shots are 3-5 MB, too slow on mobile data).
    /// Runs off the main actor so the button spinner keeps animating.
    func uploadJPEG(maxDimension: CGFloat = 1600, quality: CGFloat = 0.8) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            self.resized(maxDimension: maxDimension).jpegData(compressionQuality: quality)
        }.value
    }
}
