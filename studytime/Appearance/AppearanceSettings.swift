import Foundation

/// Holds the user's appearance choices and persists them.
///
/// Kept separate from `StudyTimer` — how the window looks is unrelated to how
/// the clock runs — but follows the same shape: computed properties over
/// private storage, and a `KeyValueStore` injected for tests.
@Observable
final class AppearanceSettings {
    static let defaultTheme = BackgroundTheme.system

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

    private let store: KeyValueStore

    init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store

        let storedRawValue: String? = store.value(forKey: Key.backgroundTheme)
        self.storedTheme = storedRawValue.flatMap(BackgroundTheme.init(rawValue:)) ?? Self.defaultTheme
    }
}
