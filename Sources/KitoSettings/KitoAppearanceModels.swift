//
//  KitoAppearanceModels.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UIKit

/// Light, dark or follow the system. Store it with `KitoSetting` and apply it with
/// `.preferredColorScheme(mode.colorScheme)`.
public enum KitoAppearanceMode: String, CaseIterable, Identifiable, KitoSettingValue {
    case system, light, dark

    public var id: Self { self }

    public var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    public var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// Nil for `.system`, so the app follows the device.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// A named accent colour for the accent grid.
public struct KitoAccentOption: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var color: Color

    public init(_ id: String, name: String, color: Color) {
        self.id = id
        self.name = name
        self.color = color
    }

    /// Nine accents that read well on light and dark backgrounds.
    public static let defaults: [KitoAccentOption] = [
        KitoAccentOption("blue", name: "Blue", color: Color(red: 0.11, green: 0.42, blue: 0.94)),
        KitoAccentOption("indigo", name: "Indigo", color: Color(red: 0.35, green: 0.34, blue: 0.84)),
        KitoAccentOption("purple", name: "Purple", color: Color(red: 0.62, green: 0.32, blue: 0.87)),
        KitoAccentOption("pink", name: "Pink", color: Color(red: 0.93, green: 0.29, blue: 0.55)),
        KitoAccentOption("red", name: "Red", color: Color(red: 0.90, green: 0.25, blue: 0.30)),
        KitoAccentOption("orange", name: "Orange", color: Color(red: 0.96, green: 0.52, blue: 0.13)),
        KitoAccentOption("green", name: "Green", color: Color(red: 0.13, green: 0.66, blue: 0.42)),
        KitoAccentOption("teal", name: "Teal", color: Color(red: 0.10, green: 0.62, blue: 0.68)),
        KitoAccentOption("graphite", name: "Graphite", color: Color(red: 0.36, green: 0.38, blue: 0.42)),
    ]

    /// The option with `id` in `options`, or the first one.
    public static func option(_ id: String, in options: [KitoAccentOption] = defaults) -> KitoAccentOption? {
        options.first { $0.id == id } ?? options.first
    }
}

/// One choice in the app icon grid.
///
/// The host app has to ship each alternate icon: add the icon sets to the asset catalog and, in
/// the target's build settings, list them under "Alternate App Icon Sets" (or declare them in
/// Info.plist under `CFBundleIcons` → `CFBundleAlternateIcons`).
public struct KitoAppIconOption: Identifiable, Hashable, Sendable {
    /// The alternate icon's name as the system knows it; nil for the primary icon.
    public var alternateIconName: String?
    public var title: String
    /// A preview image from your asset catalog (app icon sets can't be loaded as images, so ship
    /// a copy as an image set). Without one, `colors` and `systemImage` draw a stand-in.
    public var previewImageName: String?
    public var colors: [Color]
    public var systemImage: String

    public var id: String { alternateIconName ?? "primary" }

    public init(_ title: String, alternateIconName: String?, previewImageName: String? = nil,
                colors: [Color] = [.blue, .indigo], systemImage: String = "app.fill") {
        self.title = title
        self.alternateIconName = alternateIconName
        self.previewImageName = previewImageName
        self.colors = colors
        self.systemImage = systemImage
    }
}

/// Changes the app's icon where the system allows it.
@MainActor
public enum KitoAppIcon {
    /// False in extensions, on the Mac, or when the app declares no alternate icons.
    public static var isSupported: Bool { UIApplication.shared.supportsAlternateIcons }

    /// The alternate icon in use; nil for the primary icon.
    public static var current: String? { UIApplication.shared.alternateIconName }

    /// Switches to `name` (nil for the primary icon). iOS shows its own confirmation alert.
    public static func set(_ name: String?) async throws {
        guard isSupported else { throw KitoAppIconError.unsupported }
        guard current != name else { return }
        try await UIApplication.shared.setAlternateIconName(name)
    }
}

public enum KitoAppIconError: Error, Equatable, Sendable {
    /// This device or build can't change icons.
    case unsupported
}
