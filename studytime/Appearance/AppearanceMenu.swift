import SwiftUI

/// A three-dot button in the window's corner that tucks the theme swatches
/// away in a popover, so the window shows the clock and nothing else until
/// appearance is being changed.
///
/// A popover rather than a `Menu`: an AppKit menu can only hold menu items, so
/// the swatch grid — and its hover caption — would not survive in one.
struct AppearanceMenu: View {
    @Binding var selection: BackgroundTheme

    @State private var isPresented = false
    @State private var isHovered = false

    private let buttonSize: CGFloat = 28

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "ellipsis")
                // `ellipsis.vertical` only arrived in a recent SF Symbols
                // release; rotating the plain one draws the same three dots
                // without depending on it.
                .rotationEffect(.degrees(90))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(selection.foreground.opacity(isHighlighted ? 1 : 0.7))
                .frame(width: buttonSize, height: buttonSize)
                // Bare dots at rest; the chip appears under the pointer so the
                // button still reads as one.
                .background(
                    Circle().fill(selection.foreground.opacity(chipOpacity))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Appearance")
        .accessibilityLabel("Appearance")
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            // No theme colours here: the popover keeps the system appearance
            // so the swatches are judged against a neutral ground.
            BackgroundThemePicker(selection: $selection)
                .padding(16)
        }
    }

    private var isHighlighted: Bool { isHovered || isPresented }

    private var chipOpacity: Double {
        if isPresented { return 0.22 }
        return isHovered ? 0.12 : 0
    }
}

#Preview {
    @Previewable @State var selection = BackgroundTheme.ocean
    return AppearanceMenu(selection: $selection)
        .padding()
        .background(BackgroundTheme.ocean.background)
}
