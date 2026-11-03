import XCTest
import CardCore

final class ModelTests: XCTestCase {
    func testDisplayNameFallback() {
        XCTAssertEqual(BusinessCard().displayName, "未命名名片")
        XCTAssertEqual(BusinessCard(name: "David Chen").displayName, "David Chen")
        XCTAssertEqual(BusinessCard(name: "  ").displayName, "未命名名片")
    }

    func testPrimaryPhoneAndEmail() {
        let card = BusinessCard(mobiles: ["13800138000"], phones: ["021-12345678"], emails: ["a@b.com", "c@d.com"])
        XCTAssertEqual(card.primaryPhone, "13800138000")
        XCTAssertEqual(card.primaryEmail, "a@b.com")
    }

    func testSubtitleComposition() {
        let card = BusinessCard(company: "ABC University", jobTitle: "Professor")
        XCTAssertEqual(card.subtitle, "Professor · ABC University")
    }

    func testJSONRoundTrip() throws {
        let card = BusinessCard(name: "David Chen", tags: ["Conference"], notes: "note")
        let data = try JSONEncoder().encode(card)
        let decoded = try JSONDecoder().decode(BusinessCard.self, from: data)
        XCTAssertEqual(card, decoded)
    }
}
