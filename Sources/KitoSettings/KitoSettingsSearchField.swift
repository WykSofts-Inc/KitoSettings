//
//  KitoSettingsSearchField.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The search field at the top of a settings list: a capsule that rings in the tint while
/// focused, with a clear button.
public struct KitoSettingsSearchField: View {
    @Binding private var text: String
    private let prompt: String
    private let tint: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var environmentTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, prompt: String = "Search settings", tint: Color? = nil) {
        _text = text
        self.prompt = prompt
        self.tint = tint
    }

    private var resolvedTint: Color { tint ?? environmentTint ?? theme.colors.primary }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(isFocused ? resolvedTint : theme.colors.onSurface.opacity(0.45))
                .accessibilityHidden(true)
            TextField(prompt, text: $text)
                .font(theme.settingsFont(.body))
                .foregroundStyle(theme.colors.onSurface)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.colors.onSurface.opacity(0.35))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .frame(minHeight: 44)
        .background(Capsule().fill(theme.colors.surface))
        .overlay(Capsule().strokeBorder(ringColor, lineWidth: isFocused ? 1.5 : 0.5))
        .shadow(color: resolvedTint.opacity(isFocused ? 0.18 : 0), radius: 10, x: 0, y: 4)
        .animation(reduceMotion ? nil : .snappy, value: isFocused)
        .animation(reduceMotion ? nil : .snappy, value: text.isEmpty)
    }

    private var ringColor: Color {
        isFocused ? resolvedTint.opacity(0.7) : theme.colors.border
    }
}

/// Shown when the search finds nothing.
struct KitoSettingsNoResults: View {
    let query: String
    let tint: Color

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            ZStack {
                Circle().fill(tint.opacity(0.1)).frame(width: 76, height: 76)
                Circle().strokeBorder(tint.opacity(0.2), lineWidth: 1).frame(width: 96, height: 96)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)
            Text("No settings for “\(query)”")
                .font(theme.settingsFont(.headline))
                .foregroundStyle(theme.colors.onBackground)
                .multilineTextAlignment(.center)
            Text("Check the spelling, or try a broader word like “sound” or “privacy”.")
                .font(theme.settingsFont(.caption))
                .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xxl)
        .accessibilityElement(children: .combine)
    }
}
