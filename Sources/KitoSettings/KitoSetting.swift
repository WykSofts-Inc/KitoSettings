//
//  KitoSetting.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import Combine

/// A setting read and written like `@State`, stored in UserDefaults through a `KitoSettingsStore`.
/// The view updates whenever the value changes, from anywhere, including a reset.
///
/// ```swift
/// @KitoSetting(.haptics) private var haptics
/// KitoToggleRow("Haptics", systemImage: "hand.tap.fill", color: .pink, isOn: $haptics)
/// ```
@propertyWrapper
public struct KitoSetting<Value: KitoSettingValue>: DynamicProperty {
    @StateObject private var box: KitoSettingBox<Value>

    public init(_ key: KitoSettingKey<Value>, store: KitoSettingsStore = .standard) {
        _box = StateObject(wrappedValue: KitoSettingBox(key: key, store: store))
    }

    public var wrappedValue: Value {
        get { box.value }
        nonmutating set { box.write(newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding(get: { box.value }, set: { box.write($0) })
    }
}

/// Holds the current value and refreshes it when the store or UserDefaults changes.
final class KitoSettingBox<Value: KitoSettingValue>: ObservableObject {
    @Published private(set) var value: Value
    private let key: KitoSettingKey<Value>
    private let store: KitoSettingsStore
    private var observers: [NSObjectProtocol] = []

    init(key: KitoSettingKey<Value>, store: KitoSettingsStore) {
        self.key = key
        self.store = store
        self.value = store.value(for: key)
        let center = NotificationCenter.default
        let names = [KitoSettingsStore.didChange, UserDefaults.didChangeNotification]
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func write(_ newValue: Value) {
        value = newValue
        store.set(newValue, for: key)
    }

    private func refresh() {
        let latest = store.value(for: key)
        // Only publish real changes; UserDefaults posts for every write in the app.
        guard !Self.same(latest, value) else { return }
        value = latest
    }

    private static func same(_ a: Value, _ b: Value) -> Bool {
        (a.storedValue as AnyObject).isEqual(b.storedValue)
    }
}
