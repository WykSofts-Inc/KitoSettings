//
//  KitoSettingsRowView.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UIKit
import KitoCore

/// Draws one row for the current style.
struct KitoSettingsRowView: View {
    let row: KitoSettingsRow
    let style: KitoSettingsStyle
    let tint: Color

    @Environment(\.kitoTheme) private var theme
    @Environment(\.openURL) private var openURL
    @Environment(\.kitoSettingsQuery) private var query
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var confirming = false
    @State private var copied = false

    var body: some View {
        content
            .disabled(row.isDisabled)
            .opacity(row.isDisabled ? 0.45 : 1)
    }

    @ViewBuilder private var content: some View {
        switch row.kind {
        case .navigation(let value, let destination):
            NavigationLink { destination() } label: {
                line { KitoSettingsChevron(value: value) }
            }
            .buttonStyle(KitoSettingsRowPressStyle())
        case .toggle(let isOn):
            toggleRow(isOn)
        case .picker(let picker):
            KitoSettingsPickerRowView(row: row, picker: picker, style: style, tint: tint)
        case .stepper(let stepper):
            line { KitoSettingsStepperControl(stepper: stepper, tint: tint, title: row.title) }
        case .slider(let slider):
            KitoSettingsSliderRowView(row: row, slider: slider, style: style, tint: tint)
        case .value(let value, let isCopyable):
            valueRow(value, isCopyable: isCopyable)
        case .action(let role, let showsChevron, let confirmation, let action):
            actionRow(role: role, showsChevron: showsChevron, confirmation: confirmation, action: action)
        case .link(let url, let value):
            Button { openURL(url) } label: {
                line { KitoSettingsChevron(value: value, symbol: "arrow.up.right") }
            }
            .buttonStyle(KitoSettingsRowPressStyle())
            .accessibilityHint("Opens \(url.host ?? "a link")")
            .accessibilityAddTraits(.isLink)
        case .info:
            infoRow
        case .custom(let content):
            content()
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Layout

    /// Icon, title and subtitle, then `accessory`. Stacks the accessory under the text at the
    /// largest text sizes so nothing gets squeezed.
    func line<Accessory: View>(titleColor: Color? = nil,
                               @ViewBuilder accessory: () -> Accessory) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.sm))
            : AnyLayout(HStackLayout(spacing: theme.spacing.md))
        return layout {
            HStack(spacing: theme.spacing.md) {
                KitoSettingsRowLabel(row: row, style: style, tint: tint, titleColor: titleColor)
                if !typeSize.isAccessibilitySize { Spacer(minLength: theme.spacing.sm) }
                if let badge = row.badge { KitoSettingsBadgeView(badge, tint: tint) }
            }
            accessory()
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.sm)
        .frame(maxWidth: .infinity, minHeight: style.rowMinHeight, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func toggleRow(_ isOn: Binding<Bool>) -> some View {
        line {
            Toggle(row.title, isOn: isOn)
                .labelsHidden()
                .tint(tint)
        }
        .onTapGesture { isOn.wrappedValue.toggle() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.title)
        .accessibilityValue(isOn.wrappedValue ? "On" : "Off")
        .accessibilityHint(row.subtitle ?? "")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { isOn.wrappedValue.toggle() }
        .sensoryFeedback(.selection, trigger: isOn.wrappedValue)
    }

    private func valueRow(_ value: String, isCopyable: Bool) -> some View {
        line {
            Text(copied ? "Copied" : value)
                .font(theme.settingsFont(.body))
                .monospacedDigit()
                .foregroundStyle(copied ? tint : theme.colors.onSurface.opacity(0.55))
                .contentTransition(.opacity)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
        .contextMenu {
            if isCopyable {
                Button { copy(value) } label: { Label("Copy", systemImage: "doc.on.doc") }
            }
        }
    }

    private func copy(_ value: String) {
        UIPasteboard.general.string = value
        withAnimation(.snappy) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.snappy) { copied = false }
        }
    }

    private func actionRow(role: ButtonRole?, showsChevron: Bool, confirmation: String?,
                           action: @escaping () -> Void) -> some View {
        let isDestructive = role == .destructive
        return Button(role: role) {
            if confirmation == nil { action() } else { confirming = true }
        } label: {
            line(titleColor: isDestructive ? theme.colors.danger : tint) {
                if showsChevron { KitoSettingsChevron() }
            }
        }
        .buttonStyle(KitoSettingsRowPressStyle())
        .confirmationDialog(confirmation ?? row.title, isPresented: $confirming, titleVisibility: .visible) {
            Button(row.title, role: role, action: action)
            Button("Cancel", role: .cancel) {}
        }
    }

    private var infoRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
            if let icon = row.icon {
                Image(systemName: icon.systemName)
                    .foregroundStyle(icon.color ?? tint)
                    .accessibilityHidden(true)
            }
            Text(row.title)
                .font(theme.settingsFont(.caption))
                .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.06))
        .accessibilityElement(children: .combine)
    }
}

/// The icon tile, the title (with the search match highlighted) and the subtitle.
struct KitoSettingsRowLabel: View {
    let row: KitoSettingsRow
    let style: KitoSettingsStyle
    let tint: Color
    var titleColor: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsQuery) private var query

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            if let icon = row.icon {
                KitoSettingsIconTile(icon, style: style, tint: titleColor ?? tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(highlightedTitle)
                    .font(theme.settingsFont(style == .bold ? .bodyEmphasized : .body))
                    .foregroundStyle(titleColor ?? theme.colors.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(theme.settingsFont(.caption))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var highlightedTitle: AttributedString {
        var text = AttributedString(row.title)
        guard let range = KitoSettingsSearch.highlightRange(in: row.title, query: query),
              let lower = AttributedString.Index(range.lowerBound, within: text),
              let upper = AttributedString.Index(range.upperBound, within: text) else { return text }
        text[lower..<upper].foregroundColor = tint
        text[lower..<upper].inlinePresentationIntent = .stronglyEmphasized
        return text
    }
}
