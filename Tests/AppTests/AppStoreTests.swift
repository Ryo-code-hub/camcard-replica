import XCTest
import UIKit
import CardCore
@testable import CamCardReplica

@MainActor
final class AppStoreTests: XCTestCase {
    private func makeStore() throws -> AppStore {
        let repository = try BusinessCardRepository(store: InMemoryCardStore())
        return AppStore(repository: repository, imageStore: ImageStore())
    }

    private func card(name: String = "David Chen",
                      company: String = "ABC University",
                      tags: [String] = []) -> BusinessCard {
        BusinessCard(name: name,
                     company: company,
                     jobTitle: "Professor",
                     mobiles: ["13800138000"],
                     emails: ["david@abc.edu"],
                     tags: tags)
    }

    func testAddUpdatesPublishedCards() throws {
        let store = try makeStore()
        XCTAssertTrue(store.cards.isEmpty)

        store.add(card())
        XCTAssertEqual(store.cards.count, 1)
        XCTAssertEqual(store.filteredCards.count, 1)
    }

    func testSearchFiltersList() throws {
        let store = try makeStore()
        store.add(card(name: "David Chen"))
        store.add(card(name: "Alice Wang", company: "XYZ Technologies"))

        store.searchText = "Alice"
        XCTAssertEqual(store.filteredCards.count, 1)
        XCTAssertEqual(store.filteredCards.first?.name, "Alice Wang")

        store.searchText = ""
        XCTAssertEqual(store.filteredCards.count, 2)
    }

    func testDeleteRemovesCard() throws {
        let store = try makeStore()
        store.add(card())
        let target = try XCTUnwrap(store.cards.first)
        store.delete(target)
        XCTAssertTrue(store.cards.isEmpty)
    }

    func testTagFilterAndDeleteTag() throws {
        let store = try makeStore()
        store.add(card(name: "David Chen", tags: ["Conference"]))
        store.add(card(name: "Alice Wang", company: "XYZ Technologies", tags: ["Company"]))

        XCTAssertEqual(store.tags.sorted(), ["Company", "Conference"])

        store.selectedTag = "Conference"
        XCTAssertEqual(store.filteredCards.count, 1)

        store.deleteTag("Conference")
        XCTAssertFalse(store.tags.contains("Conference"))
        XCTAssertNil(store.selectedTag)
        XCTAssertEqual(store.filteredCards.count, 2)
    }

    func testUpdateReflectsInList() throws {
        let store = try makeStore()
        store.add(card())
        var target = try XCTUnwrap(store.cards.first)
        target.company = "XYZ Technologies"
        store.update(target)
        XCTAssertEqual(store.cards.first?.company, "XYZ Technologies")
    }
}
