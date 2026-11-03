import Foundation

/// vCard 3.0 导出（T19：字段映射 + 转义）。
public struct VCFExporter {
    public init() {}

    public func export(card: BusinessCard) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCARD")
        lines.append("VERSION:3.0")
        lines.append("N:;\(escape(card.name));;;")
        lines.append("FN:\(escape(card.displayName))")
        if !card.company.isEmpty { lines.append("ORG:\(escape(card.company))") }
        if !card.jobTitle.isEmpty { lines.append("TITLE:\(escape(card.jobTitle))") }
        for number in card.mobiles { lines.append("TEL;TYPE=CELL:\(escape(number))") }
        for number in card.phones { lines.append("TEL;TYPE=WORK:\(escape(number))") }
        for number in card.faxes { lines.append("TEL;TYPE=FAX:\(escape(number))") }
        for email in card.emails { lines.append("EMAIL;TYPE=INTERNET:\(escape(email))") }
        if !card.website.isEmpty { lines.append("URL:\(escape(card.website))") }
        if !card.address.isEmpty { lines.append("ADR;TYPE=WORK:;;\(escape(card.address));;;;") }
        if !card.tags.isEmpty {
            lines.append("CATEGORIES:\(card.tags.map { escape($0) }.joined(separator: ","))")
        }
        if !card.notes.isEmpty { lines.append("NOTE:\(escape(card.notes))") }
        lines.append("END:VCARD")
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    public func export(cards: [BusinessCard]) -> String {
        cards.map { export(card: $0) }.joined(separator: "\r\n")
    }

    public func write(cards: [BusinessCard], to url: URL) throws {
        let content = export(cards: cards)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
    }
}
