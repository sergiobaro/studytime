import Foundation
import Testing
@testable import studytime

struct KeyValueStoreTests {

    /// The in-memory double is only trustworthy if it behaves like the real
    /// thing, so both implementations are held to the same expectations.
    @Test func theInMemoryStoreSatisfiesTheContract() {
        assertStoreBehaviour(InMemoryKeyValueStore())
    }

    @Test func userDefaultsSatisfiesTheContract() throws {
        let suiteName = "KeyValueStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        assertStoreBehaviour(defaults)

        defaults.removePersistentDomain(forName: suiteName)
    }

    /// Values must reach `UserDefaults` itself, not just live in the instance.
    @Test func userDefaultsPersistsAcrossInstances() {
        let suiteName = "KeyValueStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let writer: KeyValueStore = defaults
        writer.set("stopwatch", forKey: "mode")

        let reader: KeyValueStore = UserDefaults(suiteName: suiteName)!
        #expect(reader.value(forKey: "mode") == "stopwatch")

        defaults.removePersistentDomain(forName: suiteName)
    }

    private func assertStoreBehaviour(
        _ store: KeyValueStore,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        // A missing key reads as nil.
        #expect(store.value(forKey: "absent") == String?.none, sourceLocation: sourceLocation)

        // Values round-trip.
        store.set("stopwatch", forKey: "mode")
        store.set(42, forKey: "duration")
        #expect(store.value(forKey: "mode") == "stopwatch", sourceLocation: sourceLocation)
        #expect(store.value(forKey: "duration") == 42, sourceLocation: sourceLocation)

        // A stored 0 is distinguishable from a missing key — the reason the
        // typed `UserDefaults.integer(forKey:)` accessor is unusable here.
        store.set(0, forKey: "zero")
        #expect(store.value(forKey: "zero") == 0, sourceLocation: sourceLocation)
        #expect(store.value(forKey: "neverSet") == Int?.none, sourceLocation: sourceLocation)

        // Reading at the wrong type yields nil rather than trapping.
        #expect(store.value(forKey: "mode") == Int?.none, sourceLocation: sourceLocation)

        // Writing nil clears the key, as does removing it outright. This is
        // what pins the documented nil behaviour on both implementations.
        store.set(nil, forKey: "mode")
        #expect(store.value(forKey: "mode") == String?.none, sourceLocation: sourceLocation)

        store.removeObject(forKey: "duration")
        #expect(store.value(forKey: "duration") == Int?.none, sourceLocation: sourceLocation)
    }
}
