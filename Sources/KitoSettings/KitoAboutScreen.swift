//
//  KitoAboutScreen.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UIKit
import KitoCore

/// A ready-made About screen: the app icon, name and a version pill you can tap to copy, your
/// links, an acknowledgements list with each licence, and "Made with love in Nairobi".
///
/// ```swift
/// KitoAboutScreen(appName: "Kito", tagline: "Every kit, live.",
///                 links: [KitoAboutLink("Website", systemImage: "globe", url: site)],
///                 licenses: [KitoLicense("KitoCore", license: "MIT")])
/// ```
public struct KitoAboutScreen: View {
    private let appName: String
    private let tagline: String?
    private let icon: Image?
    private let iconColors: [Color]
    private let iconSymbol: String
    private let version: KitoAppVersion
    private let links: [KitoAboutLink]
    private let licenses: [KitoLicense]
    private let madeIn: String?
    private let copyright: String?
    private let style: KitoSettingsStyle?
    private let tint: Color?

    /// - Parameters:
    ///   - icon: A copy of the app icon as an image; without one a gradient tile with `iconSymbol`.
    ///   - madeIn: "Nairobi" reads "Made with ♥ in Nairobi"; nil hides the line.
    public init(appName: String, tagline: String? = nil, icon: Image? = nil,
                iconColors: [Color] = [], iconSymbol: String = "app.fill",
                version: KitoAppVersion = .current, links: [KitoAboutLink] = [],
                licenses: [KitoLicense] = [], madeIn: String? = "Nairobi", copyright: String? = nil,
                style: KitoSettingsStyle? = nil, tint: Color? = nil) {
        self.appName = appName
        self.tagline = tagline
        self.icon = icon
        self.iconColors = iconColors
        self.iconSymbol = iconSymbol
        self.version = version
        self.links = links
        self.licenses = licenses
        self.madeIn = madeIn
        self.copyright = copyright
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        KitoSettingsList(style: style, tint: tint, searchPrompt: nil) {
            KitoAboutHero(appName: appName, tagline: tagline, icon: icon, iconColors: iconColors,
                          iconSymbol: iconSymbol, version: version)
        } sections: {
            if !links.isEmpty {
                KitoSettingsSection {
                    for link in links {
                        KitoLinkRow(link.title, systemImage: link.systemImage, color: link.color, url: link.url)
                    }
                }
            }
            KitoSettingsSection {
                KitoValueRow("Version", systemImage: "number", color: .gray,
                             value: version.formatted(.standard), isCopyable: true)
                if !licenses.isEmpty {
                    KitoNavigationRow("Acknowledgements", systemImage: "heart.text.square.fill", color: .pink,
                                      value: "\(licenses.count)") {
                        KitoLicensesList(licenses: licenses)
                    }
                }
            }
            if madeIn != nil || copyright != nil {
                KitoSettingsSection {
                    KitoCustomRow("Made in") {
                        KitoMadeIn(city: madeIn, copyright: copyright)
                    }
                }
            }
        }
        .navigationTitle("About")
    }
}

/// The icon, name, tagline and version pill.
struct KitoAboutHero: View {
    let appName: String
    let tagline: String?
    let icon: Image?
    let iconColors: [Color]
    let iconSymbol: String
    let version: KitoAppVersion

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var tint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var copied = false
    @State private var appeared = false

    private var accent: Color { tint ?? theme.colors.primary }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            artwork
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: accent.opacity(0.35), radius: 18, x: 0, y: 10)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.8)
                .opacity(appeared || reduceMotion ? 1 : 0)
                .accessibilityHidden(true)
            VStack(spacing: theme.spacing.xxs) {
                Text(appName)
                    .font(theme.settingsFont(.display))
                    .foregroundStyle(theme.colors.onBackground)
                if let tagline {
                    Text(tagline)
                        .font(theme.settingsFont(.label))
                        .foregroundStyle(theme.colors.onBackground.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            versionPill
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.lg)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.65)) { appeared = true }
        }
    }

    @ViewBuilder private var artwork: some View {
        if let icon {
            icon.resizable().scaledToFill()
        } else {
            let colors = iconColors.isEmpty ? [accent.opacity(0.7), accent] : iconColors
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(Image(systemName: iconSymbol).font(.system(size: 42, weight: .semibold)).foregroundStyle(.white))
                .overlay(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .center))
        }
    }

    private var versionPill: some View {
        Button(action: copy) {
            Label(copied ? "Copied" : version.formatted(.full), systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(theme.settingsFont(.caption).weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, theme.spacing.md)
                .frame(minHeight: 30)
                .foregroundStyle(copied ? theme.colors.onPrimary : theme.colors.onSurface.opacity(0.75))
                .background(Capsule().fill(copied ? AnyShapeStyle(accent) : AnyShapeStyle(theme.colors.surface)))
                .overlay(Capsule().strokeBorder(theme.colors.border, lineWidth: copied ? 0 : 0.5))
                .contentTransition(.opacity)
        }
        .buttonStyle(KitoSettingsScaleButtonStyle())
        .accessibilityHint("Copies the version")
        .sensoryFeedback(.success, trigger: copied) { _, new in new }
    }

    private func copy() {
        UIPasteboard.general.string = version.formatted(.standard)
        withAnimation(.snappy) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation(.snappy) { copied = false } }
    }
}

/// "Made with ♥ in Nairobi" with a heart that beats, and the copyright.
struct KitoMadeIn: View {
    let city: String?
    let copyright: String?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            if let city {
                HStack(spacing: 5) {
                    Text("Made with")
                    Image(systemName: "heart.fill")
                        .foregroundStyle(theme.colors.danger.gradient)
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                        .accessibilityLabel("love")
                    Text("in \(city)")
                }
                .font(theme.settingsFont(.label))
                .foregroundStyle(theme.colors.onSurface)
                .accessibilityElement(children: .combine)
            }
            if let copyright {
                Text(copyright)
                    .font(theme.settingsFont(.caption))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
