import AppKit
import Foundation
import SwiftUI
import Testing
@testable import studytime

struct BackgroundThemeTests {

    /// WCAG AAA for normal-size text. The clock is huge, but the stepper
    /// label and swatch hairlines are not, so the whole palette is held here.
    private static let minimumContrast = 7.0

    private static var fixedThemes: [BackgroundTheme] {
        BackgroundTheme.allCases.filter { $0 != .system }
    }

    @Test func rawValuesAreStableAndUnique() {
        // Raw values are the persisted representation, so a rename would
        // silently reset everyone's saved choice.
        let rawValues = BackgroundTheme.allCases.map(\.rawValue)

        #expect(rawValues == [
            "system",
            "graphite", "slate", "midnight", "ocean", "forest",
            "moss", "plum", "ember", "espresso",
            "paper", "linen", "sand", "mist", "sage", "blush",
        ])
        #expect(Set(rawValues).count == rawValues.count)
    }

    @Test func everyThemeHasATitle() {
        for theme in BackgroundTheme.allCases {
            #expect(!theme.title.isEmpty)
        }
    }

    /// The point of pinning a foreground per theme: text must stay readable
    /// on a background that no longer follows light/dark mode.
    @Test func everyThemeMeetsAAAContrastForBodyText() throws {
        for theme in Self.fixedThemes {
            let ratio = try #require(
                Self.contrastRatio(theme.background, theme.foreground),
                "\(theme.title) has a colour that cannot be measured"
            )
            #expect(
                ratio >= Self.minimumContrast,
                "\(theme.title) is \(Self.rounded(ratio)):1, below \(Self.minimumContrast):1"
            )
        }
    }

    @Test func everyThemeMeetsAAAContrastForTheActiveSegment() throws {
        for theme in Self.fixedThemes {
            let ratio = try #require(Self.contrastRatio(theme.accent, theme.onAccent))
            #expect(
                ratio >= Self.minimumContrast,
                "\(theme.title) active segment is \(Self.rounded(ratio)):1"
            )
        }
    }

    @Test func lightThemesAreActuallyLightAndDarkOnesDark() throws {
        for theme in Self.fixedThemes {
            let luminance = try #require(Self.relativeLuminance(theme.background))
            // 0.18 sits well clear of both clusters in the current palette.
            #expect(
                theme.isLight == (luminance > 0.18),
                "\(theme.title) is flagged isLight == \(theme.isLight) at luminance \(Self.rounded(luminance))"
            )
        }
    }

    @Test func fixedThemesInvertTheirPairingForTheActiveSegment() {
        for theme in Self.fixedThemes {
            #expect(theme.accent == theme.foreground)
            #expect(theme.onAccent == theme.background)
        }
    }

    @Test func systemDefersToTheUsersAccentColour() {
        #expect(BackgroundTheme.system.accent == .accentColor)
        // `.system`'s background is `.clear`, so it cannot be the label colour.
        #expect(BackgroundTheme.system.onAccent == .white)
        #expect(BackgroundTheme.system.onAccent != BackgroundTheme.system.background)
    }

    @Test func everyThemeHasAVisibleActiveSegment() {
        for theme in BackgroundTheme.allCases {
            #expect(theme.accent != .clear)
            #expect(theme.onAccent != .clear)
            #expect(theme.accent != theme.onAccent)
        }
    }

    @Test func systemIsTheOnlyTransparentTheme() {
        // The other themes paint a fixed colour; `.system` deliberately does
        // not, so the standard window material shows through.
        #expect(BackgroundTheme.system.background == .clear)

        for theme in Self.fixedThemes {
            #expect(theme.background != .clear)
        }
    }

    // MARK: - WCAG contrast

    private static func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    /// Returns `nil` for colours that have no fixed sRGB value, such as the
    /// dynamic system colours.
    private static func relativeLuminance(_ color: Color) -> Double? {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return nil }

        func channel(_ value: CGFloat) -> Double {
            let value = Double(value)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * channel(srgb.redComponent)
            + 0.7152 * channel(srgb.greenComponent)
            + 0.0722 * channel(srgb.blueComponent)
    }

    private static func contrastRatio(_ first: Color, _ second: Color) -> Double? {
        guard let a = relativeLuminance(first), let b = relativeLuminance(second) else {
            return nil
        }
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
