import Foundation
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
