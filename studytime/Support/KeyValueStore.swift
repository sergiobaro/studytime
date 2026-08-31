import Foundation

protocol KeyValueStore: AnyObject {
    
    func object(forKey key: String) -> Any?
    /// Passing `nil` removes the key.
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
}

extension UserDefaults: KeyValueStore {}

extension KeyValueStore {
    
    func value<Value>(forKey key: String) -> Value? {
        object(forKey: key) as? Value
    }
}
