//
//  KitoDeleteAccountParts.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Two capsules that fill as the steps go by.
struct KitoDeleteProgress: View {
    let step: KitoDeleteStep
    let tint: Color

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach([KitoDeleteStep.reason, .confirm], id: \.self) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(theme.colors.surfaceMuted))
                    .frame(height: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step.rawValue + 1) of 2")
    }
}

struct KitoDeleteTitle: View {
    let title: String
    let subtitle: String

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.settingsFont(.display))
                .foregroundStyle(theme.colors.onBackground)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(theme.settingsFont(.body))
                .foregroundStyle(theme.colors.onBackground.opacity(0.6))
        }
    }
}

/// A reason as a radio card.
struct KitoDeleteReasonCard: View {
    let reason: KitoDeleteReason
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
        return Button(action: action) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: reason.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? theme.colors.onPrimary : theme.colors.onSurface.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(isSelected ? theme.colors.onSurface : theme.colors.surfaceMuted))
                Text(reason.title)
                    .font(theme.settingsFont(isSelected ? .bodyEmphasized : .body))
                    .foregroundStyle(theme.colors.onSurface)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: theme.spacing.sm)
                KitoSettingsCheckmark(isOn: isSelected, tint: theme.colors.onSurface)
            }
            .padding(theme.spacing.md)
            .background(shape.fill(theme.colors.surface))
            .overlay(shape.strokeBorder(isSelected ? theme.colors.onSurface : theme.colors.border,
                                        lineWidth: isSelected ? 1.5 : 0.5))
            .contentShape(shape)
        }
        .buttonStyle(KitoSettingsScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// What they'll lose, each with a red cross.
struct KitoConsequenceList: View {
    let items: [String]

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.colors.danger)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(theme.settingsFont(.body))
                        .foregroundStyle(theme.colors.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous).fill(theme.colors.danger.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous).strokeBorder(theme.colors.danger.opacity(0.25), lineWidth: 1))
    }
}

/// "Type DELETE to confirm": a tile per letter that lights up as it's typed correctly, and a
/// shake when a letter is wrong.
struct KitoDeletePhraseField: View {
    @Binding var text: String
    let confirmation: KitoDeleteConfirmation

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shakes = 0
    @FocusState private var isFocused: Bool

    private var matched: Int { confirmation.matchedCount(of: text) }
    private var letters: [Character] { Array(confirmation.phrase) }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Type \(confirmation.phrase) to confirm")
                .font(theme.settingsFont(.label).weight(.semibold))
                .foregroundStyle(theme.colors.onSurface)
            tiles
            TextField(confirmation.phrase, text: $text)
                .font(theme.settingsFont(.body).monospaced())
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(.horizontal, theme.spacing.md)
                .frame(minHeight: 48)
                .background(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous).fill(theme.colors.surface))
                .overlay(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous).strokeBorder(borderColor, lineWidth: 1.5))
                .modifier(KitoShakeEffect(shakes: CGFloat(shakes)))
                .accessibilityHint("Type \(confirmation.phrase) in capitals")
        }
        .onChange(of: text) { _, newValue in
            guard confirmation.hasMistake(in: newValue) else { return }
            withAnimation(reduceMotion ? nil : .linear(duration: 0.35)) { shakes += 1 }
        }
        .sensoryFeedback(.error, trigger: shakes)
        .sensoryFeedback(.warning, trigger: confirmation.isConfirmed(by: text)) { _, new in new }
    }

    private var borderColor: Color {
        if confirmation.isConfirmed(by: text) { return theme.colors.danger }
        if confirmation.hasMistake(in: text) { return theme.colors.warning }
        return isFocused ? theme.colors.onSurface.opacity(0.5) : theme.colors.border
    }

    private var tiles: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                tile(letter, isLit: index < matched)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: matched)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(matched) of \(letters.count) letters typed")
    }

    private func tile(_ letter: Character, isLit: Bool) -> some View {
        Text(String(letter))
            .font(.system(.title3, design: .rounded).weight(.heavy))
            .foregroundStyle(isLit ? Color.white : theme.colors.onSurface.opacity(0.3))
            .frame(width: 38, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isLit ? AnyShapeStyle(theme.colors.danger.gradient) : AnyShapeStyle(theme.colors.surfaceMuted))
            )
            .scaleEffect(isLit && !reduceMotion ? 1.06 : 1)
            .shadow(color: theme.colors.danger.opacity(isLit ? 0.35 : 0), radius: 5, x: 0, y: 3)
    }
}

/// A horizontal shake, one wobble per step of `shakes`.
struct KitoShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = 8 * sin(shakes * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// The primary capsule and a quieter secondary button, pinned to the bottom.
struct KitoDeleteButtons: View {
    let primary: String
    let primaryIsDestructive: Bool
    let isEnabled: Bool
    let isWorking: Bool
    let secondary: String?
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    @Environment(\.kitoTheme) private var theme

    private var fill: Color { primaryIsDestructive ? theme.colors.danger : theme.colors.onBackground }
    private var ink: Color { primaryIsDestructive ? .white : theme.colors.background }

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Button(action: primaryAction) {
                HStack(spacing: theme.spacing.sm) {
                    if isWorking { ProgressView().tint(ink) }
                    Text(isWorking ? "Deleting…" : primary)
                }
                .font(theme.settingsFont(.button))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Capsule().fill(fill.gradient))
                .shadow(color: fill.opacity(isEnabled ? 0.3 : 0), radius: 10, x: 0, y: 5)
                .opacity(isEnabled ? 1 : 0.35)
            }
            .buttonStyle(KitoSettingsScaleButtonStyle())
            .disabled(!isEnabled || isWorking)
            if let secondary {
                Button(secondary, action: secondaryAction)
                    .font(theme.settingsFont(.button))
                    .foregroundStyle(theme.colors.onBackground)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(isWorking)
            }
        }
        .padding(.horizontal, theme.spacing.xl)
        .padding(.top, theme.spacing.md)
        .padding(.bottom, theme.spacing.sm)
        .background(.bar)
    }
}

/// The goodbye: a ring that draws itself around a waving hand, then Done.
struct KitoFarewell: View {
    let message: String
    let onFinish: () -> Void

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn = false

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()
            ZStack {
                Circle().fill(theme.colors.success.opacity(0.12)).frame(width: 150, height: 150)
                    .scaleEffect(drawn ? 1 : 0.6)
                Circle()
                    .trim(from: 0, to: drawn ? 1 : 0)
                    .stroke(theme.colors.success.gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .flipsForRightToLeftLayoutDirection(true) // Circle doesn't mirror but rotation does; keeps the start at the top in RTL
                    .frame(width: 118, height: 118)
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(theme.colors.success.gradient)
                    .rotationEffect(.degrees(drawn && !reduceMotion ? 0 : -20), anchor: .bottomTrailing)
                    .symbolEffect(.bounce, options: .repeat(2), value: drawn)
            }
            .accessibilityHidden(true)
            VStack(spacing: theme.spacing.sm) {
                Text("Your account is deleted")
                    .font(theme.settingsFont(.display))
                    .foregroundStyle(theme.colors.onBackground)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(theme.settingsFont(.body))
                    .foregroundStyle(theme.colors.onBackground.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .opacity(drawn ? 1 : 0)
            .offset(y: drawn || reduceMotion ? 0 : 12)
            Spacer()
            Button(action: onFinish) {
                Text("Done")
                    .font(theme.settingsFont(.button))
                    .foregroundStyle(theme.colors.background)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(theme.colors.onBackground))
            }
            .buttonStyle(KitoSettingsScaleButtonStyle())
        }
        .padding(theme.spacing.xl)
        .sensoryFeedback(.success, trigger: drawn)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.9)) { drawn = true }
        }
    }
}
