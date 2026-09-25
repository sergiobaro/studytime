import AppKit
import Testing
@testable import studytime

struct AppearanceSettingsTests {

    let store: InMemoryKeyValueStore
    let appearance: AppearanceSettings

    init() {
        store = InMemoryKeyValueStore()
        appearance = AppearanceSettings(store: store)
    }

    @Test func anEmptyStoreFallsBackToTheDefaultTheme() {
        #expect(appearance.theme == AppearanceSettings.defaultTheme)
    }

    @Test func theChosenThemeSurvivesRelaunch() {
        appearance.theme = .ocean

        let relaunched = AppearanceSettings(store: store)
        #expect(relaunched.theme == .ocean)
    }

    @Test func anUnrecognisedStoredThemeFallsBackToTheDefault() {
        let loaded = AppearanceSettings(store: InMemoryKeyValueStore(["backgroundTheme": "chartreuse"]))

        #expect(loaded.theme == AppearanceSettings.defaultTheme)
    }

    @Test func aStoredValueOfTheWrongTypeFallsBackToTheDefault() {
        let loaded = AppearanceSettings(store: InMemoryKeyValueStore(["backgroundTheme": 7]))

        #expect(loaded.theme == AppearanceSettings.defaultTheme)
    }

    @Test func everyThemeRoundTripsThroughItsRawValue() {
        for theme in BackgroundTheme.allCases {
            appearance.theme = theme
            #expect(AppearanceSettings(store: store).theme == theme)
        }
    }

    /// Reselecting the current theme must not touch the store — the setter
    /// guards on equality to avoid redundant writes.
    @Test func reselectingTheCurrentThemeWritesNothing() {
        appearance.theme = AppearanceSettings.defaultTheme

        #expect(store.object(forKey: "backgroundTheme") == nil)
    }
}

struct BackgroundImageTests {

    let store = InMemoryKeyValueStore()
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    var imageURL: URL { folder.appending(path: "Stored/BackgroundImage") }

    func makeAppearance() -> AppearanceSettings {
        AppearanceSettings(store: store, backgroundImageURL: imageURL)
    }

    /// A small PNG written to disk, as a picked file would be.
    func pngFile() throws -> URL {
        let image = NSImage(size: NSSize(width: 4, height: 4), flipped: false) { rect in
            NSColor.red.setFill()
            rect.fill()
            return true
        }
        let bitmap = try #require(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: "picked.png")
        try data.write(to: url)
        return url
    }

    @Test func thereIsNoImageByDefault() {
        #expect(makeAppearance().backgroundImage == nil)
    }

    @Test func aChosenImageSurvivesRelaunch() throws {
        try makeAppearance().setBackgroundImage(from: pngFile())

        #expect(makeAppearance().backgroundImage != nil)
    }

    /// The image is copied in, so it doesn't depend on the picked file staying put.
    @Test func theImageOutlivesTheOriginalFile() throws {
        let picked = try pngFile()
        try makeAppearance().setBackgroundImage(from: picked)
        try FileManager.default.removeItem(at: picked)

        #expect(makeAppearance().backgroundImage != nil)
    }

    @Test func removingTheImageSurvivesRelaunch() throws {
        let appearance = makeAppearance()
        try appearance.setBackgroundImage(from: pngFile())

        appearance.removeBackgroundImage()

        #expect(appearance.backgroundImage == nil)
        #expect(makeAppearance().backgroundImage == nil)
    }

    @Test func aFileThatIsNotAnImageKeepsTheCurrentOne() throws {
        let appearance = makeAppearance()
        try appearance.setBackgroundImage(from: pngFile())
        let notAnImage = folder.appending(path: "notes.txt")
        try Data("not an image".utf8).write(to: notAnImage)

        #expect(throws: BackgroundImageError.unreadable) {
            try appearance.setBackgroundImage(from: notAnImage)
        }
        #expect(appearance.backgroundImage != nil)
        #expect(makeAppearance().backgroundImage != nil)
    }
}
