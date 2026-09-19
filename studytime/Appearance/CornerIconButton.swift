import SwiftUI

/// A bare icon for the window's corner, drawn in the theme's colours. The chip
/// behind it only appears under the pointer, or while whatever it opened is
/// still showing, so the corner stays quiet until it is used.
struct CornerIconButton: View {
    let systemImage: String
    let title: String
    let theme: BackgroundTheme
    /// True while the popover or sheet the button opened is showing.
    var isActive = false
    let action: () -> Void

    @State private var isHovered = false

    static let size: CGFloat = 28

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.foreground.opacity(isHighlighted ? 1 : 0.7))
                .frame(width: Self.size, height: Self.size)
                .background(
                    Circle().fill(theme.foreground.opacity(chipOpacity))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }

    private var isHighlighted: Bool { isHovered || isActive }

    private var chipOpacity: Double {
        if isActive { return 0.22 }
        return isHovered ? 0.12 : 0
    }
}
