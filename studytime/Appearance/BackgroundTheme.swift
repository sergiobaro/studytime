import SwiftUI

/// A background choice for the timer window.
///
/// Each case carries its own foreground colour rather than relying on the
/// system label colour: a fixed background does not follow light/dark mode,
/// so the pairing has to be decided here to keep the clock readable.
///
/// Every pairing is held to WCAG AAA (7:1) by `BackgroundThemeTests`, so a
/// new case is checked automatically — no need to eyeball it.
enum BackgroundTheme: String, CaseIterable, Identifiable {
    /// The default window material, following system light/dark appearance.
    case system

    // Dark
    case graphite
    case slate
    case midnight
    case ocean
    case forest
    case moss
    case plum
    case ember
    case espresso

    // Light
    case paper
    case linen
    case sand
    case mist
    case sage
    case blush

    var id: String { rawValue }

    /// Whether the theme paints a pale background, and so needs dark text.
    var isLight: Bool {
        switch self {
        case .paper, .linen, .sand, .mist, .sage, .blush: true
        case .system, .graphite, .slate, .midnight, .ocean, .forest,
             .moss, .plum, .ember, .espresso: false
        }
    }

    var title: String {
        switch self {
        case .system: "System"
        case .graphite: "Graphite"
        case .slate: "Slate"
        case .midnight: "Midnight"
        case .ocean: "Ocean"
        case .forest: "Forest"
        case .moss: "Moss"
        case .plum: "Plum"
        case .ember: "Ember"
        case .espresso: "Espresso"
        case .paper: "Paper"
        case .linen: "Linen"
        case .sand: "Sand"
        case .mist: "Mist"
        case .sage: "Sage"
        case .blush: "Blush"
        }
    }

    /// `.clear` for `.system`, which lets the standard window material show
    /// through untouched.
    var background: Color {
        switch self {
        case .system: .clear
        case .graphite: Color(red: 0.16, green: 0.17, blue: 0.19)
        case .slate: Color(red: 0.18, green: 0.21, blue: 0.25)
        case .midnight: Color(red: 0.11, green: 0.13, blue: 0.26)
        case .ocean: Color(red: 0.10, green: 0.22, blue: 0.30)
        case .forest: Color(red: 0.11, green: 0.22, blue: 0.18)
        case .moss: Color(red: 0.16, green: 0.21, blue: 0.13)
        case .plum: Color(red: 0.20, green: 0.13, blue: 0.24)
        case .ember: Color(red: 0.24, green: 0.12, blue: 0.10)
        case .espresso: Color(red: 0.19, green: 0.15, blue: 0.12)
        case .paper: Color(red: 0.96, green: 0.95, blue: 0.93)
        case .linen: Color(red: 0.93, green: 0.91, blue: 0.86)
        case .sand: Color(red: 0.91, green: 0.86, blue: 0.78)
        case .mist: Color(red: 0.85, green: 0.90, blue: 0.94)
        case .sage: Color(red: 0.86, green: 0.90, blue: 0.84)
        case .blush: Color(red: 0.95, green: 0.89, blue: 0.89)
        }
    }

    var foreground: Color {
        switch self {
        // `.primary` keeps following the system appearance; the fixed
        // backgrounds each pin a foreground that contrasts with them.
        case .system: .primary
        case .graphite, .slate, .midnight, .ocean, .forest,
             .moss, .plum, .ember, .espresso: Color(white: 0.96)
        // The pale themes take an ink tinted towards their own hue rather
        // than a flat black, which reads warmer against the background.
        case .paper: Color(red: 0.15, green: 0.15, blue: 0.14)
        case .linen: Color(red: 0.17, green: 0.15, blue: 0.12)
        case .sand: Color(red: 0.16, green: 0.14, blue: 0.11)
        case .mist: Color(red: 0.11, green: 0.15, blue: 0.19)
        case .sage: Color(red: 0.12, green: 0.17, blue: 0.13)
        case .blush: Color(red: 0.20, green: 0.13, blue: 0.14)
        }
    }

    /// Fill for the active segment of a themed control.
    ///
    /// The fixed themes invert their own pairing, which gives the selected
    /// segment exactly the contrast measured for body text. `.system` defers
    /// to the user's chosen accent colour instead.
    var accent: Color {
        self == .system ? .accentColor : foreground
    }

    /// A mid-tone of the theme's own hue, for highlights in the sheets.
    ///
    /// The sheets keep the system appearance, where `accent` — the theme's
    /// text colour — would be near-white or near-black and read as no colour
    /// at all. A mid-tone shows on the light and dark system backgrounds
    /// alike, and carries white text at full strength. `.system` defers to
    /// the user's accent colour.
    var highlight: Color {
        switch self {
        case .system: .accentColor
        case .graphite: Color(red: 0.45, green: 0.47, blue: 0.52)
        case .slate: Color(red: 0.36, green: 0.46, blue: 0.58)
        case .midnight: Color(red: 0.33, green: 0.38, blue: 0.78)
        case .ocean: Color(red: 0.13, green: 0.50, blue: 0.66)
        case .forest: Color(red: 0.18, green: 0.55, blue: 0.40)
        case .moss: Color(red: 0.40, green: 0.53, blue: 0.23)
        case .plum: Color(red: 0.55, green: 0.33, blue: 0.65)
        case .ember: Color(red: 0.80, green: 0.35, blue: 0.24)
        case .espresso: Color(red: 0.58, green: 0.42, blue: 0.30)
        case .paper: Color(red: 0.50, green: 0.49, blue: 0.46)
        case .linen: Color(red: 0.60, green: 0.50, blue: 0.38)
        case .sand: Color(red: 0.66, green: 0.52, blue: 0.30)
        case .mist: Color(red: 0.36, green: 0.52, blue: 0.66)
        case .sage: Color(red: 0.40, green: 0.57, blue: 0.43)
        case .blush: Color(red: 0.76, green: 0.42, blue: 0.48)
        }
    }

    /// Text drawn on top of `accent`.
    var onAccent: Color {
        // `.system`'s background is `.clear`, which would be invisible here.
        self == .system ? .white : background
    }

    /// Laid over a background image so the clock stays readable on any
    /// photo: the image is tinted towards the colour `foreground` was paired
    /// with. `.system` uses the window colour, which follows light and dark
    /// mode just as its `.primary` text does.
    var imageScrim: Color {
        self == .system ? Color(nsColor: .windowBackgroundColor) : background
    }

    /// How strongly `imageScrim` covers the image: enough to keep the text
    /// legible, while leaving the picture recognisable.
    static let imageScrimOpacity = 0.6

    /// What the swatch shows. `.system`'s `.clear` background would be an
    /// invisible dot, so it gets a neutral stand-in.
    var swatch: Color {
        self == .system ? Color.secondary.opacity(0.3) : background
    }
}
