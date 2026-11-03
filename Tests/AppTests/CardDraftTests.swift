import XCTest
import CardCore
@testable import CamCardReplica

final class CardDraftTests: XCTestCase {
    func testDraftFromParsedFields() {
        var fields = ParsedFields()
        fields.name = "David Chen"
        fields.company = "ABC University"
        fields.jobTitle = "Professor"
        fields.mobiles = ["+86 138 0013 8000"]
        fields.phones = ["021-12345678"]
        fields.emails = ["david@abc.edu"]
        fields.website = "www.abc.edu"
        fields.address = "上海市杨浦区四平路1239号"

        let draft = CardDraft(fields: fields)
        XCTAssertEqual(draft.name, "David Chen")
        XCTAssertEqual(draft.mobiles, "+86 138 0013 8000")
        XCTAssertEqual(draft.emails, "david@abc.edu")
        XCTAssertEqual(draft.address, "上海市杨浦区四平路1239号")
    }

    func testDraftSplitsMultipleValues() {
        var draft = CardDraft()
        draft.name = "David Chen"
        draft.mobiles = "13800138000\n13900139000"
        draft.emails = "a@b.com, c@d.com"
        draft.tags = "Conference, Professor；客户"
        let card = draft.toCard()
        XCTAssertEqual(card.mobiles, ["13800138000", "13900139000"])
        XCTAssertEqual(card.emails, ["a@b.com", "c@d.com"])
        XCTAssertEqual(card.tags, ["Conference", "Professor", "客户"])
    }

    func testApplyPreservesIdentityAndImages() {
        var original = BusinessCard(name: "Old Name", company: "Old Co")
        original.rawOCRText = "raw ocr text"
        original.originalImageFileName = "orig.jpg"
        original.processedImageFileName = "proc.jpg"

        var draft = CardDraft(card: original)
        draft.name = "New Name"
        draft.company = "New Co"
        draft.tags = "Customer"
        let updated = draft.apply(to: original)

        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.name, "New Name")
        XCTAssertEqual(updated.company, "New Co")
        XCTAssertEqual(updated.tags, ["Customer"])
        XCTAssertEqual(updated.rawOCRText, "raw ocr text")
        XCTAssertEqual(updated.originalImageFileName, "orig.jpg")
        XCTAssertEqual(updated.processedImageFileName, "proc.jpg")
    }

    func testEmptyDraftCreatesEmptyCard() {
        let card = CardDraft().toCard()
        XCTAssertEqual(card.name, "")
        XCTAssertEqual(card.displayName, "未命名名片")
        XCTAssertTrue(card.mobiles.isEmpty)
    }
}
