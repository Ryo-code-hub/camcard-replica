import UIKit
import Vision

struct DetectedCard {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint
    var confidence: Float
}

enum CardDetectionError: Error, LocalizedError {
    case notFound

    var errorDescription: String? { "未检测到名片边界" }
}

/// Vision 矩形检测：输出归一化四角（原点左下）。
struct CardDetectionService {
    func detect(in image: UIImage) async throws -> DetectedCard {
        let normalized = image.normalizedUp()
        guard let cgImage = normalized.cgImage else {
            throw CardDetectionError.notFound
        }
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.3
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 3.0
        request.quadratureTolerance = 30
        request.minimumSize = 0.15
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])
        guard let rectangle = request.results?.first else {
            throw CardDetectionError.notFound
        }
        return DetectedCard(
            topLeft: rectangle.topLeft,
            topRight: rectangle.topRight,
            bottomRight: rectangle.bottomRight,
            bottomLeft: rectangle.bottomLeft,
            confidence: rectangle.confidence
        )
    }
}
