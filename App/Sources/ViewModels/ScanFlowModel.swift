import UIKit
import Combine
import CardCore

/// 扫描流程状态机：
/// capture → detecting（矩形检测）→ cropping（确认/手动调整四角）→ processing（校正+OCR+解析）→ review → save
@MainActor
final class ScanFlowModel: ObservableObject {
    enum Phase: Equatable {
        case capture
        case detecting
        case cropping
        case processing(String)
        case review
        case failed(String)
    }

    @Published private(set) var phase: Phase = .capture
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var processedImage: UIImage?
    @Published private(set) var detectedCard: DetectedCard?
    @Published private(set) var detectionFallback = false
    @Published private(set) var rawOCRText: String = ""
    @Published private(set) var fields = ParsedFields()
    @Published private(set) var usedFallbackCrop = false

    private var processingTask: Task<Void, Never>?

    func handleImage(_ image: UIImage) {
        capturedImage = image
        detectedCard = nil
        processedImage = nil
        detectionFallback = false
        phase = .detecting
        processingTask?.cancel()
        processingTask = Task { [weak self] in
            await self?.detectCard(in: image)
        }
    }

    func confirmCrop(_ card: DetectedCard) {
        guard let capturedImage else { return }
        detectedCard = card
        processingTask?.cancel()
        phase = .processing("校正与识别中…")
        processingTask = Task { [weak self] in
            await self?.process(image: capturedImage, card: card)
        }
    }

    func retake() {
        processingTask?.cancel()
        capturedImage = nil
        processedImage = nil
        detectedCard = nil
        detectionFallback = false
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

    private func detectCard(in image: UIImage) async {
        let services = ServiceContainer.shared
        do {
            let detected = try await services.detectionService.detect(in: image)
            detectedCard = detected
            detectionFallback = false
        } catch {
            detectedCard = Self.defaultCorners()
            detectionFallback = true
        }
        if Task.isCancelled { return }
        phase = .cropping
    }

    private func process(image: UIImage, card: DetectedCard) async {
        let services = ServiceContainer.shared
        do {
            var corrected = services.correctionService.correct(image, card: card)
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

    static func defaultCorners() -> DetectedCard {
        let inset: CGFloat = 0.06
        return DetectedCard(
            topLeft: CGPoint(x: inset, y: 1 - inset),
            topRight: CGPoint(x: 1 - inset, y: 1 - inset),
            bottomRight: CGPoint(x: 1 - inset, y: inset),
            bottomLeft: CGPoint(x: inset, y: inset),
            confidence: 0
        )
    }
}

enum ScanFlowError: Error, LocalizedError {
    case imageProcessingFailed

    var errorDescription: String? { "图像处理失败，请重试或换一张图片" }
}
