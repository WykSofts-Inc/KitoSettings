//
//  KitoSettingsRows.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

private func kitoIcon(_ systemImage: String?, _ color: Color?) -> KitoSettingsIcon? {
    systemImage.map { KitoSettingsIcon($0, color: color) }
}

/// Opens another screen: a chevron, and the current value in grey.
/// Needs a `NavigationStack` above the list.
public struct KitoNavigationRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init<Destination: View>(_ title: String, systemImage: String? = nil, color: Color? = nil,
                                   subtitle: String? = nil, value: String? = nil,
                                   @ViewBuilder destination: @escaping () -> Destination) {
        settingsRow = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                      kind: .navigation(value: value, destination: { AnyView(destination()) }))
    }
}

/// An on/off switch.
public struct KitoToggleRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init(_ title: String, systemImage: String? = nil, color: Color? = nil,
                subtitle: String? = nil, isOn: Binding<Bool>) {
        settingsRow = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                      kind: .toggle(isOn))
    }
}

/// One choice from a list, as a menu, inline checkmarks, a sheet or a segmented control.
public struct KitoPickerRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init<Value: Hashable>(_ title: String, systemImage: String? = nil, color: Color? = nil,
                                 subtitle: String? = nil, selection: Binding<Value>,
                                 options: [KitoPickerOption<Value>], style: KitoPickerRowStyle = .menu) {
        let erased = Binding<AnyHashable>(
            get: { AnyHashable(selection.wrappedValue) },
            set: { newValue in
                if let value = newValue.base as? Value { selection.wrappedValue = value }
            }
        )
        let anyOptions = options.map {
            KitoAnyPicker.Option(id: AnyHashable($0.value), title: $0.title,
                                 subtitle: $0.subtitle, systemImage: $0.systemImage)
        }
        let picker = KitoAnyPicker(options: anyOptions, selection: erased, style: style)
        let row = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                  kind: .picker(picker))
        // Options are searchable too: "français" finds the Language row.
        settingsRow = row.keywordsList(options.map(\.title))
    }
}

/// A whole number with minus and plus buttons.
public struct KitoStepperRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init(_ title: String, systemImage: String? = nil, color: Color? = nil, subtitle: String? = nil,
                value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1,
                format: ((Int) -> String)? = nil) {
        let stepper = KitoAnyStepper(value: value, range: range, step: max(1, step),
                                     format: format ?? { "\($0)" })
        settingsRow = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                      kind: .stepper(stepper))
    }
}

/// A slider under the title, with the value on the right and optional end symbols.
public struct KitoSliderRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init(_ title: String, systemImage: String? = nil, color: Color? = nil, subtitle: String? = nil,
                value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double? = nil,
                minimumSymbol: String? = nil, maximumSymbol: String? = nil,
                format: ((Double) -> String)? = nil) {
        let slider = KitoAnySlider(value: value, range: range, step: step,
                                   minimumSymbol: minimumSymbol, maximumSymbol: maximumSymbol,
                                   format: format ?? KitoSliderRow.percent)
        settingsRow = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                      kind: .slider(slider))
    }

    static func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
}

/// A read-only value, such as a version or an email. Copyable with a long press when asked.
public struct KitoValueRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init(_ title: String, systemImage: String? = nil, color: Color? = nil, subtitle: String? = nil,
                value: String, isCopyable: Bool = false) {
        settingsRow = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                      kind: .value(value, isCopyable: isCopyable))
    }
}

/// A button. With `role: .destructive` it reads in the danger colour; with `confirmation`
/// it asks first.
public struct KitoActionRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init(_ title: String, systemImage: String? = nil, color: Color? = nil, subtitle: String? = nil,
                role: ButtonRole? = nil, showsChevron: Bool = false, confirmation: String? = nil,
                action: @escaping () -> Void) {
        settingsRow = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                      kind: .action(role: role, showsChevron: showsChevron,
                                                    confirmation: confirmation, action: action))
    }
}

/// Opens a web page (or any URL) with an arrow out.
public struct KitoLinkRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init(_ title: String, systemImage: String? = nil, color: Color? = nil, subtitle: String? = nil,
                value: String? = nil, url: URL) {
        settingsRow = KitoSettingsRow(title: title, subtitle: subtitle, icon: kitoIcon(systemImage, color),
                                      kind: .link(url, value: value))
    }
}

/// A line of explanation inside a section.
public struct KitoInfoRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init(_ text: String, systemImage: String? = "info.circle.fill", color: Color? = nil) {
        settingsRow = KitoSettingsRow(title: text, icon: kitoIcon(systemImage, color), kind: .info)
    }
}

/// Your own content as a row, still found by the search through its title and keywords.
public struct KitoCustomRow: KitoSettingsRowConvertible {
    public let settingsRow: KitoSettingsRow

    public init<Content: View>(_ title: String, keywords: [String] = [],
                               @ViewBuilder content: @escaping () -> Content) {
        var row = KitoSettingsRow(title: title, kind: .custom({ AnyView(content()) }))
        row.keywords = keywords
        settingsRow = row
    }
}

extension KitoSettingsRow {
    func keywordsList(_ words: [String]) -> KitoSettingsRow {
        var row = self
        row.keywords += words
        return row
    }
}
