import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

enum BackgroundRemoverError: LocalizedError {
    case noSubject

    var errorDescription: String? {
        "Impossible de détourer le plat. Essaie avec un fond plus uni."
    }
}

/// On-device subject lift (Apple Vision, iOS 17) composited on a plain background.
/// Replaces the never-deployed paid "AI retouch" backend. Does not run on the simulator.
enum BackgroundRemover {
    static func replaceBackground(of image: UIImage, with color: UIColor = .white) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            // Redraw upright + capped so Vision, mask and output share one coordinate space.
            let upright = normalized(image, maxDimension: 2048)
            guard let cgImage = upright.cgImage else { throw BackgroundRemoverError.noSubject }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            let request = VNGenerateForegroundInstanceMaskRequest()
            try handler.perform([request])
            guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
                throw BackgroundRemoverError.noSubject
            }
            let mask = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)

            let input = CIImage(cgImage: cgImage)
            let blend = CIFilter.blendWithMask()
            blend.inputImage = input
            blend.backgroundImage = CIImage(color: CIColor(color: color)).cropped(to: input.extent)
            blend.maskImage = CIImage(cvPixelBuffer: mask)
            guard let output = blend.outputImage,
                  let result = CIContext().createCGImage(output, from: input.extent) else {
                throw BackgroundRemoverError.noSubject
            }
            return UIImage(cgImage: result)
        }.value
    }

    private static func normalized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
