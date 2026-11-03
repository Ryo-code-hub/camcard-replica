import UIKit
import CoreImage

/// Core Image 透视校正：把检测到的四角校正成矩形名片。
struct ImageCorrectionService {
    private let context = CIContext()

    func correct(_ image: UIImage, card: DetectedCard) -> UIImage? {
        let normalized = image.normalizedUp()
        guard let ciImage = CIImage(image: normalized) else { return nil }
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        guard width > 0, height > 0 else { return nil }

        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * width, y: p.y * height)
        }

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: point(card.topLeft)), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: point(card.topRight)), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: point(card.bottomRight)), forKey: "inputBottomRight")
        filter.setValue(CIVector(cgPoint: point(card.bottomLeft)), forKey: "inputBottomLeft")
        guard let output = filter.outputImage,
              output.extent.width > 1,
              output.extent.height > 1,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: normalized.scale, orientation: .up)
    }

    /// 检测失败时的兜底：轻微内缩裁剪（并在差异分析中记录）。
    func fallbackCrop(_ image: UIImage, insetRatio: CGFloat = 0.03) -> UIImage {
        let normalized = image.normalizedUp()
        guard let cgImage = normalized.cgImage else { return normalized }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let insetX = width * insetRatio
        let insetY = height * insetRatio
        let rect = CGRect(x: insetX, y: insetY, width: width - insetX * 2, height: height - insetY * 2).integral
        guard let cropped = cgImage.cropping(to: rect) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }
}
