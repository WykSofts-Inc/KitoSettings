//
//  KitoSettingsProfileHeader.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The person at the top of a settings screen: avatar (a photo or their initials), name, email
/// or phone, an optional plan badge and an "Edit profile" button.
public struct KitoSettingsProfileHeader: View {
    /// A row beside the avatar, or centred under a large one.
    public enum Layout: Sendable {
        case row
        case centered
    }

    private let name: String
    private let detail: String?
    private let plan: String?
    private let avatar: Image?
    private let isVerified: Bool
    private let layout: Layout
    private let tint: Color?
    private let editTitle: String
    private let onEdit: (() -> Void)?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var environmentTint
    @ScaledMetric(relativeTo: .title) private var scale: CGFloat = 1

    public init(name: String, detail: String? = nil, plan: String? = nil, avatar: Image? = nil,
                isVerified: Bool = false, layout: Layout = .row, tint: Color? = nil,
                editTitle: String = "Edit profile", onEdit: (() -> Void)? = nil) {
        self.name = name
        self.detail = detail
        self.plan = plan
        self.avatar = avatar
        self.isVerified = isVerified
        self.layout = layout
        self.tint = tint
        self.editTitle = editTitle
        self.onEdit = onEdit
    }

    private var resolvedTint: Color { tint ?? environmentTint ?? theme.colors.primary }

    /// "Wycliff N" → "WN"; "Amina" → "A".
    static func initials(_ name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let letters = words.prefix(2).compactMap(\.first).map { String($0).uppercased() }
        return letters.joined()
    }

    public var body: some View {
        Group {
            switch layout {
            case .row: rowLayout
            case .centered: centeredLayout
            }
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .background(card)
    }

    private var rowLayout: some View {
        HStack(spacing: theme.spacing.lg) {
            KitoSettingsAvatar(initials: Self.initials(name), image: avatar, tint: resolvedTint,
                               size: 64 * scale, showsCamera: onEdit != nil)
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                identity(alignment: .leading)
                if let onEdit { editButton(onEdit) }
            }
            Spacer(minLength: 0)
        }
    }

    private var centeredLayout: some View {
        VStack(spacing: theme.spacing.md) {
            KitoSettingsAvatar(initials: Self.initials(name), image: avatar, tint: resolvedTint,
                               size: 92 * scale, showsCamera: onEdit != nil)
            identity(alignment: .center)
            if let onEdit { editButton(onEdit) }
        }
    }

    private func identity(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: theme.spacing.xxs) {
            HStack(spacing: theme.spacing.xs) {
                Text(name)
                    .font(theme.settingsFont(.title))
                    .foregroundStyle(theme.colors.onSurface)
                if isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(resolvedTint)
                        .accessibilityLabel("Verified")
                }
            }
            if let detail {
                Text(detail)
                    .font(theme.settingsFont(.label))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.6))
            }
            if let plan { KitoSettingsPlanBadge(plan, tint: resolvedTint) }
        }
        .accessibilityElement(children: .combine)
    }

    private func editButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(editTitle, systemImage: "pencil")
                .font(theme.settingsFont(.label).weight(.semibold))
                .padding(.horizontal, theme.spacing.md)
                .frame(minHeight: 32)
                .foregroundStyle(theme.colors.onPrimary)
                .background(Capsule().fill(theme.colors.onSurface))
        }
        .buttonStyle(KitoSettingsScaleButtonStyle())
        .padding(.top, theme.spacing.xs)
    }

    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radii.xl + 6, style: .continuous)
        return shape
            .fill(theme.colors.surface)
            .overlay(shape.fill(LinearGradient(colors: [resolvedTint.opacity(0.16), .clear],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(shape.strokeBorder(theme.colors.border.opacity(0.6), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }
}

/// A round avatar: the photo, or initials on a gradient, with an optional camera badge.
struct KitoSettingsAvatar: View {
    let initials: String
    let image: Image?
    let tint: Color
    let size: CGFloat
    let showsCamera: Bool

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        face
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 2))
            .shadow(color: tint.opacity(0.35), radius: 10, x: 0, y: 5)
            .overlay(alignment: .bottomTrailing) { if showsCamera { camera } }
            .accessibilityHidden(true)
    }

    @ViewBuilder private var face: some View {
        if let image {
            image.resizable().scaledToFill()
        } else {
            LinearGradient(colors: [tint.opacity(0.7), tint], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )
        }
    }

    private var camera: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: size * 0.14, weight: .bold))
            .foregroundStyle(theme.colors.onPrimary)
            .frame(width: size * 0.32, height: size * 0.32)
            .background(Circle().fill(theme.colors.onSurface))
            .overlay(Circle().strokeBorder(theme.colors.surface, lineWidth: 2))
    }
}

/// "KITO PRO" in a gradient capsule.
struct KitoSettingsPlanBadge: View {
    let plan: String
    let tint: Color

    init(_ plan: String, tint: Color) {
        self.plan = plan
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill").font(.caption2.weight(.bold))
            Text(plan.uppercased()).font(.caption2.weight(.heavy)).kerning(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(LinearGradient(colors: [tint, tint.opacity(0.7)],
                                                  startPoint: .leading, endPoint: .trailing)))
        .accessibilityLabel("\(plan) plan")
    }
}

/// Shrinks a little while pressed.
struct KitoSettingsScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
