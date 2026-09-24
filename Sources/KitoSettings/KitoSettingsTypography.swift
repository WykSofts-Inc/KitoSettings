//
//  KitoSettingsTypography.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The text roles settings views use.
enum KitoSettingsTextRole {
    case display, title, headline, body, bodyEmphasized, label, caption, button
}

extension KitoTheme {
    /// The theme's font for `role`. With the default typography, the matching Dynamic Type text
    /// style is used instead so text grows with the reader's text size; a custom typography is
    /// always respected as given.
    func settingsFont(_ role: KitoSettingsTextRole) -> Font {
        typography == .default ? Self.dynamicFont(role) : themedFont(role)
    }

    private func themedFont(_ role: KitoSettingsTextRole) -> Font {
        switch role {
        case .display: return typography.displayMedium
        case .title: return typography.titleLarge
        case .headline: return typography.titleMedium
        case .body: return typography.body
        case .bodyEmphasized: return typography.bodyEmphasized
        case .label: return typography.label
        case .caption: return typography.caption
        case .button: return typography.button
        }
    }

    private static func dynamicFont(_ role: KitoSettingsTextRole) -> Font {
        switch role {
        case .display: return .title.weight(.bold)
        case .title: return .title2.weight(.semibold)
        case .headline: return .headline
        case .body: return .body
        case .bodyEmphasized: return .body.weight(.medium)
        case .label: return .subheadline.weight(.medium)
        case .caption: return .caption
        case .button: return .body.weight(.semibold)
        }
    }
}
