import SwiftUI

/// The close button at the start of a sheet's title row. Escape still closes
/// the sheet, as the Done button it replaced did.
struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .keyboardShortcut(.cancelAction)
        .help("Close")
        .accessibilityLabel("Close")
    }
}
