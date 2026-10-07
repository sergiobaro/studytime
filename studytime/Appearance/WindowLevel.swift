import AppKit
import SwiftUI

extension View {
    /// Keeps the window this view is in above other apps' windows while
    /// `isFloating` is true.
    func windowFloating(_ isFloating: Bool) -> some View {
        background(WindowLevelSetter(isFloating: isFloating))
    }
}

/// An empty view that reaches up to its window to set the window's level.
/// SwiftUI's own `windowLevel` is fixed per scene, so it can't be toggled.
private struct WindowLevelSetter: NSViewRepresentable {
    let isFloating: Bool

    func makeNSView(context: Context) -> WindowLevelView {
        WindowLevelView()
    }

    func updateNSView(_ nsView: WindowLevelView, context: Context) {
        nsView.isFloating = isFloating
    }

    final class WindowLevelView: NSView {
        var isFloating = false {
            didSet { applyLevel() }
        }

        // The view has no window yet when it is first made, so the level is
        // applied again once it lands in one.
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyLevel()
        }

        private func applyLevel() {
            window?.level = isFloating ? .floating : .normal
        }
    }
}
