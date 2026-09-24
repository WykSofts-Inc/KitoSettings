//
//  KitoPlanCard.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UIKit
import KitoCore

/// The current plan on a gradient card: name, price, renewal, perks and an upgrade (or manage)
/// button, with a slow sheen that stops under Reduce Motion.
public struct KitoPlanCard: View {
    private let plan: String
    private let price: String?
    private let renewal: String?
    private let perks: [String]
    private let actionTitle: String?
    private let tint: Color?
    private let action: (() -> Void)?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var environmentTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheen = false

    /// - Parameters:
    ///   - plan: "Kito Pro".
    ///   - price: "KES 499 / month".
    ///   - renewal: "Renews 24 October".
    ///   - actionTitle: "Upgrade", "Manage plan"; nil hides the button.
    public init(plan: String, price: String? = nil, renewal: String? = nil, perks: [String] = [],
                actionTitle: String? = "Upgrade", tint: Color? = nil, action: (() -> Void)? = nil) {
        self.plan = plan
        self.price = price
        self.renewal = renewal
        self.perks = perks
        self.actionTitle = actionTitle
        self.tint = tint
        self.action = action
    }

    private var resolvedTint: Color { tint ?? environmentTint ?? theme.colors.primary }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            top
            if !perks.isEmpty { perkList }
            if let actionTitle, let action { button(actionTitle, action) }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl + 8, style: .continuous))
        .shadow(color: resolvedTint.opacity(0.35), radius: 18, x: 0, y: 10)
        .onAppear { if !reduceMotion { sheen = true } }
        .accessibilityElement(children: .contain)
    }

    private var top: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text("CURRENT PLAN")
                    .font(.caption2.weight(.heavy))
                    .kerning(1.2)
                    .opacity(0.75)
                Text(plan)
                    .font(theme.settingsFont(.display))
                if let price {
                    Text(price).font(theme.settingsFont(.bodyEmphasized)).opacity(0.9)
                }
            }
            Spacer(minLength: theme.spacing.sm)
            Image(systemName: "crown.fill")
                .font(.title2)
                .padding(theme.spacing.md)
                .background(Circle().fill(.white.opacity(0.18)))
                .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var perkList: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            ForEach(perks, id: \.self) { perk in
                Label {
                    Text(perk).font(theme.settingsFont(.label))
                } icon: {
                    Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.hierarchical)
                }
            }
            if let renewal {
                Text(renewal).font(theme.settingsFont(.caption)).opacity(0.75).padding(.top, theme.spacing.xxs)
            }
        }
    }

    private func button(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Image(systemName: "arrow.forward")
            }
            .font(theme.settingsFont(.button))
            .foregroundStyle(resolvedTint)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Capsule().fill(.white))
        }
        .buttonStyle(KitoSettingsScaleButtonStyle())
        .padding(.top, theme.spacing.xs)
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [resolvedTint, KitoSettingsColor.shifted(resolvedTint)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.12)).frame(width: 220).offset(x: 130, y: -90).blur(radius: 2)
            Circle().fill(.white.opacity(0.08)).frame(width: 160).offset(x: -140, y: 110)
            sheenLayer
        }
    }

    private var sheenLayer: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [.clear, .white.opacity(0.22), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: proxy.size.width * 0.4)
                .rotationEffect(.degrees(20))
                .offset(x: sheenOffset(proxy.size.width))
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.6).repeatForever(autoreverses: false).delay(1),
                           value: sheen)
        }
        .allowsHitTesting(false)
    }

    private func sheenOffset(_ width: CGFloat) -> CGFloat {
        sheen ? width * 1.4 : -width * 0.8
    }
}

/// Small colour helpers.
enum KitoSettingsColor {
    /// A deeper, slightly hue-shifted partner for gradients.
    static func shifted(_ color: Color) -> Color {
        let ui = UIColor(color)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        guard ui.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return color }
        let newHue = (hue + 0.08).truncatingRemainder(dividingBy: 1)
        return Color(hue: Double(newHue), saturation: Double(min(1, saturation * 1.05)),
                     brightness: Double(brightness * 0.85), opacity: Double(alpha))
    }
}
