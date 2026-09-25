import SwiftUI
import UniformTypeIdentifiers

/// A palette button in the window's corner that tucks the theme swatches and
/// the background image away in a popover, so the window shows the clock and
/// nothing else until appearance is being changed.
///
/// A popover rather than a `Menu`: an AppKit menu can only hold menu items, so
/// the swatch grid — and its hover caption — would not survive in one.
struct AppearanceMenu: View {
    @Bindable var appearance: AppearanceSettings

    @State private var isPresented = false
    /// Set when "Choose Image…" is clicked. The file dialog waits for the
    /// popover to finish closing, rather than competing with it.
    @State private var choosesImageOnClose = false
    @State private var isChoosingImage = false
    @State private var failure: String?

    var body: some View {
        CornerIconButton(
            systemImage: "paintpalette",
            title: "Appearance",
            theme: appearance.theme,
            isActive: isPresented
        ) {
            isPresented = true
        }
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            // No theme colours here: the popover keeps the system appearance
            // so the swatches are judged against a neutral ground.
            VStack(spacing: 12) {
                BackgroundThemePicker(selection: $appearance.theme)

                Divider()

                BackgroundImageControls(image: appearance.backgroundImage) {
                    choosesImageOnClose = true
                    isPresented = false
                } onRemove: {
                    appearance.removeBackgroundImage()
                }
            }
            .padding(16)
        }
        .onChange(of: isPresented) { _, isPresented in
            if !isPresented, choosesImageOnClose {
                choosesImageOnClose = false
                isChoosingImage = true
            }
        }
        .fileImporter(isPresented: $isChoosingImage, allowedContentTypes: [.image]) { result in
            do {
                try appearance.setBackgroundImage(from: result.get())
            } catch {
                failure = error.localizedDescription
            }
        }
        .alert("Couldn't Use Image", isPresented: isFailing, presenting: failure) { _ in
            Button("OK") {}
        } message: { failure in
            Text(failure)
        }
    }

    private var isFailing: Binding<Bool> {
        Binding(
            get: { failure != nil },
            set: { if !$0 { failure = nil } }
        )
    }
}

/// The background image row under the swatches: a thumbnail of the current
/// image, and buttons to choose another or go back to the plain theme.
private struct BackgroundImageControls: View {
    let image: NSImage?
    let onChoose: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Button(image == nil ? "Choose Image…" : "Change…", action: onChoose)
                    if image != nil {
                        Button("Remove", action: onRemove)
                    }
                }
                .controlSize(.small)

                Text(image == nil ? "Background image" : "Tinted by the theme")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Color.secondary.opacity(0.15))
            .overlay {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 48, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    AppearanceMenu(appearance: AppearanceSettings())
        .padding()
        .background(BackgroundTheme.ocean.background)
}
