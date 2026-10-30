import KeyboardShortcuts
import SwiftUI

struct PreviewItemView: View {
  weak var item: HistoryItemDecorator?

  var body: some View {
    if let item = item {
      VStack(alignment: .leading, spacing: 0) {
        if let customTitle = item.item.customTitle {
          Text(verbatim: customTitle)
            .font(.headline)
            .padding(.bottom, 8)
        }

        if let image = item.previewImage, let animatedData = item.animatedPreviewData {
          AnimatedImageView(data: animatedData, still: image)
            .frame(width: image.size.width, height: image.size.height)
            .clipShape(.rect(cornerRadius: 5))
        } else if let image = item.previewImage {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(.rect(cornerRadius: 5))
        } else {
          ScrollView {
            WrappingTextView {
              Text(item.text)
                .font(.body)
            }
          }
        }

        Divider()
          .padding(.vertical)

        if let application = item.application {
          HStack(spacing: 3) {
            Text("Application", tableName: "PreviewItemView")
            Image(nsImage: item.applicationImage.nsImage)
              .resizable()
              .frame(width: 11, height: 11)
            Text(application)
          }
        }

        HStack(spacing: 3) {
          Text("FirstCopyTime", tableName: "PreviewItemView")
          Text(item.item.firstCopiedAt, style: .date)
          Text(item.item.firstCopiedAt, style: .time)
        }

        HStack(spacing: 3) {
          Text("LastCopyTime", tableName: "PreviewItemView")
          Text(item.item.lastCopiedAt, style: .date)
          Text(item.item.lastCopiedAt, style: .time)
        }

        if let archivedAt = item.item.archivedAt {
          HStack(spacing: 3) {
            Text("ArchivedTime", tableName: "PreviewItemView")
            Text(archivedAt, style: .date)
            Text(archivedAt, style: .time)
          }
        }

        HStack(spacing: 3) {
          Text("NumberOfCopies", tableName: "PreviewItemView")
          Text(String(item.item.numberOfCopies))
        }
        .padding(.bottom)

        if let pinKey = KeyboardShortcuts.Shortcut(name: .pin) {
          Text(
            NSLocalizedString("PinKey", tableName: "PreviewItemView", comment: "")
              .replacingOccurrences(of: "{pinKey}", with: pinKey.description)
          )
        }

        if let archiveKey = KeyboardShortcuts.Shortcut(name: .archive) {
          Text(
            NSLocalizedString("ArchiveKey", tableName: "PreviewItemView", comment: "")
              .replacingOccurrences(of: "{archiveKey}", with: archiveKey.description)
          )
        }

        if let deleteKey = KeyboardShortcuts.Shortcut(name: .delete) {
          Text(
            NSLocalizedString("DeleteKey", tableName: "PreviewItemView", comment: "")
              .replacingOccurrences(of: "{deleteKey}", with: deleteKey.description)
          )
        }
      }
      .controlSize(.small)
      .padding()
    }
  }
}
