import SwiftUI

/// Bare up and down arrows, stacked in a bezel the way `NSStepper` draws them
/// — only in the theme's colours rather than the system's.
///
/// Like `ThemedSegmentedPicker`, this stands in for an AppKit-drawn control:
/// `Stepper` is backed by `NSStepper`, whose bezel comes from the system
/// appearance and ignores the window's theme. It carries no caption of its
/// own; what it steps is shown by whatever it sits beside.
struct ThemedStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let theme: BackgroundTheme
    /// Names the value for VoiceOver, which has no caption to read.
    let label: String

    static let width: CGFloat = 30

    /// The whole control dims while the parent has it disabled — a plain
    /// button style draws no disabled state of its own.
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        VStack(spacing: 1) {
            arrow(systemImage: "chevron.up", delta: 1, label: "Increase \(label)")
            arrow(systemImage: "chevron.down", delta: -1, label: "Decrease \(label)")
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(theme.foreground.opacity(0.12))
        )
        // Clipped to the bezel so a pressed half picks up its rounded corners.
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .foregroundStyle(theme.foreground)
        .opacity(isEnabled ? 1 : 0.4)
    }

    private func arrow(systemImage: String, delta: Int, label: String) -> some View {
        // A step that would leave the range is disabled rather than clamped,
        // so the arrow stops responding at the ends like `Stepper` does.
        let target = value + delta
        let canStep = range.contains(target)

        return Button {
            value = target
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .black))
                // Each half is a comfortable target in its own right; the
                // glyph is small but the whole rectangle takes the click.
                .frame(width: Self.width, height: 17)
                .contentShape(Rectangle())
                .opacity(canStep ? 1 : 0.35)
        }
        .buttonStyle(ArrowButtonStyle(theme: theme))
        .disabled(!canStep)
        // Held down, it repeats — the range runs to three hours, so stepping
        // it one minute per click would be tedious.
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(label)
    }
}

/// Lights the pressed half up, which `.plain` does not do. Held down the
/// button repeats, so the highlight also shows that the repeat is running.
private struct ArrowButtonStyle: ButtonStyle {
    let theme: BackgroundTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(theme.foreground.opacity(configuration.isPressed ? 0.22 : 0))
    }
}

#Preview {
    @Previewable @State var minutes = 25
    return ThemedStepper(
        value: $minutes,
        range: StudyTimer.durationRange,
        theme: .ocean,
        label: "duration"
    )
    .padding()
    .background(BackgroundTheme.ocean.background)
}
