import UIKit
import Vision
import CardCore

struct OCRResult {
    let rawText: String
    let blocks: [OCRTextBlock]
}

protocol OCRService {
    func recognize(image: UIImage) async throws -> OCRResult
}

enum OCRServiceError: Error, LocalizedError {
    case noText
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .noText: return "没有识别到文字，请换一张更清晰的名片"
        case .encodingFailed: return "图片处理失败"
        }
    }
}

/// Vision 原生 OCR：中英混合，输出原始文本 + 带位置的行。
final class VisionOCRService: OCRService {
    func recognize(image: UIImage) async throws -> OCRResult {
        let normalized = image.normalizedUp()
        guard let cgImage = normalized.cgImage else {
            throw OCRServiceError.encodingFailed
        }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<OCRResult, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    request.recognitionLanguages = ["zh-Hans", "en-US"]
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
                    try handler.perform([request])
                    let observations = request.results ?? []
                    let sorted = observations.sorted { lhs, rhs in
                        if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) > 0.01 {
                            return lhs.boundingBox.midY > rhs.boundingBox.midY
                        }
                        return lhs.boundingBox.minX < rhs.boundingBox.minX
                    }
                    let blocks: [OCRTextBlock] = sorted.compactMap { observation in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        let box = observation.boundingBox
                        return OCRTextBlock(
                            text: candidate.string,
                            confidence: Double(candidate.confidence),
                            boundingBox: NormalizedRect(
                                x: Double(box.minX),
                                y: Double(box.minY),
                                width: Double(box.width),
                                height: Double(box.height)
                            )
                        )
                    }
                    if blocks.isEmpty {
                        continuation.resume(throwing: OCRServiceError.noText)
                        return
                    }
                    let rawText = blocks.map(\.text).joined(separator: "\n")
                    continuation.resume(returning: OCRResult(rawText: rawText, blocks: blocks))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
