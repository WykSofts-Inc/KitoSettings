//
//  KitoLanguagePicker.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A language shown by its own name ("Kiswahili"), with its English name and a flag.
public struct KitoLanguage: Identifiable, Hashable, Sendable, KitoSettingsSearchable {
    /// A BCP 47 code: "sw", "fr", "zh-Hans".
    public var code: String
    public var nativeName: String
    public var englishName: String
    public var flag: String

    public var id: String { code }

    public init(_ code: String, nativeName: String, englishName: String, flag: String = "🌐") {
        self.code = code
        self.nativeName = nativeName
        self.englishName = englishName
        self.flag = flag
    }

    /// Names from the system: `KitoLanguage(code: "de")` is "Deutsch" / "German".
    public init(code: String, flag: String = "🌐") {
        let native = Locale(identifier: code).localizedString(forIdentifier: code) ?? code
        let english = Locale(identifier: "en").localizedString(forIdentifier: code) ?? code
        self.init(code, nativeName: native.prefix(1).uppercased() + native.dropFirst(), englishName: english, flag: flag)
    }

    public var searchTitle: String { nativeName }
    public var searchSubtitle: String? { englishName }
    public var searchKeywords: [String] { [code] }

    /// English, East African and widely used languages.
    public static let common: [KitoLanguage] = [
        KitoLanguage("en", nativeName: "English", englishName: "English", flag: "🇬🇧"),
        KitoLanguage("sw", nativeName: "Kiswahili", englishName: "Swahili", flag: "🇰🇪"),
        KitoLanguage("fr", nativeName: "Français", englishName: "French", flag: "🇫🇷"),
        KitoLanguage("ar", nativeName: "العربية", englishName: "Arabic", flag: "🇸🇦"),
        KitoLanguage("am", nativeName: "አማርኛ", englishName: "Amharic", flag: "🇪🇹"),
        KitoLanguage("so", nativeName: "Soomaali", englishName: "Somali", flag: "🇸🇴"),
        KitoLanguage("rw", nativeName: "Ikinyarwanda", englishName: "Kinyarwanda", flag: "🇷🇼"),
        KitoLanguage("lg", nativeName: "Luganda", englishName: "Ganda", flag: "🇺🇬"),
        KitoLanguage("yo", nativeName: "Èdè Yorùbá", englishName: "Yoruba", flag: "🇳🇬"),
        KitoLanguage("zu", nativeName: "isiZulu", englishName: "Zulu", flag: "🇿🇦"),
        KitoLanguage("pt", nativeName: "Português", englishName: "Portuguese", flag: "🇵🇹"),
        KitoLanguage("es", nativeName: "Español", englishName: "Spanish", flag: "🇪🇸"),
        KitoLanguage("de", nativeName: "Deutsch", englishName: "German", flag: "🇩🇪"),
        KitoLanguage("hi", nativeName: "हिन्दी", englishName: "Hindi", flag: "🇮🇳"),
        KitoLanguage("zh-Hans", nativeName: "简体中文", englishName: "Chinese, Simplified", flag: "🇨🇳"),
        KitoLanguage("ja", nativeName: "日本語", englishName: "Japanese", flag: "🇯🇵"),
    ]

    /// The languages in `languages` that the device prefers, in the device's order.
    public static func suggested(from languages: [KitoLanguage],
                                 preferred: [String] = Locale.preferredLanguages) -> [KitoLanguage] {
        var result: [KitoLanguage] = []
        for identifier in preferred {
            let match = languages.first { identifier == $0.code || identifier.hasPrefix($0.code + "-") }
            if let match, !result.contains(match) { result.append(match) }
        }
        return result
    }
}

/// A searchable list of languages by their own names, suggested ones first, with a checkmark
/// that springs to the one you pick.
public struct KitoLanguagePicker: View {
    @Binding private var selection: String
    private let languages: [KitoLanguage]
    private let suggested: [KitoLanguage]
    private let footer: String?
    private let style: KitoSettingsStyle?
    private let tint: Color?

    /// - Parameters:
    ///   - selection: The chosen language's code.
    ///   - suggested: Shown first; defaults to the device's preferred languages.
    public init(selection: Binding<String>, languages: [KitoLanguage] = KitoLanguage.common,
                suggested: [KitoLanguage]? = nil, footer: String? = nil,
                style: KitoSettingsStyle? = nil, tint: Color? = nil) {
        _selection = selection
        self.languages = languages
        self.suggested = suggested ?? KitoLanguage.suggested(from: languages)
        self.footer = footer
        self.style = style
        self.tint = tint
    }

    private var others: [KitoLanguage] {
        languages.filter { language in !suggested.contains(language) }
    }

    public var body: some View {
        KitoSettingsList(style: style, tint: tint, searchPrompt: "Search languages") {
            if !suggested.isEmpty {
                KitoSettingsSection("Suggested") {
                    for language in suggested { row(language, prefix: "suggested") }
                }
            }
            KitoSettingsSection(suggested.isEmpty ? "Languages" : "More languages", footer: footer) {
                for language in others { row(language, prefix: "all") }
            }
        }
        .navigationTitle("Language")
    }

    private func row(_ language: KitoLanguage, prefix: String) -> KitoSettingsRow {
        KitoCustomRow(language.nativeName, keywords: [language.englishName, language.code]) {
            KitoLanguageRow(language: language, isSelected: selection == language.code) {
                selection = language.code
            }
        }
        .rowID("\(prefix)-\(language.code)")
    }
}

/// A flag, the language's own name over its English name, and a checkmark.
struct KitoLanguageRow: View {
    let language: KitoLanguage
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var tint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color { tint ?? theme.colors.primary }

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) { action() }
        } label: {
            HStack(spacing: theme.spacing.md) {
                Text(language.flag)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(theme.colors.surfaceMuted))
                    .overlay(Circle().strokeBorder(isSelected ? accent : .clear, lineWidth: 2))
                VStack(alignment: .leading, spacing: 1) {
                    Text(language.nativeName)
                        .font(theme.settingsFont(isSelected ? .bodyEmphasized : .body))
                        .foregroundStyle(theme.colors.onSurface)
                    Text(language.englishName)
                        .font(theme.settingsFont(.caption))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                }
                Spacer(minLength: theme.spacing.sm)
                KitoSettingsCheckmark(isOn: isSelected, tint: accent)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(language.nativeName), \(language.englishName)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
