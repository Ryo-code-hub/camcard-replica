import SwiftUI
import UIKit

/// 检测结果确认 + 四角手动调整（对应 7.3：显示检测结果 / 手动调整 / 确认 / 重新拍摄）。
struct CropEditorView: View {
    @ObservedObject var model: ScanFlowModel
    @State private var corners: [CGPoint]

    init(model: ScanFlowModel) {
        self.model = model
        let card = model.detectedCard ?? ScanFlowModel.defaultCorners()
        _corners = State(initialValue: [card.topLeft, card.topRight, card.bottomRight, card.bottomLeft])
    }

    var body: some View {
        VStack(spacing: 12) {
            if model.detectionFallback {
                Label("未自动检测到名片边界，请手动拖动四角", systemImage: "hand.draw")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            } else {
                Label("已自动检测名片区域，可拖动四角微调", systemImage: "checkmark.seal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                let viewSize = geometry.size
                let imageSize = model.capturedImage?.size ?? viewSize
                let rect = Self.fittedRect(imageSize: imageSize, in: viewSize)

                ZStack {
                    Color.black.opacity(0.85)
                    if let image = model.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                    quadPath(in: rect)
                        .fill(Color.accentColor.opacity(0.22))
                    quadPath(in: rect)
                        .stroke(Color.accentColor, lineWidth: 2)
                    cornerHandles(in: rect)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 16) {
                Button {
                    model.retake()
                } label: {
                    Label("重新拍摄", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    confirm()
                } label: {
                    Label("确认并识别", systemImage: "text.viewfinder")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
    }

    private func confirm() {
        let card = DetectedCard(
            topLeft: corners[0],
            topRight: corners[1],
            bottomRight: corners[2],
            bottomLeft: corners[3],
            confidence: 1
        )
        model.confirmCrop(card)
    }

    private func quadPath(in rect: CGRect) -> Path {
        var path = Path()
        guard corners.count == 4 else { return path }
        path.move(to: viewPoint(corners[0], in: rect))
        path.addLine(to: viewPoint(corners[1], in: rect))
        path.addLine(to: viewPoint(corners[2], in: rect))
        path.addLine(to: viewPoint(corners[3], in: rect))
        path.closeSubpath()
        return path
    }

    private func cornerHandles(in rect: CGRect) -> some View {
        ForEach(0..<corners.count, id: \.self) { index in
            let corner = corners[index]
            Circle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 3))
                .position(viewPoint(corner, in: rect))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            corners[index] = normalized(value.location, in: rect)
                        }
                )
        }
    }

    private func viewPoint(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + point.x * rect.width,
            y: rect.minY + (1 - point.y) * rect.height
        )
    }

    private func normalized(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        guard rect.width > 0, rect.height > 0 else { return .zero }
        let x = min(max((point.x - rect.minX) / rect.width, 0), 1)
        let y = min(max(1 - (point.y - rect.minY) / rect.height, 0), 1)
        return CGPoint(x: x, y: y)
    }

    static func fittedRect(imageSize: CGSize, in viewSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: viewSize)
        }
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(x: (viewSize.width - width) / 2, y: (viewSize.height - height) / 2, width: width, height: height)
    }
}
