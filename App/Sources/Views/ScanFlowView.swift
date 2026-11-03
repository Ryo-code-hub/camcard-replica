import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

struct ScanFlowView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = ScanFlowModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCameraPicker = false
    @State private var showPermissionAlert = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") { dismiss() }
                    }
                }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { @MainActor in
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    model.handleImage(image)
                }
            }
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPickerView(
                onImage: { image in
                    showCameraPicker = false
                    model.handleImage(image)
                },
                onCancel: {
                    showCameraPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .alert("无法使用相机", isPresented: $showPermissionAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("相机不可用或权限被拒绝。请使用相册导入；真机上可重新授权后拍摄。")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .capture:
            captureView
        case .processing(let message):
            processingView(message)
        case .review:
            reviewView
        case .failed(let message):
            failureView(message)
        }
    }

    // MARK: - Capture

    private var captureView: some View {
        VStack(spacing: 20) {
            MockCameraPreview(imageName: "sample_card_01")
                .frame(height: 240)
                .padding(.horizontal, 20)

            Text(cameraAvailable ? "将名片放在取景框内，尽量填满画面" : "模拟器没有摄像头：点“模拟拍摄”或从相册导入")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button {
                    requestCamera()
                } label: {
                    Label("拍摄", systemImage: "camera.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!cameraAvailable)

                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Label("相册导入", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
            }

            if !cameraAvailable {
                Button {
                    mockCapture()
                } label: {
                    Label("模拟拍摄（测试名片）", systemImage: "wand.and.stars")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(.top, 24)
    }

    private func requestCamera() {
        guard cameraAvailable else {
            showPermissionAlert = true
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCameraPicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCameraPicker = true
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        default:
            showPermissionAlert = true
        }
    }

    private func mockCapture() {
        if let image = MockCameraPreview.image(named: "sample_card_01") {
            model.handleImage(image)
        }
    }

    // MARK: - Processing / Review / Failure

    private func processingView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.headline)
            Text("首次识别可能需要几秒")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviewView: some View {
        CardFormView(mode: .create, initialDraft: CardDraft(fields: model.fields)) { draft in
            if let card = model.makeCard(draft: draft) {
                store.add(card)
            }
        }
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("重拍 / 重新导入") {
                model.retake()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var navigationTitle: String {
        switch model.phase {
        case .capture: return "扫描名片"
        case .processing: return "识别中"
        case .review: return "确认信息"
        case .failed: return "识别失败"
        }
    }
}

// MARK: - Mock camera (simulator)

struct MockCameraPreview: View {
    let imageName: String

    var body: some View {
        ZStack {
            if let image = Self.image(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.15))
                    .overlay(Text("缺少测试名片资源 \(imageName).png").font(.caption).foregroundStyle(.secondary))
            }
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topLeading) {
            Text("模拟相机")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(8)
        }
    }

    static func image(named name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png") {
            return UIImage(contentsOfFile: url.path)
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "SampleCards") {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }
}

// MARK: - System camera

struct CameraPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPickerView

        init(parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}
