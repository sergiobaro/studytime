import SwiftUI

/// What the timer window is painted with: the theme's colour, and over it the
/// background image, if there is one, tinted by the theme's scrim.
struct WindowBackground: View {
    let theme: BackgroundTheme
    let image: NSImage?

    var body: some View {
        ZStack {
            theme.background

            if let image {
                // Filling an overlay on a clear view crops the image to the
                // window, rather than letting its size stretch the layout.
                Color.clear
                    .overlay {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()

                theme.imageScrim.opacity(BackgroundTheme.imageScrimOpacity)
            }
        }
        .accessibilityHidden(true)
    }
}
