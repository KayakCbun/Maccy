import SwiftUI

/// Edits an item's content or name, covering the list.
///
/// It lives in the popup itself: the popup takes the keyboard while another app stays active,
/// which alerts and sheets don't, and rows of the list never switched into a field.
struct ItemEditorView: View {
  @Environment(AppState.self) private var appState
  @FocusState private var focused: Bool

  var body: some View {
    @Bindable var history = appState.history

    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)

      if history.edit == .name {
        TextField("rename_placeholder", text: $history.editingText)
          .accessibilityIdentifier("edit-field")
          .focused($focused)
          .onSubmit { history.saveEdit() }
      } else {
        // ↩ saves, ⌥↩ starts a new line.
        TextField("", text: $history.editingText, axis: .vertical)
          .lineLimit(3...12)
          .accessibilityIdentifier("edit-content-field")
          .focused($focused)
          .onSubmit { history.saveEdit() }
      }

      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      HStack {
        Spacer()
        Button("rename_cancel") {
          history.cancelEdit()
        }
        Button("rename_save") {
          history.saveEdit()
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .textFieldStyle(.roundedBorder)
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(nsColor: .windowBackgroundColor))
    .clipShape(.rect(cornerRadius: Popup.cornerRadius + Popup.horizontalPadding))
    .defaultFocus($focused, true)
    .onAppear {
      // Focus asked for while the editor is still being added to the window doesn't stick.
      DispatchQueue.main.async {
        focused = true
      }
    }
    .onExitCommand {
      history.cancelEdit()
    }
  }

  private var title: LocalizedStringKey {
    switch appState.history.edit {
    case .content: "edit_title"
    case .newItem: "add_new"
    case .name: "rename_title"
    }
  }

  private var message: LocalizedStringKey {
    appState.history.edit == .name ? "rename_message" : "edit_message"
  }
}
