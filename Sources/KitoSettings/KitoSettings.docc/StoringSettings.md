# Storing Settings

Declare typed keys, bind them in views, and reset them to their defaults.

## Overview

Settings are stored in UserDefaults through typed keys. A ``KitoSettingKey``
pairs a name with a default value, a ``KitoSettingsStore`` reads and writes keys
under a namespace, and the ``KitoSetting`` property wrapper exposes a key to a
view as a live value with a `Binding`.

### Declare keys

Declare each key once, as a static member constrained to its value type:

```swift
extension KitoSettingKey where Value == Bool {
    static let haptics = KitoSettingKey("haptics", default: true)
}

extension KitoSettingKey where Value == KitoAppearanceMode {
    static let appearance = KitoSettingKey("appearance", default: .system)
}
```

`Bool`, `Int`, `Double`, `String`, `Date`, `Data`, `URL`, arrays and optionals
of them work as values, and so does any enum with a `String` or `Int` raw value
once it adopts ``KitoSettingValue``. Wrap anything `Codable` in
``KitoCodableSetting``.

### Bind a key in a view

```swift
struct PreferencesView: View {
    @KitoSetting(.haptics) private var haptics

    var body: some View {
        Toggle("Haptics", isOn: $haptics)
    }
}
```

Without a `store:` argument, ``KitoSetting`` uses ``KitoSettingsStore/standard``.

### Read, write and reset

```swift
let store = KitoSettingsStore(namespace: "settings")   // UserDefaults.standard by default
store[.haptics] = false
store.reset(.haptics)
store.reset([KitoSettingKey<Bool>.haptics.erased, KitoSettingKey<KitoAppearanceMode>.appearance.erased])
store.resetAll()                                        // only "settings." keys
```

``KitoSettingsStore/resetAll()`` removes only the keys in the store's
namespace, so it never wipes another library's settings.
