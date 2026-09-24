//
//  KitoSettingsSectionModel.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// A titled group of rows. Put sections in a `KitoSettingsList`, or show one on its own in any
/// scroll view.
///
/// ```swift
/// KitoSettingsSection("General", footer: "Applies on every device.") {
///     KitoToggleRow("Haptics", systemImage: "hand.tap.fill", color: .pink, isOn: $haptics)
///     KitoNavigationRow("Language", systemImage: "globe", color: .indigo, value: "Kiswahili") { … }
/// }
/// ```
public struct KitoSettingsSection: Identifiable {
    public var id: String
    public var title: String?
    public var footer: String?
    public var rows: [KitoSettingsRow]

    public init(_ title: String? = nil, footer: String? = nil,
                @KitoSettingsRowBuilder rows: () -> [KitoSettingsRow]) {
        self.init(title: title, footer: footer, rows: rows())
    }

    public init(title: String?, footer: String? = nil, rows: [KitoSettingsRow]) {
        self.id = title ?? rows.first.map { "section-" + $0.id } ?? "section"
        self.title = title
        self.footer = footer
        self.rows = rows
    }

    /// A stable identity when two sections share a title.
    public func sectionID(_ id: String) -> KitoSettingsSection {
        var copy = self
        copy.id = id
        return copy
    }

    /// The sections and rows that match `query`. A section whose title matches keeps all its
    /// rows; other sections keep only matching rows, best first; empty sections are dropped.
    /// Footers are hidden while searching.
    public static func filter(_ sections: [KitoSettingsSection], query: String) -> [KitoSettingsSection] {
        guard !KitoSettingsSearch.tokens(query).isEmpty else { return sections }
        return sections.compactMap { section in
            var copy = section
            copy.footer = nil
            if let title = section.title, KitoSettingsSearch.matches(KitoSearchText(title), query: query) {
                return copy
            }
            copy.rows = KitoSettingsSearch.filter(section.rows, query: query)
            return copy.rows.isEmpty ? nil : copy
        }
    }

    /// How many rows match `query` across `sections`.
    public static func matchCount(_ sections: [KitoSettingsSection], query: String) -> Int {
        filter(sections, query: query).reduce(0) { $0 + $1.rows.count }
    }
}

/// A plain string that the settings search can match.
struct KitoSearchText: KitoSettingsSearchable {
    let searchTitle: String
    var searchSubtitle: String? { nil }
    var searchKeywords: [String] { [] }

    init(_ text: String) { searchTitle = text }
}
