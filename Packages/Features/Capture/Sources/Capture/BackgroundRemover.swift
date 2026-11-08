import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Networking

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
            let upright = image.resized(maxDimension: 2048)
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
}
