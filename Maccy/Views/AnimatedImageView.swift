import AppKit
import ImageIO
import SwiftUI

/// Plays a GIF or APNG, which SwiftUI's Image shows as a still of the first frame.
struct AnimatedImageView: NSViewRepresentable {
  let data: Data
  /// The first frame at the size to show, used until the animation starts.
  let still: NSImage

  func makeNSView(context: Context) -> AnimatedImageNSView {
    AnimatedImageNSView(data: data, still: still)
  }

  func updateNSView(_ nsView: AnimatedImageNSView, context: Context) {}

  static func dismantleNSView(_ nsView: AnimatedImageNSView, coordinator: ()) {
    nsView.stop()
  }
}

final class AnimatedImageNSView: NSView {
  private let size: NSSize
  private var isStopped = false

  init(data: Data, still: NSImage) {
    size = still.size
    super.init(frame: NSRect(origin: .zero, size: size))
    wantsLayer = true
    layer?.contentsGravity = .resizeAspect
    layer?.contents = still

    // ImageIO calls the block on the main queue as each frame is due, until told to stop.
    // Formats it can't animate keep showing the still.
    CGAnimateImageDataWithBlock(data as CFData, nil) { [weak self] _, frame, stop in
      guard let self, !self.isStopped else {
        stop.pointee = true
        return
      }
      self.layer?.contents = frame
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: NSSize { size }

  func stop() {
    isStopped = true
  }
}
