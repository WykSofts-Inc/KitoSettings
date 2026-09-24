//
//  KitoSettingsBuilders.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Collects rows for a `KitoSettingsSection`, with `if`, `if let`, `switch` and `for` support.
@resultBuilder
public enum KitoSettingsRowBuilder {
    public static func buildExpression<Row: KitoSettingsRowConvertible>(_ row: Row) -> [KitoSettingsRow] {
        [row.settingsRow]
    }

    public static func buildExpression(_ rows: [KitoSettingsRow]) -> [KitoSettingsRow] { rows }

    public static func buildBlock(_ parts: [KitoSettingsRow]...) -> [KitoSettingsRow] {
        parts.flatMap { $0 }
    }

    public static func buildOptional(_ rows: [KitoSettingsRow]?) -> [KitoSettingsRow] { rows ?? [] }

    public static func buildEither(first rows: [KitoSettingsRow]) -> [KitoSettingsRow] { rows }

    public static func buildEither(second rows: [KitoSettingsRow]) -> [KitoSettingsRow] { rows }

    public static func buildArray(_ parts: [[KitoSettingsRow]]) -> [KitoSettingsRow] { parts.flatMap { $0 } }

    public static func buildLimitedAvailability(_ rows: [KitoSettingsRow]) -> [KitoSettingsRow] { rows }
}

/// Collects sections for a `KitoSettingsList`.
@resultBuilder
public enum KitoSettingsSectionBuilder {
    public static func buildExpression(_ section: KitoSettingsSection) -> [KitoSettingsSection] { [section] }

    public static func buildExpression(_ sections: [KitoSettingsSection]) -> [KitoSettingsSection] { sections }

    public static func buildBlock(_ parts: [KitoSettingsSection]...) -> [KitoSettingsSection] {
        parts.flatMap { $0 }
    }

    public static func buildOptional(_ sections: [KitoSettingsSection]?) -> [KitoSettingsSection] {
        sections ?? []
    }

    public static func buildEither(first sections: [KitoSettingsSection]) -> [KitoSettingsSection] { sections }

    public static func buildEither(second sections: [KitoSettingsSection]) -> [KitoSettingsSection] { sections }

    public static func buildArray(_ parts: [[KitoSettingsSection]]) -> [KitoSettingsSection] {
        parts.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ sections: [KitoSettingsSection]) -> [KitoSettingsSection] {
        sections
    }
}
