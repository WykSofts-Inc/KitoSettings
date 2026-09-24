//
//  KitoLicensesList.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The acknowledgements: every library with its licence, searchable, each opening to its text.
public struct KitoLicensesList: View {
    private let licenses: [KitoLicense]
    private let style: KitoSettingsStyle?
    private let tint: Color?

    public init(licenses: [KitoLicense], style: KitoSettingsStyle? = nil, tint: Color? = nil) {
        self.licenses = licenses
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        KitoSettingsList(style: style, tint: tint,
                         searchPrompt: licenses.count > 6 ? "Search libraries" : nil) {
            KitoSettingsSection(footer: "Thank you to everyone who builds in the open.") {
                for license in licenses {
                    KitoCustomRow(license.name, keywords: [license.license]) {
                        KitoLicenseRow(license: license)
                    }
                }
            }
        }
        .navigationTitle("Acknowledgements")
    }
}

/// A library's name and licence; tapping shows the text and a link.
struct KitoLicenseRow: View {
    let license: KitoLicense

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var tint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var isOpen = false

    private var accent: Color { tint ?? theme.colors.primary }
    private var canOpen: Bool { license.text != nil || license.url != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) { isOpen.toggle() }
            } label: {
                HStack(spacing: theme.spacing.md) {
                    Text(license.name)
                        .font(theme.settingsFont(.body))
                        .foregroundStyle(theme.colors.onSurface)
                    Spacer(minLength: theme.spacing.sm)
                    Text(license.license)
                        .font(theme.settingsFont(.caption).weight(.semibold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(accent.opacity(0.12)))
                    if canOpen {
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(theme.colors.onSurface.opacity(0.3))
                            .rotationEffect(.degrees(isOpen ? 180 : 0))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canOpen)
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            if isOpen { details.transition(.opacity.combined(with: .move(edge: .top))) }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if let text = license.text {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.7))
                    .textSelection(.enabled)
                    .padding(theme.spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous).fill(theme.colors.surfaceMuted))
            }
            if let url = license.url {
                Button { openURL(url) } label: {
                    Label(url.host ?? url.absoluteString, systemImage: "arrow.up.right.square")
                        .font(theme.settingsFont(.label))
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
