import XCTest
import CardCore

final class BusinessCardRepositoryTests: XCTestCase {
    private var tempDirectory: URL!
    private var fileURL: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        fileURL = tempDirectory.appendingPathComponent("cards.json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private func makeRepository() throws -> BusinessCardRepository {
        try BusinessCardRepository(store: JSONFileCardStore(fileURL: fileURL))
    }

    private func sampleCard(name: String = "David Chen",
                            company: String = "ABC University",
                            tags: [String] = []) -> BusinessCard {
        BusinessCard(name: name,
                     company: company,
                     jobTitle: "Professor",
                     mobiles: ["+86 138 0013 8000"],
                     phones: ["021-12345678"],
                     emails: ["david@abc.edu"],
                     tags: tags)
    }

    // T18：保存后重新加载仍在
    func testAddPersistsAcrossReload() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard())
        XCTAssertEqual(repository.cards.count, 1)

        let reloaded = try makeRepository()
        XCTAssertEqual(reloaded.cards.count, 1)
        XCTAssertEqual(reloaded.cards.first?.name, "David Chen")
        XCTAssertEqual(reloaded.cards.first?.mobiles, ["+86 138 0013 8000"])
    }

    // T14：编辑后持久化
    func testUpdatePersists() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard())
        var card = try XCTUnwrap(repository.cards.first)
        card.company = "XYZ Technologies"
        card.notes = "Follow up next week"
        try repository.update(card)

        let reloaded = try makeRepository()
        XCTAssertEqual(reloaded.cards.first?.company, "XYZ Technologies")
        XCTAssertEqual(reloaded.cards.first?.notes, "Follow up next week")
    }

    // T17：删除后列表消失且持久化
    func testDeleteRemovesCard() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard(name: "A"))
        try repository.add(sampleCard(name: "B"))
        let first = try XCTUnwrap(repository.cards.first)
        try repository.delete(id: first.id)

        XCTAssertEqual(repository.cards.count, 1)
        let reloaded = try makeRepository()
        XCTAssertEqual(reloaded.cards.count, 1)
        XCTAssertNotEqual(reloaded.cards.first?.id, first.id)
    }

    // T15：按姓名搜索
    func testSearchByName() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard(name: "David Chen"))
        try repository.add(sampleCard(name: "Alice Wang"))

        XCTAssertEqual(repository.search("Alice").count, 1)
        XCTAssertEqual(repository.search("David Chen").first?.name, "David Chen")
        XCTAssertTrue(repository.search("nobody").isEmpty)
    }

    // T15：按公司搜索
    func testSearchByCompany() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard(name: "David Chen", company: "ABC University"))
        try repository.add(sampleCard(name: "Alice Wang", company: "XYZ Technologies"))

        XCTAssertEqual(repository.search("University").count, 1)
        XCTAssertEqual(repository.search("Technologies").count, 1)
    }

    // T15：按电话数字搜索（忽略空格/横线）
    func testSearchByPhoneDigits() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard())

        XCTAssertEqual(repository.search("13800138000").count, 1)
        XCTAssertEqual(repository.search("021-12345678").count, 1)
    }

    // T15：按邮箱搜索
    func testSearchByEmail() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard())

        XCTAssertEqual(repository.search("david@abc.edu").count, 1)
        XCTAssertEqual(repository.search("abc.edu").count, 1)
    }

    // T16：标签筛选与删除标签
    func testTagFilterAndDeleteTag() throws {
        let repository = try makeRepository()
        try repository.add(sampleCard(name: "David Chen", tags: ["Conference", "Professor"]))
        try repository.add(sampleCard(name: "Alice Wang", tags: ["Company"]))

        XCTAssertEqual(repository.allTags, ["Company", "Conference", "Professor"])
        XCTAssertEqual(repository.search("", tag: "Conference").count, 1)

        try repository.deleteTag("Conference")
        XCTAssertFalse(repository.allTags.contains("Conference"))
        XCTAssertFalse(try XCTUnwrap(repository.cards.first(where: { $0.name == "David Chen" })).tags.contains("Conference"))
        XCTAssertEqual(repository.search("", tag: "Conference").count, 0)
    }

    // T11/T14：更新不存在的名片应报错
    func testUpdateUnknownCardThrows() throws {
        let repository = try makeRepository()
        XCTAssertThrowsError(try repository.update(BusinessCard(name: "Ghost"))) { error in
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }

    // 空仓库搜索
    func testSearchOnEmptyRepository() throws {
        let repository = try makeRepository()
        XCTAssertTrue(repository.search("anything").isEmpty)
        XCTAssertTrue(repository.allTags.isEmpty)
    }
}
