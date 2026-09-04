import SwiftUI

/// A capsule button drawn from the same palette as `ThemedSegmentedPicker`:
/// `prominent` fills with the theme's accent the way a selected segment does,
/// and the rest take the picker's track fill.
///
/// System button styles are drawn by AppKit against the system appearance, so
/// like the picker and the stepper this has to be drawn by hand to follow the
/// window's theme.
struct ThemedButtonStyle: ButtonStyle {
    let theme: BackgroundTheme
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, theme: theme, prominent: prominent)
    }

    /// A nested view so the style can read `isEnabled`, which is only
    /// available from the environment.
    private struct Face: View {
        let configuration: Configuration
        let theme: BackgroundTheme
        let prominent: Bool

        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                // Matches a segment's padding, with a floor so the two
                // buttons stay the same width as their titles change.
                .padding(.vertical, 5)
                .padding(.horizontal, 16)
                .frame(minWidth: 88)
                .foregroundStyle(prominent ? theme.onAccent : theme.foreground)
                .background(
                    Capsule(style: .continuous)
                        .fill(fill)
                )
                .contentShape(Capsule(style: .continuous))
                .opacity(opacity(isPressed: configuration.isPressed))
        }

        private var fill: AnyShapeStyle {
            prominent
                ? AnyShapeStyle(theme.accent)
                : AnyShapeStyle(theme.foreground.opacity(0.12))
        }

        private func opacity(isPressed: Bool) -> Double {
            guard isEnabled else { return 0.4 }
            return isPressed ? 0.7 : 1
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        Button("Start") {}
            .buttonStyle(ThemedButtonStyle(theme: .ocean, prominent: true))
        Button("Finish") {}
            .buttonStyle(ThemedButtonStyle(theme: .ocean))
    }
    .padding()
    .background(BackgroundTheme.ocean.background)
}
