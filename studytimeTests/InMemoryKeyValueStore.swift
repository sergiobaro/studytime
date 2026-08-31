import Foundation
@testable import studytime

final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Any]

    init(_ storage: [String: Any] = [:]) {
        self.storage = storage
    }

    func object(forKey key: String) -> Any? {
        storage[key]
    }

    func set(_ value: Any?, forKey key: String) {
        if let value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
