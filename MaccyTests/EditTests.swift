import XCTest
import Defaults
@testable import Maccy

@MainActor
class EditTests: XCTestCase {
  let savedSize = Defaults[.size]
  let history = History.shared

  override func setUp() {
    super.setUp()
    removeEverything()
    Defaults[.size] = 10
  }

  override func tearDown() {
    super.tearDown()
    removeEverything()
    Defaults[.size] = savedSize
  }

  func testEditingChangesTheContent() {
    let item = history.add(historyItem("foo"))
    history.startEditing(item)

    XCTAssertEqual(history.editedItem, item)
    XCTAssertEqual(history.edit, .content)
    XCTAssertEqual(history.editingText, "foo")

    history.editingText = "bar\nbaz"
    history.saveEdit()

    XCTAssertNil(history.editedItem)
    XCTAssertEqual(item.item.text, "bar\nbaz")
    XCTAssertEqual(item.title, item.item.title)
  }

  func testEmptyContentDeletesTheItem() {
    let item = history.add(historyItem("foo"))
    history.startEditing(item)
    history.editingText = ""
    history.saveEdit()

    XCTAssertEqual(history.all, [])
  }

  // Editing used to stay switched on when its field never showed up, which blocked renaming
  // and every key in the popup until Maccy restarted.
  func testCancellingLeavesNothingOpen() {
    let foo = history.add(historyItem("foo"))
    let bar = history.add(historyItem("bar"))
    history.startEditing(foo)
    history.startRenaming(bar)

    XCTAssertEqual(history.editedItem, foo)
    XCTAssertEqual(history.edit, .content)

    history.editingText = "changed"
    history.cancelEdit()

    XCTAssertFalse(history.isEditingItem)
    XCTAssertEqual(foo.item.text, "foo")

    history.startRenaming(bar)

    XCTAssertEqual(history.editedItem, bar)
    XCTAssertEqual(history.edit, .name)
  }

  func testNewItemIsKeptOnlyWhenSaved() {
    history.addNew()

    XCTAssertEqual(history.edit, .newItem)
    XCTAssertEqual(history.all.count, 1)

    history.cancelEdit()

    XCTAssertEqual(history.all, [])

    history.addNew()
    history.editingText = "note"
    history.saveEdit()

    XCTAssertEqual(history.all.map(\.title), ["note"])
    XCTAssertEqual(history.all.first?.item.text, "note")
  }

  func testOpeningTheEditorClosesThePreview() {
    let item = history.add(historyItem("foo"))
    item.showPreview = true
    history.startRenaming(item)

    XCTAssertFalse(item.showPreview)
  }

  private func removeEverything() {
    history.cancelEdit()
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
