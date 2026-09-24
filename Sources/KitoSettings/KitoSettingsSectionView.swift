//
//  KitoSettingsSectionView.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

extension KitoSettingsSection: View {
    /// The section on its own, in the environment's style.
    public var body: some View {
        KitoSettingsSectionView(section: self, style: nil, tint: nil)
    }
}

/// A section's header, its rows in the style's container, and its footer.
struct KitoSettingsSectionView: View {
    let section: KitoSettingsSection
    let style: KitoSettingsStyle?
    let tint: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsStyle) private var environmentStyle
    @Environment(\.kitoSettingsTint) private var environmentTint
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    private var resolvedStyle: KitoSettingsStyle { style ?? environmentStyle }
    private var resolvedTint: Color { tint ?? environmentTint ?? theme.colors.primary }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if let title = section.title { header(title) }
            rows
                .modifier(KitoSettingsGroupBackground(style: resolvedStyle, tint: resolvedTint))
            if let footer = section.footer {
                Text(footer)
                    .font(theme.settingsFont(.caption))
                    .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                    .padding(.horizontal, footerInset)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var footerInset: CGFloat { resolvedStyle == .minimal ? 0 : theme.spacing.lg }

    @ViewBuilder private func header(_ title: String) -> some View {
        switch resolvedStyle {
        case .insetGrouped:
            Text(title.uppercased())
                .font(theme.settingsFont(.caption).weight(.semibold))
                .kerning(0.4)
                .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                .padding(.horizontal, theme.spacing.lg)
                .accessibilityAddTraits(.isHeader)
        case .cards:
            Text(title)
                .font(theme.settingsFont(.label).weight(.semibold))
                .foregroundStyle(theme.colors.onBackground.opacity(0.75))
                .padding(.horizontal, theme.spacing.xs)
                .accessibilityAddTraits(.isHeader)
        case .minimal:
            Text(title.uppercased())
                .font(theme.settingsFont(.caption).weight(.bold))
                .kerning(1.2)
                .foregroundStyle(resolvedTint)
                .accessibilityAddTraits(.isHeader)
        case .bold:
            Text(title)
                .font(theme.settingsFont(.title).weight(.bold))
                .foregroundStyle(theme.colors.onBackground)
                .padding(.horizontal, theme.spacing.xs)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                KitoSettingsRowView(row: row, style: resolvedStyle, tint: resolvedTint)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                if index < section.rows.count - 1 {
                    divider(before: section.rows[index + 1], after: row)
                }
            }
        }
    }

    private func divider(before next: KitoSettingsRow, after row: KitoSettingsRow) -> some View {
        Rectangle()
            .fill(theme.colors.border.opacity(resolvedStyle == .minimal ? 0.8 : 0.6))
            .frame(height: 0.5)
            .padding(.leading, dividerInset(row))
    }

    /// Dividers start after the icon, like iOS; minimal and icon-less rows run full width.
    private func dividerInset(_ row: KitoSettingsRow) -> CGFloat {
        guard resolvedStyle != .minimal else { return 0 }
        guard row.icon != nil, !isInfo(row) else { return theme.spacing.lg }
        let icon = min(resolvedStyle.iconSize * scale, resolvedStyle.iconSize * 1.6)
        return theme.spacing.lg + icon + theme.spacing.md
    }

    private func isInfo(_ row: KitoSettingsRow) -> Bool {
        if case .info = row.kind { return true }
        return false
    }
}

/// The container behind a section's rows for each style.
struct KitoSettingsGroupBackground: ViewModifier {
    let style: KitoSettingsStyle
    let tint: Color

    @Environment(\.kitoTheme) private var theme

    func body(content: Content) -> some View {
        switch style {
        case .insetGrouped:
            content
                .background(theme.colors.surface)
                .clipShape(shape(theme.radii.lg))
                .overlay(shape(theme.radii.lg).strokeBorder(theme.colors.border.opacity(0.5), lineWidth: 0.5))
        case .cards:
            content
                .background(theme.colors.surface)
                .clipShape(shape(theme.radii.xl))
                .overlay(shape(theme.radii.xl).strokeBorder(theme.colors.border.opacity(0.6), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        case .minimal:
            content
        case .bold:
            content
                .background(boldFill)
                .clipShape(shape(theme.radii.xl + 4))
                .overlay(shape(theme.radii.xl + 4).strokeBorder(boldStroke, lineWidth: 1))
                .shadow(color: tint.opacity(0.10), radius: 16, x: 0, y: 8)
        }
    }

    private func shape(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    private var boldFill: some View {
        ZStack {
            theme.colors.surface
            LinearGradient(colors: [tint.opacity(0.07), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var boldStroke: LinearGradient {
        LinearGradient(colors: [tint.opacity(0.35), theme.colors.border.opacity(0.4)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
