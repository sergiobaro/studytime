import Foundation
import Testing
@testable import studytime

struct BackgroundThemePickerTests {

    @Test func theCaptionNamesTheSelectionWhenNothingIsHovered() {
        #expect(
            BackgroundThemePicker.displayedName(hovered: nil, selected: .ocean) == "Ocean"
        )
    }

    @Test func hoveringPreviewsTheNameWithoutChangingTheSelection() {
        #expect(
            BackgroundThemePicker.displayedName(hovered: .sand, selected: .ocean) == "Sand"
        )
    }

    @Test func everyThemeCanBeCaptioned() {
        for theme in BackgroundTheme.allCases {
            #expect(
                BackgroundThemePicker.displayedName(hovered: theme, selected: .system) == theme.title
            )
        }
    }
}
