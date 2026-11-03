import UIKit

enum ImageStoreError: Error {
    case encodingFailed
}

/// 名片图片本地存储：Documents/BusinessCards/
final class ImageStore {
    let rootURL: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.rootURL = documents.appendingPathComponent("BusinessCards", isDirectory: true)
        try? fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    @discardableResult
    func save(image: UIImage, name: String) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw ImageStoreError.encodingFailed
        }
        try data.write(to: rootURL.appendingPathComponent(name), options: .atomic)
        return name
    }

    func load(name: String) -> UIImage? {
        UIImage(contentsOfFile: rootURL.appendingPathComponent(name).path)
    }

    func delete(name: String) {
        try? fileManager.removeItem(at: rootURL.appendingPathComponent(name))
    }
}
