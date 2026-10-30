import Defaults
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator

  @Environment(AppState.self) private var appState
  @FocusState private var editFocused: Bool

  var body: some View {
    if item.isEditing || item.isRenaming {
      editingView
    } else {
      normalView
    }
  }

  private var normalView: some View {
    ListItemView(
      id: item.id,
      appIcon: item.applicationImage,
      image: item.thumbnailImage,
      imageBadge: item.thumbnailBadge,
      showsTitleWithImage: item.item.customTitle != nil,
      accessoryImage: item.thumbnailImage != nil ? nil : ColorImage.from(item.item.title),
      attributedTitle: item.attributedTitle,
      marker: item.isArchived ? "archivebox" : nil,
      shortcuts: item.shortcuts,
      isSelected: item.isSelected
    ) {
      HStack(spacing: 6) {
        Text(verbatim: item.title)
        // What a renamed item holds, for telling apart items with similar names.
        if item.thumbnailImage == nil, let originalTitle = item.originalTitle {
          Text(verbatim: originalTitle)
            .foregroundStyle(.secondary)
            .layoutPriority(-1)
        }
      }
    }
    .onAppear {
      item.ensureThumbnailImage()
    }
    .onTapGesture {
      appState.history.select(item)
    }
    .popover(isPresented: $item.showPreview, arrowEdge: .trailing) {
      PreviewItemView(item: item)
        .onAppear {
          item.ensurePreviewImage()
        }
    }
    .contextMenu {
      if item.item.text != nil {
        Button {
          appState.history.startEditing(item)
        } label: {
          Text("edit")
        }
      }

      Button {
        appState.history.startRenaming(item)
      } label: {
        Text("rename")
      }

      Button {
        appState.history.toggleArchive(item)
      } label: {
        Text(item.isArchived ? "unarchive" : "archive")
      }

      Button {
        appState.history.togglePin(item)
      } label: {
        Text(item.isPinned ? "unpin" : "pin")
      }

      Button {
        appState.history.delete(item)
      } label: {
        Text("delete")
      }
    }
  }

  private var editingView: some View {
    HStack(spacing: 0) {
      Spacer().frame(width: 10)
      if item.isRenaming {
        TextField(NSLocalizedString("rename_placeholder", comment: ""), text: $item.editingText)
          .textFieldStyle(.plain)
          .lineLimit(1)
          .accessibilityIdentifier("edit-field")
          .focused($editFocused)
          .onAppear(perform: focus)
          .onSubmit(save)
          .onExitCommand(perform: cancel)
      } else {
        TextField("", text: $item.editingText, axis: .vertical)
          .textFieldStyle(.plain)
          .lineLimit(1...5)
          .accessibilityIdentifier("edit-field")
          .focused($editFocused)
          .onAppear(perform: focus)
          .onSubmit(save)
          .onExitCommand(perform: cancel)
      }
      Spacer().frame(width: 4)
      Button(action: save) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      }
      .buttonStyle(.plain)
      .padding(.trailing, 4)
      Button(action: cancel) {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .padding(.trailing, 8)
    }
    .frame(minHeight: Popup.itemHeight)
    .id(item.id)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.accentColor.opacity(0.15))
    .clipShape(.rect(cornerRadius: Popup.cornerRadius))
  }

  // Focus set in onAppear is lost, as the field isn't in the window yet.
  private func focus() {
    DispatchQueue.main.async {
      editFocused = true
    }
  }

  private func save() {
    if item.isRenaming {
      appState.history.saveRenaming(item)
    } else {
      appState.history.saveEditing(item)
    }
  }

  private func cancel() {
    if item.isRenaming {
      appState.history.cancelRenaming(item)
    } else {
      appState.history.cancelEditing(item)
    }
  }
}
