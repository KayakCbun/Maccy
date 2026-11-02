import Defaults
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator

  @Environment(AppState.self) private var appState

  var body: some View {
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
}
