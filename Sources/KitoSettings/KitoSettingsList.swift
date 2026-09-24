//
//  KitoSettingsList.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A complete, scrolling settings screen: an optional header (a profile, a plan card), a search
/// field that filters every row by title and keywords, and your sections in one of four styles.
///
/// ```swift
/// NavigationStack {
///     KitoSettingsList(style: .bold) {
///         KitoSettingsProfileHeader(name: "Wycliff N", detail: "wycliff@example.com", plan: "Kito Pro")
///     } sections: {
///         KitoSettingsSection("General") {
///             KitoToggleRow("Haptics", systemImage: "hand.tap.fill", color: .pink, isOn: $haptics)
///             KitoNavigationRow("Appearance", systemImage: "paintbrush.fill", color: .purple, value: "Dark") {
///                 KitoAppearanceSettings(mode: $mode, accent: $accent)
///             }
///         }
///     }
///     .navigationTitle("Settings")
/// }
/// ```
public struct KitoSettingsList<Header: View>: View {
    private let sections: [KitoSettingsSection]
    private let style: KitoSettingsStyle?
    private let tint: Color?
    private let searchPrompt: String?
    private let header: Header

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsStyle) private var environmentStyle
    @Environment(\.kitoSettingsTint) private var environmentTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var query = ""

    /// - Parameters:
    ///   - style: Nil uses `.kitoSettingsStyle(_:)` from the environment (inset grouped by default).
    ///   - tint: Nil uses `.kitoSettingsTint(_:)`, then the theme's primary colour.
    ///   - searchPrompt: The search field's placeholder; nil hides the field.
    public init(style: KitoSettingsStyle? = nil, tint: Color? = nil,
                searchPrompt: String? = "Search settings",
                @ViewBuilder header: () -> Header,
                @KitoSettingsSectionBuilder sections: () -> [KitoSettingsSection]) {
        self.style = style
        self.tint = tint
        self.searchPrompt = searchPrompt
        self.header = header()
        self.sections = sections()
    }

    private var resolvedStyle: KitoSettingsStyle { style ?? environmentStyle }
    private var resolvedTint: Color { tint ?? environmentTint ?? theme.colors.primary }
    private var isSearching: Bool { !KitoSettingsSearch.tokens(query).isEmpty }
    private var visibleSections: [KitoSettingsSection] { KitoSettingsSection.filter(sections, query: query) }

    public var body: some View {
        ScrollView {
            content
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.sm)
                .padding(.bottom, theme.spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KitoSettingsBackdrop(style: resolvedStyle, tint: resolvedTint).ignoresSafeArea())
        .environment(\.kitoSettingsStyle, resolvedStyle)
        .environment(\.kitoSettingsTint, resolvedTint)
        .environment(\.kitoSettingsQuery, query)
    }

    private var content: some View {
        let visible = visibleSections
        return VStack(alignment: .leading, spacing: sectionSpacing) {
            if !isSearching {
                header.transition(.opacity)
            }
            if let searchPrompt {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    KitoSettingsSearchField(text: $query, prompt: searchPrompt, tint: resolvedTint)
                    if isSearching && !visible.isEmpty { resultCount(visible) }
                }
            }
            if visible.isEmpty && isSearching {
                KitoSettingsNoResults(query: query, tint: resolvedTint)
            }
            ForEach(visible) { section in
                KitoSettingsSectionView(section: section, style: resolvedStyle, tint: resolvedTint)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: query)
    }

    private var sectionSpacing: CGFloat {
        resolvedStyle == .bold ? theme.spacing.xxl : theme.spacing.xl
    }

    private func resultCount(_ visible: [KitoSettingsSection]) -> some View {
        let count = visible.reduce(0) { $0 + $1.rows.count }
        return Text(count == 1 ? "1 result" : "\(count) results")
            .font(theme.settingsFont(.caption))
            .foregroundStyle(theme.colors.onBackground.opacity(0.55))
            .padding(.horizontal, theme.spacing.lg)
            .contentTransition(.numericText(value: Double(count)))
    }
}

public extension KitoSettingsList where Header == EmptyView {
    init(style: KitoSettingsStyle? = nil, tint: Color? = nil,
         searchPrompt: String? = "Search settings",
         @KitoSettingsSectionBuilder sections: () -> [KitoSettingsSection]) {
        self.init(style: style, tint: tint, searchPrompt: searchPrompt, header: { EmptyView() }, sections: sections)
    }
}

/// The screen behind a settings list: the theme background with a soft wash of the tint at the top.
struct KitoSettingsBackdrop: View {
    let style: KitoSettingsStyle
    let tint: Color

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        ZStack(alignment: .top) {
            theme.colors.background
            LinearGradient(colors: [tint.opacity(washOpacity), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 320)
        }
    }

    private var washOpacity: Double {
        switch style {
        case .insetGrouped, .minimal: return 0.05
        case .cards: return 0.08
        case .bold: return 0.14
        }
    }
}
