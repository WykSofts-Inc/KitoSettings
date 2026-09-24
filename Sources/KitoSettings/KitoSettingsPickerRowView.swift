//
//  KitoSettingsPickerRowView.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A picker row in one of its four styles.
struct KitoSettingsPickerRowView: View {
    let row: KitoSettingsRow
    let picker: KitoAnyPicker
    let style: KitoSettingsStyle
    let tint: Color

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsSheet = false
    @Namespace private var segment

    var body: some View {
        switch picker.style {
        case .menu: menu
        case .inline: inline
        case .sheet: sheet
        case .segmented: segmented
        }
    }

    private var label: some View {
        HStack(spacing: theme.spacing.md) {
            KitoSettingsRowLabel(row: row, style: style, tint: tint)
            Spacer(minLength: theme.spacing.sm)
            if let badge = row.badge { KitoSettingsBadgeView(badge, tint: tint) }
        }
    }

    private func select(_ id: AnyHashable) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
            picker.selection.wrappedValue = id
        }
    }

    // MARK: Menu

    private var menu: some View {
        HStack(spacing: theme.spacing.md) {
            label
            Menu {
                ForEach(picker.options) { option in
                    Button { select(option.id) } label: {
                        if option.id == picker.selection.wrappedValue {
                            Label(option.title, systemImage: "checkmark")
                        } else if let symbol = option.systemImage {
                            Label(option.title, systemImage: symbol)
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                KitoSettingsChevron(value: picker.selectedTitle, symbol: "chevron.up.chevron.down")
            }
            .accessibilityLabel(row.title)
            .accessibilityValue(picker.selectedTitle ?? "")
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.sm)
        .frame(maxWidth: .infinity, minHeight: style.rowMinHeight, alignment: .leading)
    }

    // MARK: Inline

    private var inline: some View {
        VStack(alignment: .leading, spacing: 0) {
            label
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.sm)
                .frame(minHeight: style.rowMinHeight)
                .accessibilityAddTraits(.isHeader)
            ForEach(picker.options) { option in
                KitoSettingsOptionRow(option: option, isSelected: option.id == picker.selection.wrappedValue,
                                      tint: tint) { select(option.id) }
            }
        }
    }

    // MARK: Sheet

    private var sheet: some View {
        Button { showsSheet = true } label: {
            HStack(spacing: theme.spacing.md) {
                label
                KitoSettingsChevron(value: picker.selectedTitle)
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.sm)
            .frame(maxWidth: .infinity, minHeight: style.rowMinHeight, alignment: .leading)
        }
        .buttonStyle(KitoSettingsRowPressStyle())
        .accessibilityValue(picker.selectedTitle ?? "")
        .sheet(isPresented: $showsSheet) {
            KitoSettingsOptionSheet(title: row.title, picker: picker, tint: tint) { id in
                select(id)
                showsSheet = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: Segmented

    private var segmented: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            label
            HStack(spacing: 0) {
                ForEach(picker.options) { option in
                    segmentButton(option)
                }
            }
            .padding(3)
            .background(Capsule().fill(theme.colors.surfaceMuted))
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
    }

    private func segmentButton(_ option: KitoAnyPicker.Option) -> some View {
        let isSelected = option.id == picker.selection.wrappedValue
        return Button { select(option.id) } label: {
            HStack(spacing: theme.spacing.xs) {
                if let symbol = option.systemImage { Image(systemName: symbol) }
                Text(option.title).lineLimit(1).minimumScaleFactor(0.8)
            }
            .font(theme.settingsFont(.label))
            .foregroundStyle(isSelected ? theme.colors.onSurface : theme.colors.onSurface.opacity(0.6))
            .frame(maxWidth: .infinity, minHeight: 34)
            .background {
                if isSelected {
                    Capsule()
                        .fill(theme.colors.surface)
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
                        .matchedGeometryEffect(id: "segment", in: segment)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// An option with a checkmark that springs in when chosen.
struct KitoSettingsOptionRow: View {
    let option: KitoAnyPicker.Option
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.md) {
                if let symbol = option.systemImage {
                    Image(systemName: symbol)
                        .foregroundStyle(isSelected ? tint : theme.colors.onSurface.opacity(0.5))
                        .frame(width: 24)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(theme.settingsFont(isSelected ? .bodyEmphasized : .body))
                        .foregroundStyle(theme.colors.onSurface)
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(theme.settingsFont(.caption))
                            .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                    }
                }
                Spacer(minLength: theme.spacing.sm)
                KitoSettingsCheckmark(isOn: isSelected, tint: tint)
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        }
        .buttonStyle(KitoSettingsRowPressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A filled check that scales in, or an empty ring.
struct KitoSettingsCheckmark: View {
    let isOn: Bool
    let tint: Color

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(theme.colors.border, lineWidth: 1.5)
                .opacity(isOn ? 0 : 1)
            if isOn {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, tint)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}

/// The list a `.sheet` picker opens.
struct KitoSettingsOptionSheet: View {
    let title: String
    let picker: KitoAnyPicker
    let tint: Color
    let onSelect: (AnyHashable) -> Void

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text(title)
                    .font(theme.settingsFont(.title))
                    .foregroundStyle(theme.colors.onBackground)
                    .padding(.horizontal, theme.spacing.xs)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    ForEach(picker.options) { option in
                        KitoSettingsOptionRow(option: option, isSelected: option.id == picker.selection.wrappedValue,
                                              tint: tint) { onSelect(option.id) }
                        if option.id != picker.options.last?.id {
                            Divider().padding(.leading, theme.spacing.lg)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous).fill(theme.colors.surface))
            }
            .padding(theme.spacing.lg)
            .padding(.top, theme.spacing.md)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }
}
