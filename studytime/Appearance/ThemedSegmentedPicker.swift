import SwiftUI

/// A segmented picker whose active segment follows the app's theme.
///
/// This replaces `.pickerStyle(.segmented)`, which is drawn by AppKit's
/// `NSSegmentedControl`: its selected-segment bezel comes from the system
/// accent colour and does not reliably follow a SwiftUI `.tint`.
struct ThemedSegmentedPicker<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let theme: BackgroundTheme
    let title: (Option) -> String

    @Namespace private var indicatorNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                segment(for: option)
            }
        }
        .padding(3)
        .background(
            Capsule(style: .continuous)
                .fill(theme.foreground.opacity(0.12))
        )
        .animation(.snappy(duration: 0.2), value: selection)
    }

    private func segment(for option: Option) -> some View {
        let isSelected = option == selection

        return Button {
            selection = option
        } label: {
            Text(title(option))
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .foregroundStyle(isSelected ? theme.onAccent : theme.foreground.opacity(0.75))
                .background {
                    if isSelected {
                        // Shared id lets the indicator slide between segments.
                        Capsule(style: .continuous)
                            .fill(theme.accent)
                            .matchedGeometryEffect(id: "indicator", in: indicatorNamespace)
                    }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title(option))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var mode = TimerMode.countdown
    return ThemedSegmentedPicker(
        options: TimerMode.allCases,
        selection: $mode,
        theme: .ocean,
        title: \.title
    )
    .frame(width: 220)
    .padding()
    .background(BackgroundTheme.ocean.background)
}
