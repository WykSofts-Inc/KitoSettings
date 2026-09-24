//
//  KitoNotificationSettings.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UIKit
import KitoCore

/// A ready-made Notifications screen: one switch per topic with channel chips (Push, Email, SMS)
/// that open under it, quiet hours on a 24-hour dial, and a banner when iOS has notifications
/// turned off for the app.
///
/// ```swift
/// KitoNotificationSettings(topics: $topics, quietHours: $quietHours, channels: [.push, .email])
/// ```
public struct KitoNotificationSettings: View {
    @Binding private var topics: [KitoNotificationTopic]
    private let quietHours: Binding<KitoSettingsQuietHours>?
    private let channels: [KitoNotificationChannel]
    private let isSystemAllowed: Bool
    private let onOpenSystemSettings: (() -> Void)?
    private let style: KitoSettingsStyle?
    private let tint: Color?

    @Environment(\.openURL) private var openURL

    /// - Parameters:
    ///   - channels: The channels to offer as chips; one or none hides the chips.
    ///   - isSystemAllowed: Pass false when `UNUserNotificationCenter` reports notifications are
    ///     denied, to show a banner that opens the app's page in iOS Settings.
    public init(topics: Binding<[KitoNotificationTopic]>, quietHours: Binding<KitoSettingsQuietHours>? = nil,
                channels: [KitoNotificationChannel] = [.push, .email], isSystemAllowed: Bool = true,
                onOpenSystemSettings: (() -> Void)? = nil, style: KitoSettingsStyle? = nil, tint: Color? = nil) {
        _topics = topics
        self.quietHours = quietHours
        self.channels = channels
        self.isSystemAllowed = isSystemAllowed
        self.onOpenSystemSettings = onOpenSystemSettings
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        KitoSettingsList(style: style, tint: tint, searchPrompt: nil) {
            if !isSystemAllowed {
                KitoSettingsSection {
                    KitoCustomRow("Notifications are off") {
                        KitoNotificationsOffBanner(action: openSystemSettings)
                    }
                }
            }
            KitoSettingsSection("Notify me about", footer: "Choose what you hear about and where.") {
                for index in topics.indices {
                    KitoCustomRow(topics[index].title) {
                        KitoNotificationTopicRow(topic: $topics[index], channels: channels)
                    }
                    .rowID(topics[index].id)
                }
            }
            if let quietHours {
                KitoSettingsSection("Quiet hours",
                                    footer: "Notifications arrive silently in this window; calls and alarms still ring.") {
                    KitoCustomRow("Quiet hours", keywords: ["do not disturb", "sleep"]) {
                        KitoQuietHoursEditor(quietHours: quietHours)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
    }

    private func openSystemSettings() {
        if let onOpenSystemSettings { return onOpenSystemSettings() }
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

/// A topic's switch, with channel chips that expand under it while it's on.
struct KitoNotificationTopicRow: View {
    @Binding var topic: KitoNotificationTopic
    let channels: [KitoNotificationChannel]

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsStyle) private var style
    @Environment(\.kitoSettingsTint) private var tint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color { tint ?? theme.colors.primary }
    private var motion: Animation? { reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.82) }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.md) {
                KitoSettingsIconTile(KitoSettingsIcon(topic.systemImage, color: topic.color), style: style)
                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.title)
                        .font(theme.settingsFont(.body))
                        .foregroundStyle(theme.colors.onSurface)
                    Text(topic.subtitle ?? topic.summary)
                        .font(theme.settingsFont(.caption))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: theme.spacing.sm)
                Toggle(topic.title, isOn: $topic.isOn.animation(motion))
                    .labelsHidden()
                    .tint(accent)
            }
            if topic.isOn && channels.count > 1 {
                chips.transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .sensoryFeedback(.selection, trigger: topic.isOn)
    }

    private var chips: some View {
        HStack(spacing: theme.spacing.sm) {
            ForEach(channels) { channel in
                chip(channel)
            }
        }
        .padding(.leading, style == .minimal ? 0 : theme.spacing.xxs)
    }

    private func chip(_ channel: KitoNotificationChannel) -> some View {
        let isOn = topic.channels.contains(channel)
        return Button {
            withAnimation(motion) { topic.toggle(channel) }
        } label: {
            Label(channel.title, systemImage: isOn ? "checkmark" : channel.systemImage)
                .font(theme.settingsFont(.caption).weight(.semibold))
                .padding(.horizontal, theme.spacing.md)
                .frame(minHeight: 30)
                .foregroundStyle(isOn ? theme.colors.onPrimary : theme.colors.onSurface.opacity(0.75))
                .background(Capsule().fill(isOn ? AnyShapeStyle(accent.gradient) : AnyShapeStyle(theme.colors.surfaceMuted)))
                .overlay(Capsule().strokeBorder(isOn ? .clear : theme.colors.border, lineWidth: 0.5))
        }
        .buttonStyle(KitoSettingsScaleButtonStyle())
        .accessibilityLabel("\(channel.title) for \(topic.title)")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// "Notifications are off" with a button to iOS Settings.
struct KitoNotificationsOffBanner: View {
    let action: () -> Void

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            Image(systemName: "bell.slash.fill")
                .font(.title3)
                .foregroundStyle(theme.colors.warning)
                .frame(width: 40, height: 40)
                .background(Circle().fill(theme.colors.warning.opacity(0.15)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Notifications are off")
                    .font(theme.settingsFont(.headline))
                    .foregroundStyle(theme.colors.onSurface)
                Text("Turn them on in Settings to hear about the things below.")
                    .font(theme.settingsFont(.caption))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: action) {
                    Text("Open Settings")
                        .font(theme.settingsFont(.label).weight(.semibold))
                        .padding(.horizontal, theme.spacing.md)
                        .frame(minHeight: 32)
                        .foregroundStyle(theme.colors.onPrimary)
                        .background(Capsule().fill(theme.colors.onSurface))
                }
                .buttonStyle(KitoSettingsScaleButtonStyle())
                .padding(.top, theme.spacing.xxs)
            }
        }
    }
}
