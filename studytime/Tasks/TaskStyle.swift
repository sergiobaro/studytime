import AppKit
import SwiftUI

/// The symbol a task is drawn with, so it can be told apart at a glance.
///
/// A fixed set rather than any SF Symbol name: a free-form name could come
/// back from a backup naming a symbol this system doesn't have, and draw as
/// nothing.
enum TaskIcon: String, CaseIterable, Identifiable, Codable {
    case book
    case pencil
    case function
    case flask
    case globe
    case translate
    case music
    case paintbrush
    case laptop
    case brain
    case leaf
    case star
    case history
    case code
    case chart
    case atom
    case stethoscope
    case ruler
    case graduation
    case lightbulb
    case heart
    case dumbbell
    case camera
    case theatre

    static let `default`: TaskIcon = .book

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .book: "book.closed.fill"
        case .pencil: "pencil"
        case .function: "function"
        case .flask: "flask.fill"
        case .globe: "globe.europe.africa.fill"
        case .translate: "character.bubble.fill"
        case .music: "music.note"
        case .paintbrush: "paintbrush.pointed.fill"
        case .laptop: "laptopcomputer"
        case .brain: "brain.head.profile"
        case .leaf: "leaf.fill"
        case .star: "star.fill"
        case .history: "building.columns.fill"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .chart: "chart.bar.fill"
        case .atom: "atom"
        case .stethoscope: "stethoscope"
        case .ruler: "ruler.fill"
        case .graduation: "graduationcap.fill"
        case .lightbulb: "lightbulb.fill"
        case .heart: "heart.fill"
        case .dumbbell: "dumbbell.fill"
        case .camera: "camera.fill"
        case .theatre: "theatermasks.fill"
        }
    }

    var title: String {
        switch self {
        case .book: "Book"
        case .pencil: "Pencil"
        case .function: "Maths"
        case .flask: "Science"
        case .globe: "Geography"
        case .translate: "Languages"
        case .music: "Music"
        case .paintbrush: "Art"
        case .laptop: "Computing"
        case .brain: "Thinking"
        case .leaf: "Nature"
        case .star: "Star"
        case .history: "History"
        case .code: "Code"
        case .chart: "Statistics"
        case .atom: "Physics"
        case .stethoscope: "Medicine"
        case .ruler: "Geometry"
        case .graduation: "Exams"
        case .lightbulb: "Ideas"
        case .heart: "Health"
        case .dumbbell: "Sport"
        case .camera: "Photography"
        case .theatre: "Drama"
        }
    }

    /// An unknown name — from a newer app's backup, say — falls back to the
    /// default rather than failing the whole task list.
    init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TaskIcon(rawValue: rawValue) ?? .default
    }
}

/// The colour a task's icon is drawn in.
///
/// Mid-tone colours, so the icon reads on the light and dark themes alike and
/// on the system sheets. System colours where there is one; the rest are fixed
/// mid-tones picked to stay apart from them.
///
/// New colours go at the end: `next(after:)` hands out colours in this order.
enum TaskColor: String, CaseIterable, Identifiable, Codable {
    case blue
    case green
    case orange
    case purple
    case red
    case teal
    case pink
    case yellow
    case indigo
    case brown
    case mint
    case cyan
    case gray
    case lime
    case crimson
    case magenta
    case lavender
    case olive

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .purple: .purple
        case .red: .red
        case .teal: .teal
        case .pink: .pink
        case .yellow: .yellow
        case .indigo: .indigo
        case .brown: .brown
        case .mint: .mint
        case .cyan: .cyan
        case .gray: .gray
        case .lime: Color(red: 0.55, green: 0.78, blue: 0.18)
        case .crimson: Color(red: 0.75, green: 0.13, blue: 0.27)
        case .magenta: Color(red: 0.85, green: 0.22, blue: 0.75)
        case .lavender: Color(red: 0.65, green: 0.56, blue: 0.95)
        case .olive: Color(red: 0.56, green: 0.56, blue: 0.22)
        }
    }

    var title: String {
        rawValue.capitalized
    }

    /// The colour a new task gets: the first one no task is using yet, so
    /// tasks start out distinct without the user having to choose.
    static func next(after used: [TaskColor]) -> TaskColor {
        if let unused = allCases.first(where: { !used.contains($0) }) { return unused }
        // Every colour is taken: carry on round the palette.
        return allCases[used.count % allCases.count]
    }

    init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = TaskColor(rawValue: rawValue) ?? .blue
    }
}

/// A task's icon in its colour.
struct TaskIconView: View {
    let icon: TaskIcon
    let color: TaskColor

    var body: some View {
        Image(systemName: icon.systemImage)
            .foregroundStyle(color.color)
            .accessibilityHidden(true)
    }
}

extension StudyTask {

    /// The task's icon in its colour, for menu items.
    var menuIcon: Image {
        .menuSymbol(icon.systemImage, color: NSColor(color.color))
    }
}

extension Image {

    /// A symbol for a menu item, centred in a fixed square so every item's
    /// title starts at the same place however wide its symbol is.
    ///
    /// With a colour, the colour is baked in: menus otherwise draw an image as
    /// a template, tinted to the text colour. Without one it stays a template,
    /// for items that aren't a task and should read like the text beside them.
    static func menuSymbol(_ name: String, color: NSColor? = nil) -> Image {
        var configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        if let color {
            configuration = configuration.applying(.init(paletteColors: [color]))
        }
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        else { return Image(systemName: name) }

        let side: CGFloat = 18
        let canvas = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            let scale = min(1, rect.width / symbol.size.width, rect.height / symbol.size.height)
            let size = NSSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
            symbol.draw(in: NSRect(
                x: rect.midX - size.width / 2,
                y: rect.midY - size.height / 2,
                width: size.width,
                height: size.height
            ))
            return true
        }
        canvas.isTemplate = color == nil
        return Image(nsImage: canvas)
    }
}
