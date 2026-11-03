import Foundation
import CardCore

/// 编辑态数据结构：把多值字段用换行/逗号分隔的文本编辑，保存时再拆成数组。
struct CardDraft {
    var name: String = ""
    var company: String = ""
    var jobTitle: String = ""
    var mobiles: String = ""
    var phones: String = ""
    var faxes: String = ""
    var emails: String = ""
    var website: String = ""
    var address: String = ""
    var tags: String = ""
    var notes: String = ""

    init() {}

    init(fields: ParsedFields) {
        name = fields.name ?? ""
        company = fields.company ?? ""
        jobTitle = fields.jobTitle ?? ""
        mobiles = fields.mobiles.joined(separator: "\n")
        phones = fields.phones.joined(separator: "\n")
        faxes = fields.faxes.joined(separator: "\n")
        emails = fields.emails.joined(separator: "\n")
        website = fields.website ?? ""
        address = fields.address ?? ""
    }

    init(card: BusinessCard) {
        name = card.name
        company = card.company
        jobTitle = card.jobTitle
        mobiles = card.mobiles.joined(separator: "\n")
        phones = card.phones.joined(separator: "\n")
        faxes = card.faxes.joined(separator: "\n")
        emails = card.emails.joined(separator: "\n")
        website = card.website
        address = card.address
        tags = card.tags.joined(separator: ", ")
        notes = card.notes
    }

    func toCard(id: UUID = UUID(), createdAt: Date = Date()) -> BusinessCard {
        BusinessCard(id: id,
                     name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                     company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                     jobTitle: jobTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                     mobiles: Self.list(mobiles),
                     phones: Self.list(phones),
                     faxes: Self.list(faxes),
                     emails: Self.list(emails),
                     website: website.trimmingCharacters(in: .whitespacesAndNewlines),
                     address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                     tags: tagList,
                     notes: notes,
                     createdAt: createdAt,
                     updatedAt: Date())
    }

    /// 保留原名片的 id、图片、OCR 原文与创建时间。
    func apply(to card: BusinessCard) -> BusinessCard {
        var updated = card
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.company = company.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.jobTitle = jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.mobiles = Self.list(mobiles)
        updated.phones = Self.list(phones)
        updated.faxes = Self.list(faxes)
        updated.emails = Self.list(emails)
        updated.website = website.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.tags = tagList
        updated.notes = notes
        updated.updatedAt = Date()
        return updated
    }

    var tagList: [String] {
        Self.list(tags)
    }

    static func list(_ text: String) -> [String] {
        let separators = CharacterSet(charactersIn: "\n,，;；、")
        return text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
