import XCTest
import CardCore

final class FieldParserTests: XCTestCase {
    private let parser = FieldParser()

    private func block(_ text: String, y: Double) -> OCRTextBlock {
        OCRTextBlock(text: text, confidence: 0.9, boundingBox: NormalizedRect(x: 0.1, y: y, width: 0.8, height: 0.06))
    }

    private func blocks(_ entries: [(String, Double)]) -> [OCRTextBlock] {
        entries.map { block($0.0, y: $0.1) }
    }

    // T08：标准英文名片
    func testStandardEnglishCardExtractsAllFields() {
        let result = parser.parse(blocks([
            ("Dr. David Chen", 0.86),
            ("Professor", 0.74),
            ("School of Computer Science", 0.64),
            ("ABC University", 0.54),
            ("Mobile: +86 138 0013 8000", 0.40),
            ("Email: david@abc.edu", 0.30),
            ("Website: www.abc.edu", 0.20)
        ]))

        XCTAssertEqual(result.name, "David Chen")
        XCTAssertEqual(result.jobTitle, "Professor")
        XCTAssertEqual(result.company, "ABC University")
        XCTAssertEqual(result.mobiles, ["+86 138 0013 8000"])
        XCTAssertEqual(result.emails, ["david@abc.edu"])
        XCTAssertEqual(result.website, "www.abc.edu")
    }

    // T09：不存在 Website 时不得虚构
    func testMissingWebsiteIsNotHallucinated() {
        let result = parser.parse(blocks([
            ("Alice Wang", 0.80),
            ("XYZ Technologies", 0.62),
            ("Mobile: 13900139000", 0.40)
        ]))

        XCTAssertEqual(result.name, "Alice Wang")
        XCTAssertEqual(result.company, "XYZ Technologies")
        XCTAssertNil(result.website)
        XCTAssertTrue(result.emails.isEmpty)
    }

    // T09：只有一个孤立单词时不应猜出任何字段
    func testAmbiguousSingleWordProducesNoFields() {
        let result = parser.parse(blocks([("Apple", 0.5)]))
        XCTAssertTrue(result.isEmpty)
    }

    // T10：多电话分类 Mobile / Office / Fax
    func testMultiplePhonesAreClassified() {
        let result = parser.parse(blocks([
            ("David Chen", 0.82),
            ("Mobile: +86 138 0013 8000", 0.62),
            ("Office: 021-12345678", 0.50),
            ("Fax: 021-87654321", 0.38)
        ]))

        XCTAssertEqual(result.mobiles, ["+86 138 0013 8000"])
        XCTAssertEqual(result.phones, ["021-12345678"])
        XCTAssertEqual(result.faxes, ["021-87654321"])
    }

    // 人名与公司混淆
    func testNameIsNotConfusedWithCompany() {
        let result = parser.parse(blocks([
            ("Jordan Lee", 0.82),
            ("Lee Consulting", 0.62)
        ]))

        XCTAssertEqual(result.name, "Jordan Lee")
        XCTAssertEqual(result.company, "Lee Consulting")
    }

    // 中英混排
    func testChineseBilingualCard() {
        let result = parser.parse(blocks([
            ("朱宏明", 0.86),
            ("Professor", 0.70),
            ("Tongji University", 0.58)
        ]))

        XCTAssertEqual(result.name, "朱宏明")
        XCTAssertEqual(result.jobTitle, "Professor")
        XCTAssertEqual(result.company, "Tongji University")
    }

    // 称谓剥离
    func testHonorificIsStrippedFromName() {
        let result = parser.parse(blocks([("Dr. David Chen", 0.8)]))
        XCTAssertEqual(result.name, "David Chen")
    }

    // 多邮箱
    func testMultipleEmails() {
        let result = parser.parse(blocks([
            ("David Chen", 0.8),
            ("Email: david@abc.edu; david.chen@gmail.com", 0.6)
        ]))

        XCTAssertEqual(Set(result.emails), Set(["david@abc.edu", "david.chen@gmail.com"]))
    }

    // 地址
    func testAddressExtraction() {
        let result = parser.parse(blocks([
            ("ABC University", 0.82),
            ("地址：上海市杨浦区四平路1239号", 0.60)
        ]))

        XCTAssertEqual(result.address, "上海市杨浦区四平路1239号")
        XCTAssertEqual(result.company, "ABC University")
    }

    // 空输入
    func testEmptyInputProducesEmptyFields() {
        XCTAssertTrue(parser.parse([]).isEmpty)
    }

    // 无标签手机号
    func testUnlabelledMobileNumberIsClassifiedAsMobile() {
        let result = parser.parse(blocks([
            ("David Chen", 0.8),
            ("13800138000", 0.6)
        ]))

        XCTAssertEqual(result.mobiles, ["13800138000"])
        XCTAssertTrue(result.phones.isEmpty)
    }

    // 纯文本入口
    func testRawTextEntryPoint() {
        let result = parser.parse(rawText: "David Chen\nProfessor\nABC University\nMobile: 13800138000")
        XCTAssertEqual(result.name, "David Chen")
        XCTAssertEqual(result.jobTitle, "Professor")
        XCTAssertEqual(result.company, "ABC University")
        XCTAssertEqual(result.mobiles, ["13800138000"])
    }
}
