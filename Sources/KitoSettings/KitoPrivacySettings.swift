//
//  KitoPrivacySettings.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A privacy choice with an explanation, such as "Personalised ads".
public struct KitoPrivacyToggle: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var systemImage: String
    public var color: Color
    public var isOn: Bool

    public init(_ id: String, title: String, subtitle: String? = nil, systemImage: String,
                color: Color = .blue, isOn: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.isOn = isOn
    }
}

/// A ready-made Privacy screen: a summary card, your privacy switches, then "Download my data"
/// (with a preparing state and a share button when the file is ready), "Delete my data" and
/// "Delete account". Leave out a closure to leave out its row.
///
/// ```swift
/// KitoPrivacySettings(toggles: $privacy, policyURL: policy,
///                     onExportData: { try? await api.exportData() },
///                     onDeleteAccount: { showsDeleteFlow = true })
/// ```
public struct KitoPrivacySettings: View {
    @Binding private var toggles: [KitoPrivacyToggle]
    private let policyURL: URL?
    private let onExportData: (() async -> URL?)?
    private let onDeleteData: (() -> Void)?
    private let onDeleteAccount: (() -> Void)?
    private let style: KitoSettingsStyle?
    private let tint: Color?

    /// - Parameter onExportData: Prepares the export and returns the file (or a link to it) to
    ///   share; nil when it failed.
    public init(toggles: Binding<[KitoPrivacyToggle]>, policyURL: URL? = nil,
                onExportData: (() async -> URL?)? = nil, onDeleteData: (() -> Void)? = nil,
                onDeleteAccount: (() -> Void)? = nil, style: KitoSettingsStyle? = nil, tint: Color? = nil) {
        _toggles = toggles
        self.policyURL = policyURL
        self.onExportData = onExportData
        self.onDeleteData = onDeleteData
        self.onDeleteAccount = onDeleteAccount
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        KitoSettingsList(style: style, tint: tint, searchPrompt: nil) {
            KitoPrivacySummary(onCount: toggles.filter(\.isOn).count, total: toggles.count)
        } sections: {
            KitoSettingsSection("Sharing", footer: "You can change these at any time; they apply on every device.") {
                for index in toggles.indices {
                    KitoToggleRow(toggles[index].title, systemImage: toggles[index].systemImage,
                                  color: toggles[index].color, subtitle: toggles[index].subtitle,
                                  isOn: $toggles[index].isOn)
                        .rowID(toggles[index].id)
                }
            }
            KitoSettingsSection("Your data") {
                if let onExportData {
                    KitoCustomRow("Download my data", keywords: ["export", "copy"]) {
                        KitoDataExportRow(export: onExportData)
                    }
                }
                if let policyURL {
                    KitoLinkRow("Privacy policy", systemImage: "doc.text.fill", color: .gray, url: policyURL)
                }
                if let onDeleteData {
                    KitoActionRow("Delete my data", systemImage: "externaldrive.badge.xmark", role: .destructive,
                                  confirmation: "Delete your history, preferences and saved items? Your account stays open.",
                                  action: onDeleteData)
                }
                if let onDeleteAccount {
                    KitoActionRow("Delete account", systemImage: "trash.fill", role: .destructive,
                                  showsChevron: true, action: onDeleteAccount)
                }
            }
        }
        .navigationTitle("Privacy")
    }
}

/// The shield card at the top of the Privacy screen.
struct KitoPrivacySummary: View {
    let onCount: Int
    let total: Int

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var tint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var accent: Color { tint ?? theme.colors.primary }

    var body: some View {
        HStack(spacing: theme.spacing.lg) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 72, height: 72)
                Circle().strokeBorder(accent.opacity(0.25), lineWidth: 1).frame(width: 88, height: 88)
                    .scaleEffect(appeared ? 1 : 0.8)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(accent.gradient)
                    .symbolEffect(.bounce, value: appeared)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text("You're in control")
                    .font(theme.settingsFont(.headline))
                    .foregroundStyle(theme.colors.onSurface)
                Text("\(onCount) of \(total) sharing options on")
                    .font(theme.settingsFont(.label))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText(value: Double(onCount)))
                Text("We never sell your data.")
                    .font(theme.settingsFont(.caption))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.xl + 4, style: .continuous)
                .fill(theme.colors.surface)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .animation(reduceMotion ? nil : .snappy, value: onCount)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.6)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Download my data": idle, then preparing with a spinner, then ready with a share button.
struct KitoDataExportRow: View {
    let export: () async -> URL?

    private enum Phase: Equatable { case idle, preparing, ready(URL), failed }

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsStyle) private var style
    @Environment(\.kitoSettingsTint) private var tint
    @State private var phase: Phase = .idle

    private var accent: Color { tint ?? theme.colors.primary }

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            KitoSettingsIconTile(KitoSettingsIcon("arrow.down.doc.fill", color: .teal), style: style)
            VStack(alignment: .leading, spacing: 2) {
                Text("Download my data").font(theme.settingsFont(.body)).foregroundStyle(theme.colors.onSurface)
                Text(caption)
                    .font(theme.settingsFont(.caption))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                    .contentTransition(.opacity)
            }
            Spacer(minLength: theme.spacing.sm)
            trailing
        }
        .animation(.snappy, value: phase)
        .sensoryFeedback(.success, trigger: phase) { _, new in if case .ready = new { return true } else { return false } }
    }

    private var caption: String {
        switch phase {
        case .idle: return "A copy of everything, as a file"
        case .preparing: return "Preparing your file…"
        case .ready: return "Ready to save or share"
        case .failed: return "Couldn't prepare it. Try again."
        }
    }

    @ViewBuilder private var trailing: some View {
        switch phase {
        case .idle, .failed:
            Button(phase == .failed ? "Retry" : "Request", action: start)
                .font(theme.settingsFont(.label).weight(.semibold))
                .padding(.horizontal, theme.spacing.md)
                .frame(minHeight: 32)
                .foregroundStyle(accent)
                .background(Capsule().fill(accent.opacity(0.12)))
                .buttonStyle(KitoSettingsScaleButtonStyle())
        case .preparing:
            ProgressView().tint(accent)
        case .ready(let url):
            ShareLink(item: url) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(theme.settingsFont(.label).weight(.semibold))
                    .padding(.horizontal, theme.spacing.md)
                    .frame(minHeight: 32)
                    .foregroundStyle(theme.colors.onPrimary)
                    .background(Capsule().fill(accent))
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func start() {
        phase = .preparing
        Task { @MainActor in
            let url = await export()
            phase = url.map(Phase.ready) ?? .failed
        }
    }
}
