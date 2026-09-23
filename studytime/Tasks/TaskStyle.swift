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
/// Mid-tone system colours, so the icon reads on the light and dark themes
/// alike and on the system sheets.
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
