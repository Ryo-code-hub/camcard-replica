import Foundation
import CardCore

/// 服务容器：App 内共享的 OCR / 检测 / 校正 / 图片存储 / 解析器。
@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()

    let imageStore: ImageStore
    let ocrService: OCRService
    let detectionService: CardDetectionService
    let correctionService: ImageCorrectionService
    let parser: FieldParser
    let vcfExporter: VCFExporter

    private init() {
        self.imageStore = ImageStore()
        self.ocrService = VisionOCRService()
        self.detectionService = CardDetectionService()
        self.correctionService = ImageCorrectionService()
        self.parser = FieldParser()
        self.vcfExporter = VCFExporter()
    }
}
