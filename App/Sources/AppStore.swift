import Foundation
import UIKit
import CardCore

/// 全局状态：名片列表、搜索、标签筛选、错误提示。
@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var cards: [BusinessCard] = []
    @Published var searchText: String = ""
    @Published var selectedTag: String?
    @Published var lastErrorMessage: String?

    private let repository: BusinessCardRepository
    private let imageStore: ImageStore

    init(repository: BusinessCardRepository? = nil, imageStore: ImageStore? = nil) {
        let services = ServiceContainer.shared
        self.imageStore = imageStore ?? services.imageStore
        if let repository {
            self.repository = repository
        } else {
            let url = Self.storeURL()
            if let created = try? BusinessCardRepository(store: JSONFileCardStore(fileURL: url)) {
                self.repository = created
            } else {
                self.repository = try! BusinessCardRepository(store: InMemoryCardStore())
            }
        }
        self.cards = self.repository.cards
    }

    private static func storeURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = documents.appendingPathComponent("CamCardReplica", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("cards.json")
    }

    var filteredCards: [BusinessCard] {
        repository.search(searchText, tag: selectedTag)
    }

    var tags: [String] {
        repository.allTags
    }

    func image(for card: BusinessCard, processed: Bool) -> UIImage? {
        let name = processed ? card.processedImageFileName : card.originalImageFileName
        guard let name else { return nil }
        return imageStore.load(name: name)
    }

    func add(_ card: BusinessCard) {
        do {
            try repository.add(card)
            cards = repository.cards
        } catch {
            lastErrorMessage = "保存名片失败：\(error.localizedDescription)"
        }
    }

    func update(_ card: BusinessCard) {
        do {
            try repository.update(card)
            cards = repository.cards
        } catch {
            lastErrorMessage = "更新名片失败：\(error.localizedDescription)"
        }
    }

    func delete(_ card: BusinessCard) {
        do {
            try repository.delete(id: card.id)
            cards = repository.cards
            if selectedTag != nil && !repository.allTags.contains(selectedTag!) {
                selectedTag = nil
            }
        } catch {
            lastErrorMessage = "删除名片失败：\(error.localizedDescription)"
        }
    }

    func addTag(_ tag: String, to card: BusinessCard) {
        do {
            try repository.addTag(tag, to: card.id)
            cards = repository.cards
        } catch {
            lastErrorMessage = "添加标签失败：\(error.localizedDescription)"
        }
    }

    func deleteTag(_ tag: String) {
        do {
            try repository.deleteTag(tag)
            cards = repository.cards
            if selectedTag == tag { selectedTag = nil }
        } catch {
            lastErrorMessage = "删除标签失败：\(error.localizedDescription)"
        }
    }

    func clearError() {
        lastErrorMessage = nil
    }
}
