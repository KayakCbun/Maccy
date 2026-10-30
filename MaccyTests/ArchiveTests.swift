import XCTest
import Defaults
import SwiftData
@testable import Maccy

@MainActor
class ArchiveTests: XCTestCase {
  let savedSize = Defaults[.size]
  let savedSortBy = Defaults[.sortBy]
  let savedSearchMode = Defaults[.searchMode]
  let history = History.shared

  override func setUp() {
    super.setUp()
    removeEverything()
    Defaults[.size] = 2
    Defaults[.sortBy] = .firstCopiedAt
    Defaults[.searchMode] = .exact
  }

  override func tearDown() {
    super.tearDown()
    removeEverything()
    Defaults[.size] = savedSize
    Defaults[.sortBy] = savedSortBy
    Defaults[.searchMode] = savedSearchMode
  }

  func testArchivedItemsAreKeptOverTheSizeLimit() {
    let archived = history.add(historyItem("archived"))
    history.toggleArchive(archived)
    history.add(historyItem("first"))
    history.add(historyItem("second"))
    history.add(historyItem("third"))

    XCTAssertEqual(history.all.map(\.title), ["third", "second", "archived"])
    XCTAssertTrue(archived.isArchived)
  }

  func testUnarchiving() {
    let item = history.add(historyItem("foo"))
    history.toggleArchive(item)
    history.toggleArchive(item)

    XCTAssertFalse(item.isArchived)
    XCTAssertNil(storedItem("foo")?.archivedAt)
  }

  func testClearKeepsPinnedAndArchivedItems() {
    let archived = history.add(historyItem("archived"))
    history.toggleArchive(archived)
    let pinned = history.add(historyItem("pinned"))
    history.togglePin(pinned)
    history.add(historyItem("plain"))

    history.clear()

    XCTAssertEqual(Set(history.all.map(\.title)), ["archived", "pinned"])
    XCTAssertEqual(Set(storedItems().map(\.title)), ["archived", "pinned"])
    XCTAssertEqual(storedItem("archived")?.text, "archived")
  }

  func testClearAllKeepsArchivedItems() {
    let archived = history.add(historyItem("archived"))
    history.toggleArchive(archived)
    let pinned = history.add(historyItem("pinned"))
    history.togglePin(pinned)
    history.add(historyItem("plain"))

    history.clearAll()

    XCTAssertEqual(history.all.map(\.title), ["archived"])
    XCTAssertEqual(storedItems().map(\.title), ["archived"])
    XCTAssertEqual(storedItem("archived")?.text, "archived")
  }

  func testRenamingArchivesAndKeepsTheContentSearchable() {
    let item = history.add(historyItem("ssh deploy@10.0.0.1"))
    history.startRenaming(item)
    item.editingText = "  staging server  "
    history.saveRenaming(item)

    XCTAssertTrue(item.isArchived)
    XCTAssertEqual(item.title, "staging server")
    XCTAssertEqual(item.originalTitle, "ssh deploy@10.0.0.1")
    XCTAssertEqual(storedItem("ssh deploy@10.0.0.1")?.customTitle, "staging server")
    XCTAssertEqual(search("staging"), [item])
    XCTAssertEqual(search("10.0.0"), [item])
    XCTAssertEqual(search("nothing"), [])
  }

  func testEmptyNameBringsBackTheTitle() {
    let item = history.add(historyItem("foo"))
    history.startRenaming(item)
    item.editingText = "bar"
    history.saveRenaming(item)
    history.startRenaming(item)
    XCTAssertEqual(item.editingText, "bar")
    item.editingText = " "
    history.saveRenaming(item)

    XCTAssertEqual(item.title, "foo")
    XCTAssertNil(item.item.customTitle)
    XCTAssertNil(item.originalTitle)
    XCTAssertTrue(item.isArchived)
  }

  func testNameDropsObjectReplacementCharacters() {
    let item = history.add(historyItem("foo"))
    history.startRenaming(item)
    item.editingText = "\u{FFFC}服务器\u{FFFC}地址"
    history.saveRenaming(item)

    XCTAssertEqual(item.item.customTitle, "服务器地址")
  }

  func testCancellingRenameKeepsTheTitle() {
    let item = history.add(historyItem("foo"))
    history.startRenaming(item)
    item.editingText = "bar"
    history.cancelRenaming(item)

    XCTAssertFalse(item.isRenaming)
    XCTAssertEqual(item.title, "foo")
    XCTAssertFalse(item.isArchived)
  }

  func testCopyingAgainKeepsArchiveAndName() {
    let first = history.add(historyItem("foo"))
    history.startRenaming(first)
    first.editingText = "bar"
    history.saveRenaming(first)

    let second = history.add(historyItem("foo"))

    XCTAssertEqual(history.all, [second])
    XCTAssertTrue(second.isArchived)
    XCTAssertEqual(second.title, "bar")
    XCTAssertEqual(second.originalTitle, "foo")
  }

  private func search(_ query: String) -> [HistoryItemDecorator] {
    Search().search(string: query, within: history.all).map(\.object)
  }

  private func storedItems() -> [HistoryItem] {
    (try? Storage.shared.context.fetch(FetchDescriptor<HistoryItem>())) ?? []
  }

  private func storedItem(_ title: String) -> HistoryItem? {
    storedItems().first { $0.title == title }
  }

  private func removeEverything() {
    history.clearAll()
    history.all.forEach(history.delete)
  }

  private func historyItem(_ value: String) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()

    return item
  }
}
