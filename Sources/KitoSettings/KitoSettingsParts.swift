//
//  KitoSettingsParts.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A row icon drawn for a style: a coloured square, a soft circle, a bare glyph or a glossy tile.
public struct KitoSettingsIconTile: View {
    private let icon: KitoSettingsIcon
    private let style: KitoSettingsStyle?
    private let tint: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsStyle) private var environmentStyle
    @Environment(\.kitoSettingsTint) private var environmentTint
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    public init(_ icon: KitoSettingsIcon, style: KitoSettingsStyle? = nil, tint: Color? = nil) {
        self.icon = icon
        self.style = style
        self.tint = tint
    }

    private var resolvedStyle: KitoSettingsStyle { style ?? environmentStyle }
    private var color: Color { icon.color ?? tint ?? environmentTint ?? theme.colors.primary }
    private var side: CGFloat { min(resolvedStyle.iconSize * scale, resolvedStyle.iconSize * 1.6) }

    public var body: some View {
        tile
            .frame(width: side, height: side)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var tile: some View {
        switch resolvedStyle {
        case .insetGrouped: square
        case .cards: circle
        case .minimal: glyph(color, weight: .medium, ratio: 0.8)
        case .bold: glossy
        }
    }

    private func glyph(_ color: Color, weight: Font.Weight, ratio: CGFloat) -> some View {
        Image(systemName: icon.systemName)
            .font(.system(size: side * ratio * 0.62, weight: weight))
            .foregroundStyle(color)
            .symbolRenderingMode(.hierarchical)
    }

    private var square: some View {
        RoundedRectangle(cornerRadius: side * 0.26, style: .continuous)
            .fill(color.gradient)
            .overlay(glyph(.white, weight: .semibold, ratio: 0.85))
    }

    private var circle: some View {
        Circle()
            .fill(color.opacity(0.14))
            .overlay(Circle().strokeBorder(color.opacity(0.22), lineWidth: 1))
            .overlay(glyph(color, weight: .semibold, ratio: 0.8))
    }

    private var glossy: some View {
        let shape = RoundedRectangle(cornerRadius: side * 0.3, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [color.opacity(0.75), color], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(shape.fill(Self.shine).padding(1))
            .overlay(shape.strokeBorder(.white.opacity(0.25), lineWidth: 0.8))
            .overlay(glyph(.white, weight: .bold, ratio: 0.85))
            .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)
    }

    private static let shine = LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0)],
                                              startPoint: .top, endPoint: .center)
}

/// A "New", count or dot badge.
public struct KitoSettingsBadgeView: View {
    private let badge: KitoSettingsBadge
    private let tint: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var environmentTint

    public init(_ badge: KitoSettingsBadge, tint: Color? = nil) {
        self.badge = badge
        self.tint = tint
    }

    private var fill: Color {
        switch badge {
        case .count, .dot: return theme.colors.danger
        case .new, .text: return tint ?? environmentTint ?? theme.colors.primary
        }
    }

    public var body: some View {
        Group {
            if badge.isVisible {
                content
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .accessibilityLabel(badge.accessibilityLabel)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let label = badge.label {
            Text(label)
                .font(.caption2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .frame(minWidth: 20)
                .background(Capsule().fill(fill.gradient))
                .shadow(color: fill.opacity(0.3), radius: 3, x: 0, y: 1)
        } else {
            Circle().fill(fill).frame(width: 9, height: 9)
                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
        }
    }
}

/// Highlights a row while it's pressed.
struct KitoSettingsRowPressStyle: ButtonStyle {
    @Environment(\.kitoTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(theme.colors.onSurface.opacity(configuration.isPressed ? 0.07 : 0))
            .contentShape(Rectangle())
    }
}

/// The chevron and grey value at the end of a navigation row.
struct KitoSettingsChevron: View {
    var value: String?
    var symbol = "chevron.forward"
    @Environment(\.kitoTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            if let value {
                Text(value)
                    .font(theme.settingsFont(.body))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                    .lineLimit(1)
            }
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(theme.colors.onSurface.opacity(0.3))
        }
    }
}
