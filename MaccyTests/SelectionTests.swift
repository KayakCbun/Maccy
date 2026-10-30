import XCTest
import Observation
@testable import Maccy

@MainActor
class SelectionTests: XCTestCase {
  let history = History.shared
  let appState = AppState.shared

  override func setUp() {
    super.setUp()
    removeEverything()
  }

  override func tearDown() {
    super.tearDown()
    appState.selectWithoutScrolling(nil)
    removeEverything()
  }

  // Hover selects the row under the mouse again after layout. That must not change anything,
  // or it starts another layout pass and the main thread never rests.
  func testSelectingTheSelectedItemAgainChangesNothing() {
    let item = history.add(historyItem("foo"))
    appState.selectWithoutScrolling(item.id)
    XCTAssertTrue(item.isSelected)

    let changed = Flag()
    withObservationTracking {
      _ = history.selectedItem
      _ = item.isSelected
      _ = item.showPreview
    } onChange: {
      changed.value = true
    }
    appState.selectWithoutScrolling(item.id)

    XCTAssertFalse(changed.value)
    XCTAssertTrue(item.isSelected)
    XCTAssertEqual(history.selectedItem, item)
  }

  func testSelectingAnotherItem() {
    let first = history.add(historyItem("foo"))
    let second = history.add(historyItem("bar"))
    appState.selectWithoutScrolling(first.id)
    appState.selectWithoutScrolling(second.id)

    XCTAssertFalse(first.isSelected)
    XCTAssertTrue(second.isSelected)
    XCTAssertEqual(history.selectedItem, second)
  }

  func testSelectingNothing() {
    let item = history.add(historyItem("foo"))
    appState.selectWithoutScrolling(item.id)
    appState.selectWithoutScrolling(nil)

    XCTAssertFalse(item.isSelected)
    XCTAssertNil(history.selectedItem)
  }

  private final class Flag {
    var value = false
  }

  private func removeEverything() {
    history.clearAll()
    history.all.forEach { history.delete($0) }
  }

  private func historyItem(_ value: String) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(type: NSPasteboard.PasteboardType.string.rawValue, value: value.data(using: .utf8))
    ]
    item.title = item.generateTitle()

    return item
  }
}
