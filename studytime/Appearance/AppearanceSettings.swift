import AppKit

/// Holds the user's appearance choices and persists them.
///
/// Kept separate from `StudyTimer` — how the window looks is unrelated to how
/// the clock runs — but follows the same shape: computed properties over
/// private storage, and a `KeyValueStore` injected for tests.
@Observable
final class AppearanceSettings {
    static let defaultTheme = BackgroundTheme.system

    /// Where the background image is kept: a copy in the app's own storage,
    /// so it survives the original being moved or deleted.
    static var defaultBackgroundImageURL: URL {
        URL.applicationSupportDirectory
            .appending(path: Bundle.main.bundleIdentifier ?? "studytime")
            .appending(path: "BackgroundImage")
    }

    private enum Key {
        static let backgroundTheme = "backgroundTheme"
    }

    private var storedTheme: BackgroundTheme

    var theme: BackgroundTheme {
        get { storedTheme }
        set {
            guard newValue != storedTheme else { return }
            storedTheme = newValue
            store.set(newValue.rawValue, forKey: Key.backgroundTheme)
        }
    }

    /// The image drawn behind the clock, or `nil` for the theme's colour alone.
    ///
    /// The file itself is the setting: there is an image when the copy exists.
    private(set) var backgroundImage: NSImage?

    private let store: KeyValueStore
    private let backgroundImageURL: URL

    init(
        store: KeyValueStore = UserDefaults.standard,
        backgroundImageURL: URL = AppearanceSettings.defaultBackgroundImageURL
    ) {
        self.store = store
        self.backgroundImageURL = backgroundImageURL

        let storedRawValue: String? = store.value(forKey: Key.backgroundTheme)
        self.storedTheme = storedRawValue.flatMap(BackgroundTheme.init(rawValue:)) ?? Self.defaultTheme
        self.backgroundImage = NSImage(contentsOf: backgroundImageURL)
    }

    /// Copies the image at `url` in as the background, replacing any before it.
    ///
    /// Checked before it is copied, so picking a file that isn't an image
    /// leaves the current background as it was.
    func setBackgroundImage(from url: URL) throws {
        // A file picked outside the sandbox is readable only while access is held.
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)
        guard let image = NSImage(data: data), image.isValid else {
            throw BackgroundImageError.unreadable
        }

        try FileManager.default.createDirectory(
            at: backgroundImageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: backgroundImageURL, options: .atomic)
        backgroundImage = image
    }

    func removeBackgroundImage() {
        try? FileManager.default.removeItem(at: backgroundImageURL)
        backgroundImage = nil
    }
}

enum BackgroundImageError: LocalizedError {
    case unreadable

    var errorDescription: String? {
        "The file isn't an image StudyTime can open."
    }
}
