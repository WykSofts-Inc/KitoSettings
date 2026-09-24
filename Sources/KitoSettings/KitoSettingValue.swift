//
//  KitoSettingValue.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A value that can live in UserDefaults. Bool, Int, Double, String, Date, Data, URL and arrays of
/// them work out of the box; so does any enum with a String or Int raw value once you add
/// `KitoSettingValue` to it. Anything `Codable` can be stored with `KitoCodableSetting`.
public protocol KitoSettingValue: Sendable {
    /// The property-list value written to UserDefaults.
    var storedValue: Any { get }
    /// Reads a value back; nil when what's stored has the wrong type.
    init?(storedValue: Any)
}

extension Bool: KitoSettingValue {
    public var storedValue: Any { self }
    public init?(storedValue: Any) {
        guard let value = storedValue as? Bool else { return nil }
        self = value
    }
}

extension Int: KitoSettingValue {
    public var storedValue: Any { self }
    public init?(storedValue: Any) {
        guard let value = storedValue as? Int else { return nil }
        self = value
    }
}

extension Double: KitoSettingValue {
    public var storedValue: Any { self }
    public init?(storedValue: Any) {
        if let value = storedValue as? Double { self = value; return }
        guard let value = storedValue as? Int else { return nil }
        self = Double(value)
    }
}

extension String: KitoSettingValue {
    public var storedValue: Any { self }
    public init?(storedValue: Any) {
        guard let value = storedValue as? String else { return nil }
        self = value
    }
}

extension Date: KitoSettingValue {
    public var storedValue: Any { self }
    public init?(storedValue: Any) {
        guard let value = storedValue as? Date else { return nil }
        self = value
    }
}

extension Data: KitoSettingValue {
    public var storedValue: Any { self }
    public init?(storedValue: Any) {
        guard let value = storedValue as? Data else { return nil }
        self = value
    }
}

extension URL: KitoSettingValue {
    public var storedValue: Any { absoluteString }
    public init?(storedValue: Any) {
        guard let text = storedValue as? String, let url = URL(string: text) else { return nil }
        self = url
    }
}

extension Array: KitoSettingValue where Element: KitoSettingValue {
    public var storedValue: Any { map(\.storedValue) }
    public init?(storedValue: Any) {
        guard let values = storedValue as? [Any] else { return nil }
        var result: [Element] = []
        for value in values {
            guard let element = Element(storedValue: value) else { return nil }
            result.append(element)
        }
        self = result
    }
}

extension Optional: KitoSettingValue where Wrapped: KitoSettingValue {
    /// `nil` is stored as an empty marker so a key set to nil differs from a key never set.
    public var storedValue: Any {
        switch self {
        case .some(let value): return ["value": value.storedValue]
        case .none: return [String: Any]()
        }
    }

    public init?(storedValue: Any) {
        guard let box = storedValue as? [String: Any] else { return nil }
        guard let inner = box["value"] else { self = .none; return }
        guard let value = Wrapped(storedValue: inner) else { return nil }
        self = .some(value)
    }
}

public extension KitoSettingValue where Self: RawRepresentable, RawValue: KitoSettingValue {
    var storedValue: Any { rawValue.storedValue }
    init?(storedValue: Any) {
        guard let raw = RawValue(storedValue: storedValue) else { return nil }
        self.init(rawValue: raw)
    }
}

/// Stores any `Codable` value as JSON: `KitoSettingKey<KitoCodableSetting<Profile>>`.
public struct KitoCodableSetting<Value: Codable & Sendable>: KitoSettingValue {
    public var value: Value

    public init(_ value: Value) { self.value = value }

    public var storedValue: Any {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    public init?(storedValue: Any) {
        guard let data = storedValue as? Data,
              let value = try? JSONDecoder().decode(Value.self, from: data) else { return nil }
        self.value = value
    }
}

extension KitoCodableSetting: Equatable where Value: Equatable {}
