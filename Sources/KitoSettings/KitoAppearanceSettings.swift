//
//  KitoAppearanceSettings.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A ready-made Appearance screen: Light, Dark or System on little phone previews, an accent
/// colour grid, an app icon grid and a text size slider with a live preview. Leave out a binding
/// to leave out its section.
///
/// ```swift
/// @KitoSetting(.appearance) private var mode
/// @KitoSetting(.accent) private var accent
///
/// KitoAppearanceSettings(mode: $mode, accent: $accent, textScale: $textScale)
/// ```
public struct KitoAppearanceSettings: View {
    @Binding private var mode: KitoAppearanceMode
    private let accent: Binding<String>?
    private let accents: [KitoAccentOption]
    private let appIcons: [KitoAppIconOption]
    private let textScale: Binding<Double>?
    private let style: KitoSettingsStyle?
    private let tint: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var environmentTint

    public init(mode: Binding<KitoAppearanceMode>, accent: Binding<String>? = nil,
                accents: [KitoAccentOption] = KitoAccentOption.defaults,
                appIcons: [KitoAppIconOption] = [], textScale: Binding<Double>? = nil,
                style: KitoSettingsStyle? = nil, tint: Color? = nil) {
        _mode = mode
        self.accent = accent
        self.accents = accents
        self.appIcons = appIcons
        self.textScale = textScale
        self.style = style
        self.tint = tint
    }

    /// The chosen accent, so the previews and the screen's tint follow it live.
    private var accentColor: Color {
        if let accent, let option = KitoAccentOption.option(accent.wrappedValue, in: accents) {
            return option.color
        }
        return tint ?? environmentTint ?? theme.colors.primary
    }

    public var body: some View {
        KitoSettingsList(style: style, tint: accentColor, searchPrompt: nil) {
            KitoSettingsSection("Appearance") {
                KitoCustomRow("Theme", keywords: ["dark", "light", "mode"]) {
                    KitoAppearanceModePicker(mode: $mode, accent: accentColor)
                }
            }
            if let accent {
                KitoSettingsSection("Accent colour") {
                    KitoCustomRow("Accent colour", keywords: ["tint", "color"]) {
                        KitoAccentGrid(selection: accent, options: accents)
                    }
                }
            }
            if !appIcons.isEmpty {
                KitoSettingsSection("App icon") {
                    KitoCustomRow("App icon") {
                        KitoAppIconGrid(options: appIcons, accent: accentColor)
                    }
                }
            }
            if let textScale {
                KitoSettingsSection("Text size", footer: "Apps that follow Dynamic Type also use the size set in iOS Settings.") {
                    KitoCustomRow("Text size", keywords: ["font", "bigger", "smaller"]) {
                        KitoTextSizeControl(scale: textScale, accent: accentColor)
                    }
                }
            }
        }
        .navigationTitle("Appearance")
    }
}

// MARK: - Mode picker

/// Three phone previews; the chosen one gets a ring and a check.
public struct KitoAppearanceModePicker: View {
    @Binding private var mode: KitoAppearanceMode
    private let accent: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(mode: Binding<KitoAppearanceMode>, accent: Color? = nil) {
        _mode = mode
        self.accent = accent
    }

    private var tint: Color { accent ?? theme.colors.primary }

    public var body: some View {
        HStack(spacing: theme.spacing.md) {
            ForEach(KitoAppearanceMode.allCases) { option in
                card(option)
            }
        }
        .sensoryFeedback(.selection, trigger: mode)
    }

    private func card(_ option: KitoAppearanceMode) -> some View {
        let isSelected = option == mode
        return Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.75)) { mode = option }
        } label: {
            VStack(spacing: theme.spacing.sm) {
                KitoPhonePreview(mode: option, accent: tint)
                    .frame(height: 118)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(isSelected ? tint : theme.colors.border, lineWidth: isSelected ? 2.5 : 1)
                    )
                    .scaleEffect(isSelected && !reduceMotion ? 1.0 : 0.96)
                HStack(spacing: 4) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? tint : theme.colors.onSurface.opacity(0.35))
                    Text(option.title)
                        .font(theme.settingsFont(.label).weight(isSelected ? .bold : .medium))
                        .foregroundStyle(theme.colors.onSurface)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title) appearance")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A tiny phone: status bar, a header in the accent, a few rows and a switch. `.system` is split
/// light and dark down the middle.
public struct KitoPhonePreview: View {
    private let mode: KitoAppearanceMode
    private let accent: Color

    public init(mode: KitoAppearanceMode, accent: Color) {
        self.mode = mode
        self.accent = accent
    }

    public var body: some View {
        Group {
            switch mode {
            case .light: KitoPhoneFace(isDark: false, accent: accent)
            case .dark: KitoPhoneFace(isDark: true, accent: accent)
            case .system:
                ZStack {
                    KitoPhoneFace(isDark: false, accent: accent)
                    KitoPhoneFace(isDark: true, accent: accent).mask(KitoDiagonalHalf())
                }
            }
        }
        .aspectRatio(0.52, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// The right-hand half of a rectangle, cut on a slight diagonal.
struct KitoDiagonalHalf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
