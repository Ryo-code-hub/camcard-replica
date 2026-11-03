import XCTest
import CardCore

final class VCFExporterTests: XCTestCase {
    private let exporter = VCFExporter()

    private func makeCard() -> BusinessCard {
        BusinessCard(name: "David Chen",
                     company: "ABC University",
                     jobTitle: "Professor",
                     mobiles: ["+86 138 0013 8000"],
                     phones: ["021-12345678"],
                     faxes: ["021-87654321"],
                     emails: ["david@abc.edu"],
                     website: "www.abc.edu",
                     address: "上海市杨浦区四平路1239号",
                     tags: ["Conference", "Professor"],
                     notes: "Follow up next week")
    }

    // T19：字段映射
    func testFieldMapping() {
        let vcf = exporter.export(card: makeCard())

        XCTAssertTrue(vcf.hasPrefix("BEGIN:VCARD"))
        XCTAssertTrue(vcf.contains("VERSION:3.0"))
        XCTAssertTrue(vcf.contains("FN:David Chen"))
        XCTAssertTrue(vcf.contains("ORG:ABC University"))
        XCTAssertTrue(vcf.contains("TITLE:Professor"))
        XCTAssertTrue(vcf.contains("TEL;TYPE=CELL:+86 138 0013 8000"))
        XCTAssertTrue(vcf.contains("TEL;TYPE=WORK:021-12345678"))
        XCTAssertTrue(vcf.contains("TEL;TYPE=FAX:021-87654321"))
        XCTAssertTrue(vcf.contains("EMAIL;TYPE=INTERNET:david@abc.edu"))
        XCTAssertTrue(vcf.contains("URL:www.abc.edu"))
        XCTAssertTrue(vcf.contains("CATEGORIES:Conference,Professor"))
        XCTAssertTrue(vcf.contains("NOTE:Follow up next week"))
        XCTAssertTrue(vcf.hasSuffix("END:VCARD\r\n"))
    }

    // T19：特殊字符转义
    func testEscapingOfSpecialCharacters() {
        var card = BusinessCard(name: "Doe, John; Jr.")
        card.notes = "Line1\nLine2"
        let vcf = exporter.export(card: card)

        XCTAssertTrue(vcf.contains("FN:Doe\\, John\\; Jr."))
        XCTAssertTrue(vcf.contains("NOTE:Line1\\nLine2"))
    }

    // T19：多张名片
    func testMultipleCards() {
        let vcf = exporter.export(cards: [makeCard(), BusinessCard(name: "Alice Wang")])
        let beginCount = vcf.components(separatedBy: "BEGIN:VCARD").count - 1
        let endCount = vcf.components(separatedBy: "END:VCARD").count - 1
        XCTAssertEqual(beginCount, 2)
        XCTAssertEqual(endCount, 2)
    }

    // 未命名名片回退
    func testUnnamedCardUsesFallbackFN() {
        let vcf = exporter.export(card: BusinessCard())
        XCTAssertTrue(vcf.contains("FN:未命名名片"))
    }
}
