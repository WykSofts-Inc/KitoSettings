//
//  KitoSettingsStore.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A typed UserDefaults key with its default value.
///
/// ```swift
/// extension KitoSettingKey where Value == Bool {
///     static let haptics = KitoSettingKey("haptics", default: true)
/// }
/// ```
public struct KitoSettingKey<Value: KitoSettingValue>: Sendable {
    /// The key's name, without the store's namespace.
    public let name: String
    /// What the setting reads as until it's been set, and after a reset.
    public let defaultValue: Value

    public init(_ name: String, default defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }

    /// The key erased to its name, for `reset(_:)`.
    public var erased: KitoAnySettingKey { KitoAnySettingKey(name: name) }
}

/// A key without its value type, used to reset a mixed list of keys.
public struct KitoAnySettingKey: Hashable, Sendable {
    public let name: String
    public init(name: String) { self.name = name }
}

/// Reads and writes typed settings in UserDefaults, under an optional namespace so a reset only
/// touches your own keys.
///
/// ```swift
/// let store = KitoSettingsStore(namespace: "settings")
/// store[.haptics] = false
/// store.resetAll()          // every "settings." key goes back to its default
/// ```
public struct KitoSettingsStore {
    /// Posted (on the default center) after any write or reset through a store.
    public static let didChange = Notification.Name("KitoSettingsStore.didChange")

    public let defaults: UserDefaults
    /// Prefixed to every key as "namespace.name". Empty for none.
    public let namespace: String

    public init(defaults: UserDefaults = .standard, namespace: String = "kito.settings") {
        self.defaults = defaults
        self.namespace = namespace
    }

    /// The store most apps use: `.standard` under "kito.settings".
    public static let standard = KitoSettingsStore()

    /// The full UserDefaults key for `name`.
    public func storageKey(_ name: String) -> String {
        namespace.isEmpty ? name : "\(namespace).\(name)"
    }

    /// The stored value, or the key's default when nothing (or the wrong type) is stored.
    public func value<Value>(for key: KitoSettingKey<Value>) -> Value {
        guard let stored = defaults.object(forKey: storageKey(key.name)),
              let value = Value(storedValue: stored) else { return key.defaultValue }
        return value
    }

    public func set<Value>(_ value: Value, for key: KitoSettingKey<Value>) {
        defaults.set(value.storedValue, forKey: storageKey(key.name))
        notify()
    }

    public subscript<Value>(key: KitoSettingKey<Value>) -> Value {
        get { value(for: key) }
        nonmutating set { set(newValue, for: key) }
    }

    /// Whether the key has been set (a reset key hasn't).
    public func contains<Value>(_ key: KitoSettingKey<Value>) -> Bool {
        defaults.object(forKey: storageKey(key.name)) != nil
    }

    /// Puts one key back to its default.
    public func reset<Value>(_ key: KitoSettingKey<Value>) {
        reset([key.erased])
    }

    /// Puts several keys back to their defaults.
    public func reset(_ keys: [KitoAnySettingKey]) {
        for key in keys { defaults.removeObject(forKey: storageKey(key.name)) }
        notify()
    }

    /// Puts every key in this namespace back to its default. Does nothing without a namespace,
    /// so it can never wipe another library's settings.
    public func resetAll() {
        guard !namespace.isEmpty else { return }
        let prefix = namespace + "."
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
        notify()
    }

    private func notify() {
        NotificationCenter.default.post(name: Self.didChange, object: nil)
    }
}

/// UserDefaults is thread-safe, so a store can be shared freely.
extension KitoSettingsStore: @unchecked Sendable {}
