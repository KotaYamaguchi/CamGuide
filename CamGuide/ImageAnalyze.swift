import SwiftUI
import Vision

class ImageAnalyze: ObservableObject {
    func analyzeCGImage(image: CGImage) async throws -> Float {
        let request = CalculateImageAestheticsScoresRequest()
        do {
            let observation = try await request.perform(on: image, orientation: .up)
            let score = observation.overallScore
            return score
        } catch {
            print("Analysis error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func analyzeUIImage(image: UIImage) async throws -> Float {
        guard let cgImage = image.cgImage else {
            print("Failed to convert UIImage to CGImage")
            throw NSError(domain: "ImageConversionError", code: 0, userInfo: nil)
        }
        let request = CalculateImageAestheticsScoresRequest()
        do {
            let observation = try await request.perform(on: cgImage, orientation: .up)
            let score = observation.overallScore
            return score
        } catch {
            print("Analysis error: \(error.localizedDescription)")
            throw error
        }
    }
}
