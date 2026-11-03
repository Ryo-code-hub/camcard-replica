import UIKit
import CardCore

/// 扫描流程状态机：capture → processing(detect/correct/OCR/parse) → review → save
@MainActor
final class ScanFlowModel: ObservableObject {
    enum Phase: Equatable {
        case capture
        case processing(String)
        case review
        case failed(String)
    }

    @Published private(set) var phase: Phase = .capture
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var processedImage: UIImage?
    @Published private(set) var rawOCRText: String = ""
    @Published private(set) var fields = ParsedFields()
    @Published private(set) var usedFallbackCrop = false

    private var processingTask: Task<Void, Never>?

    func handleImage(_ image: UIImage) {
        capturedImage = image
        phase = .processing("检测名片区域…")
        processingTask?.cancel()
        processingTask = Task { [weak self] in
            await self?.process(image)
        }
    }

    func retake() {
        processingTask?.cancel()
        capturedImage = nil
        processedImage = nil
        rawOCRText = ""
        fields = ParsedFields()
        usedFallbackCrop = false
        phase = .capture
    }

    func makeCard(draft: CardDraft) -> BusinessCard? {
        let services = ServiceContainer.shared
        let id = UUID()
        var card = draft.toCard(id: id, createdAt: Date())
        if let capturedImage {
            card.originalImageFileName = try? services.imageStore.save(
                image: capturedImage,
                name: "\(id.uuidString)-original.jpg"
            )
        }
        if let processedImage {
            card.processedImageFileName = try? services.imageStore.save(
                image: processedImage,
                name: "\(id.uuidString)-processed.jpg"
            )
        }
        card.rawOCRText = rawOCRText
        return card
    }

    private func process(_ image: UIImage) async {
        let services = ServiceContainer.shared
        do {
            phase = .processing("检测名片区域…")
            var corrected: UIImage?
            do {
                let detection = try await services.detectionService.detect(in: image)
                corrected = services.correctionService.correct(image, card: detection)
            } catch {
                corrected = nil
            }
            if corrected == nil {
                corrected = services.correctionService.fallbackCrop(image)
                usedFallbackCrop = true
            } else {
                usedFallbackCrop = false
            }
            guard let processed = corrected else {
                throw ScanFlowError.imageProcessingFailed
            }
            processedImage = processed

            phase = .processing("识别文字（OCR）…")
            let resized = processed.resized(maxDimension: 2000)
            let ocr = try await services.ocrService.recognize(image: resized)
            rawOCRText = ocr.rawText

            phase = .processing("解析联系人字段…")
            fields = services.parser.parse(ocr.blocks)
            phase = .review
        } catch {
            if Task.isCancelled { return }
            let message = (error as? LocalizedError)?.errorDescription ?? "识别失败：\(error.localizedDescription)"
            phase = .failed(message)
        }
    }
}

enum ScanFlowError: Error, LocalizedError {
    case imageProcessingFailed

    var errorDescription: String? { "图像处理失败，请重试或换一张图片" }
}
