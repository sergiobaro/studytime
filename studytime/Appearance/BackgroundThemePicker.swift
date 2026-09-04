import SwiftUI

/// A grid of colour swatches for choosing the window background, captioned
/// with the name of the theme under the pointer — or the selected one when
/// nothing is hovered.
///
/// Drawn in the system appearance and *not* in the selected theme: the picker
/// is where a theme is being judged, so the only colour that should change as
/// the selection moves is the ring's position. Its own furniture staying put
/// keeps the swatches comparable.
struct BackgroundThemePicker: View {
    @Binding var selection: BackgroundTheme

    @State private var hoveredTheme: BackgroundTheme?

    private let swatchSize: CGFloat = 18
    /// Spacing has to clear the selection ring, which is drawn 4pt outside
    /// the swatch on every side.
    private let spacing: CGFloat = 12
    private let columnCount = 8

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(swatchSize), spacing: spacing),
            count: columnCount
        )
    }

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(BackgroundTheme.allCases) { theme in
                    Button {
                        selection = theme
                    } label: {
                        swatch(for: theme)
                    }
                    .buttonStyle(.plain)
                    .help(theme.title)
                    .accessibilityLabel(theme.title)
                    .accessibilityAddTraits(theme == selection ? [.isSelected] : [])
                    .onHover { isHovering in
                        updateHover(for: theme, isHovering: isHovering)
                    }
                }
            }
            // Room for the ring on the outermost swatches.
            .padding(4)

            caption
        }
        .animation(.easeInOut(duration: 0.15), value: selection)
    }

    private var caption: some View {
        Text(Self.displayedName(hovered: hoveredTheme, selected: selection))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            // Fixed height so the grid does not shift as the name changes.
            .frame(height: 14)
            .animation(.easeInOut(duration: 0.1), value: hoveredTheme)
    }

    /// The name to caption: whatever is hovered, else the current selection.
    static func displayedName(hovered: BackgroundTheme?, selected: BackgroundTheme) -> String {
        (hovered ?? selected).title
    }

    private func updateHover(for theme: BackgroundTheme, isHovering: Bool) {
        if isHovering {
            hoveredTheme = theme
        } else if hoveredTheme == theme {
            // Only clear if this swatch is still the hovered one — leaving a
            // swatch can be reported after entering its neighbour.
            hoveredTheme = nil
        }
    }

    private func swatch(for theme: BackgroundTheme) -> some View {
        Circle()
            .fill(theme.swatch)
            .frame(width: swatchSize, height: swatchSize)
            // A hairline keeps pale swatches visible on a pale background.
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1))
            .overlay {
                // The ring sits outside the swatch, in the system label colour
                // so it reads against the popover in light and dark alike.
                Circle()
                    .stroke(Color.primary, lineWidth: 2)
                    .padding(-4)
                    .opacity(theme == selection ? 1 : 0)
            }
            .contentShape(Circle())
    }
}

#Preview {
    @Previewable @State var selection = BackgroundTheme.ocean
    return BackgroundThemePicker(selection: $selection)
        .padding()
}
