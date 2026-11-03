import Foundation

public protocol BusinessCardStoring {
    func load() throws -> [BusinessCard]
    func save(_ cards: [BusinessCard]) throws
}

/// JSON 文件存储（App 中文件位于 Documents/，测试中可指向临时目录）。
public final class JSONFileCardStore: BusinessCardStoring {
    public let fileURL: URL
    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func load() throws -> [BusinessCard] {
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([BusinessCard].self, from: data)
    }

    public func save(_ cards: [BusinessCard]) throws {
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(cards)
        try data.write(to: fileURL, options: .atomic)
    }
}

public enum RepositoryError: Error, Equatable {
    case notFound
}

/// 名片仓库：增删改查、搜索、标签管理；每次变更立即持久化。
public final class BusinessCardRepository {
    public private(set) var cards: [BusinessCard] = []
    private let store: BusinessCardStoring

    public init(store: BusinessCardStoring) throws {
        self.store = store
        self.cards = try store.load()
        sortCards()
    }

    public func reload() throws {
        cards = try store.load()
        sortCards()
    }

    public func add(_ card: BusinessCard) throws {
        var card = card
        card.updatedAt = Date()
        cards.append(card)
        try persist()
    }

    public func update(_ card: BusinessCard) throws {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else {
            throw RepositoryError.notFound
        }
        var updated = card
        updated.updatedAt = Date()
        cards[index] = updated
        try persist()
    }

    public func delete(id: UUID) throws {
        cards.removeAll { $0.id == id }
        try persist()
    }

    public func card(withID id: UUID) -> BusinessCard? {
        cards.first { $0.id == id }
    }

    public var allTags: [String] {
        Array(Set(cards.flatMap { $0.tags })).sorted()
    }

    public func addTag(_ tag: String, to cardID: UUID) throws {
        let cleaned = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let index = cards.firstIndex(where: { $0.id == cardID }) else { return }
        if !cards[index].tags.contains(cleaned) {
            cards[index].tags.append(cleaned)
        }
        try persist()
    }

    public func removeTag(_ tag: String, from cardID: UUID) throws {
        guard let index = cards.firstIndex(where: { $0.id == cardID }) else { return }
        cards[index].tags.removeAll { $0 == tag }
        try persist()
    }

    /// 删除标签：从所有名片上移除（T16）。
    public func deleteTag(_ tag: String) throws {
        for index in cards.indices {
            cards[index].tags.removeAll { $0 == tag }
        }
        try persist()
    }

    /// 搜索：姓名/公司/职位/邮箱/电话/备注，支持中文包含与电话数字匹配（T15）。
    public func search(_ query: String, tag: String? = nil) -> [BusinessCard] {
        var result = cards
        if let tag, !tag.isEmpty {
            result = result.filter { $0.tags.contains(tag) }
        }
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return result }
        let queryDigits = normalized.filter { $0.isNumber }
        return result.filter { card in
            let text = [card.name, card.company, card.jobTitle, card.website, card.address, card.notes]
                .joined(separator: "\n")
                .lowercased()
            if text.contains(normalized) { return true }
            if card.emails.joined(separator: " ").lowercased().contains(normalized) { return true }
            let phoneNumbers = card.mobiles + card.phones + card.faxes
            if phoneNumbers.contains(where: { $0.lowercased().contains(normalized) }) { return true }
            if !queryDigits.isEmpty {
                let allDigits = phoneNumbers.joined().filter { $0.isNumber }
                if allDigits.contains(queryDigits) { return true }
            }
            return false
        }
    }

    private func persist() throws {
        try store.save(cards)
        sortCards()
    }

    private func sortCards() {
        cards.sort { $0.updatedAt > $1.updatedAt }
    }
}

/// 内存存储，便于测试 / SwiftUI Preview。
public final class InMemoryCardStore: BusinessCardStoring {
    public var cards: [BusinessCard]

    public init(cards: [BusinessCard] = []) {
        self.cards = cards
    }

    public func load() throws -> [BusinessCard] { cards }

    public func save(_ cards: [BusinessCard]) throws { self.cards = cards }
}
