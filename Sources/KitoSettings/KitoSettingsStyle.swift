//
//  KitoSettingsStyle.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// How a settings list looks.
public enum KitoSettingsStyle: String, CaseIterable, Identifiable, Sendable {
    /// Like iOS Settings: rounded groups, small coloured icon squares, inset dividers.
    case insetGrouped
    /// Each section is a raised card with soft, tinted icon circles and roomier rows.
    case cards
    /// No boxes: plain rows, tinted glyphs and hairline dividers.
    case minimal
    /// Large gradient icon tiles with a glossy highlight and bolder type.
    case bold

    public var id: Self { self }

    public var title: String {
        switch self {
        case .insetGrouped: return "Inset grouped"
        case .cards: return "Cards"
        case .minimal: return "Minimal"
        case .bold: return "Bold"
        }
    }

    /// The icon tile's side, before Dynamic Type scaling.
    var iconSize: CGFloat {
        switch self {
        case .insetGrouped: return 30
        case .cards: return 36
        case .minimal: return 24
        case .bold: return 38
        }
    }

    var rowMinHeight: CGFloat {
        switch self {
        case .insetGrouped: return 50
        case .cards: return 60
        case .minimal: return 52
        case .bold: return 62
        }
    }

    var usesGroupBackground: Bool { self != .minimal }
}

/// An icon for a row: an SF Symbol and the colour of its tile.
public struct KitoSettingsIcon: Hashable, Sendable {
    public var systemName: String
    /// Nil uses the list's tint.
    public var color: Color?

    public init(_ systemName: String, color: Color? = nil) {
        self.systemName = systemName
        self.color = color
    }
}

/// A small label on a row: "New", a count or a dot.
public enum KitoSettingsBadge: Hashable, Sendable {
    case new
    case count(Int)
    case text(String)
    case dot

    /// What the badge reads; nil for a dot or a count of zero.
    public var label: String? {
        switch self {
        case .new: return "New"
        case .count(let value): return Self.countLabel(value)
        case .text(let text): return text.isEmpty ? nil : text
        case .dot: return nil
        }
    }

    /// Whether anything shows: a zero count hides the badge.
    public var isVisible: Bool {
        switch self {
        case .count(let value): return value > 0
        case .text(let text): return !text.isEmpty
        case .new, .dot: return true
        }
    }

    /// For VoiceOver: "New", "3 new", "More than 99 new".
    public var accessibilityLabel: String {
        switch self {
        case .new: return "New"
        case .count(let value): return value > 99 ? "More than 99 new" : "\(value) new"
        case .text(let text): return text
        case .dot: return "Needs attention"
        }
    }

    /// "7", "99+", nil for zero or less.
    static func countLabel(_ value: Int) -> String? {
        guard value > 0 else { return nil }
        return value > 99 ? "99+" : "\(value)"
    }
}

// MARK: - Environment

private struct KitoSettingsStyleKey: EnvironmentKey {
    static let defaultValue: KitoSettingsStyle = .insetGrouped
}

private struct KitoSettingsTintKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private struct KitoSettingsQueryKey: EnvironmentKey {
    static let defaultValue = ""
}

public extension EnvironmentValues {
    /// The style settings lists and screens in this subtree use.
    var kitoSettingsStyle: KitoSettingsStyle {
        get { self[KitoSettingsStyleKey.self] }
        set { self[KitoSettingsStyleKey.self] = newValue }
    }

    /// The accent settings views use instead of the theme's primary colour.
    var kitoSettingsTint: Color? {
        get { self[KitoSettingsTintKey.self] }
        set { self[KitoSettingsTintKey.self] = newValue }
    }
}

extension EnvironmentValues {
    /// The search text, so rows can highlight what matched.
    var kitoSettingsQuery: String {
        get { self[KitoSettingsQueryKey.self] }
        set { self[KitoSettingsQueryKey.self] = newValue }
    }
}

public extension View {
    /// Styles every settings list and ready-made settings screen in this view.
    func kitoSettingsStyle(_ style: KitoSettingsStyle) -> some View {
        environment(\.kitoSettingsStyle, style)
    }

    /// Accents every settings view in this view with `tint`.
    func kitoSettingsTint(_ tint: Color?) -> some View {
        environment(\.kitoSettingsTint, tint)
    }
}
