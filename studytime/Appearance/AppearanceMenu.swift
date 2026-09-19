import SwiftUI

/// A palette button in the window's corner that tucks the theme swatches
/// away in a popover, so the window shows the clock and nothing else until
/// appearance is being changed.
///
/// A popover rather than a `Menu`: an AppKit menu can only hold menu items, so
/// the swatch grid — and its hover caption — would not survive in one.
struct AppearanceMenu: View {
    @Binding var selection: BackgroundTheme

    @State private var isPresented = false

    var body: some View {
        CornerIconButton(
            systemImage: "paintpalette",
            title: "Appearance",
            theme: selection,
            isActive: isPresented
        ) {
            isPresented = true
        }
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            // No theme colours here: the popover keeps the system appearance
            // so the swatches are judged against a neutral ground.
            BackgroundThemePicker(selection: $selection)
                .padding(16)
        }
    }
}

#Preview {
    @Previewable @State var selection = BackgroundTheme.ocean
    return AppearanceMenu(selection: $selection)
        .padding()
        .background(BackgroundTheme.ocean.background)
}
