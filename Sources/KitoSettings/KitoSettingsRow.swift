//
//  KitoSettingsRow.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Anything that can go in a `KitoSettingsSection`: every `Kito…Row` type.
public protocol KitoSettingsRowConvertible {
    var settingsRow: KitoSettingsRow { get }
}

/// One row of a settings list. You make rows with the `Kito…Row` types
/// (`KitoToggleRow`, `KitoNavigationRow`, …); this is what they all turn into.
public struct KitoSettingsRow: Identifiable, KitoSettingsRowConvertible, KitoSettingsSearchable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var icon: KitoSettingsIcon?
    /// Extra words the search matches, never shown.
    public var keywords: [String]
    public var badge: KitoSettingsBadge?
    public var isDisabled: Bool
    let kind: Kind

    init(title: String, subtitle: String? = nil, icon: KitoSettingsIcon? = nil, kind: Kind) {
        self.id = title
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.keywords = []
        self.badge = nil
        self.isDisabled = false
        self.kind = kind
    }

    public var settingsRow: KitoSettingsRow { self }
    public var searchTitle: String { title }
    public var searchSubtitle: String? { subtitle }
    public var searchKeywords: [String] { keywords }

    enum Kind {
        case navigation(value: String?, destination: () -> AnyView)
        case toggle(Binding<Bool>)
        case picker(KitoAnyPicker)
        case stepper(KitoAnyStepper)
        case slider(KitoAnySlider)
        case value(String, isCopyable: Bool)
        case action(role: ButtonRole?, showsChevron: Bool, confirmation: String?, action: () -> Void)
        case link(URL, value: String?)
        case info
        case custom(() -> AnyView)
    }
}

public extension KitoSettingsRowConvertible {
    /// Extra words the search should match: `.keywords("wifi", "network")`.
    func keywords(_ words: String...) -> KitoSettingsRow {
        var row = settingsRow
        row.keywords += words
        return row
    }

    /// A "New", count or dot badge before the accessory. A count of zero shows nothing.
    func badge(_ badge: KitoSettingsBadge?) -> KitoSettingsRow {
        var row = settingsRow
        row.badge = badge
        return row
    }

    /// Dims the row and stops it responding.
    func rowDisabled(_ isDisabled: Bool = true) -> KitoSettingsRow {
        var row = settingsRow
        row.isDisabled = isDisabled
        return row
    }

    /// A stable identity when two rows share a title.
    func rowID(_ id: String) -> KitoSettingsRow {
        var row = settingsRow
        row.id = id
        return row
    }
}

// MARK: - Type-erased controls

/// How a picker row shows its options.
public enum KitoPickerRowStyle: Sendable {
    /// A pop-up menu from the value.
    case menu
    /// Every option listed under the title, with a checkmark.
    case inline
    /// A sheet listing the options.
    case sheet
    /// A segmented control under the title, for two to four short options.
    case segmented
}

/// One choice in a `KitoPickerRow`.
public struct KitoPickerOption<Value: Hashable>: Identifiable {
    public var value: Value
    public var title: String
    public var subtitle: String?
    public var systemImage: String?

    public var id: Value { value }

    public init(_ title: String, value: Value, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

struct KitoAnyPicker {
    struct Option: Identifiable {
        let id: AnyHashable
        let title: String
        let subtitle: String?
        let systemImage: String?
    }

    let options: [Option]
    let selection: Binding<AnyHashable>
    let style: KitoPickerRowStyle

    var selectedTitle: String? {
        options.first { $0.id == selection.wrappedValue }?.title
    }
}

struct KitoAnyStepper {
    let value: Binding<Int>
    let range: ClosedRange<Int>
    let step: Int
    let format: (Int) -> String
}

struct KitoAnySlider {
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double?
    let minimumSymbol: String?
    let maximumSymbol: String?
    let format: (Double) -> String
}
