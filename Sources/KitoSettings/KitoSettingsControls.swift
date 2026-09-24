//
//  KitoSettingsControls.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

// MARK: - Stepper

extension KitoAnyStepper {
    /// The value one step up or down, kept inside the range.
    static func stepped(_ value: Int, by step: Int, in range: ClosedRange<Int>) -> Int {
        min(range.upperBound, max(range.lowerBound, value + step))
    }
}

/// Minus and plus in a capsule, with the value rolling between them.
struct KitoSettingsStepperControl: View {
    let stepper: KitoAnyStepper
    let tint: Color
    let title: String

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var value: Int { stepper.value.wrappedValue }

    var body: some View {
        HStack(spacing: 0) {
            button("minus", by: -stepper.step, enabled: value > stepper.range.lowerBound)
            Text(stepper.format(value))
                .font(theme.settingsFont(.bodyEmphasized))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
                .frame(minWidth: 44)
                .foregroundStyle(theme.colors.onSurface)
            button("plus", by: stepper.step, enabled: value < stepper.range.upperBound)
        }
        .padding(3)
        .background(Capsule().fill(theme.colors.surfaceMuted))
        .overlay(Capsule().strokeBorder(theme.colors.border.opacity(0.6), lineWidth: 0.5))
        .sensoryFeedback(.increase, trigger: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(stepper.format(value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: change(by: stepper.step)
            case .decrement: change(by: -stepper.step)
            @unknown default: break
            }
        }
    }

    private func button(_ symbol: String, by step: Int, enabled: Bool) -> some View {
        Button { change(by: step) } label: {
            Image(systemName: symbol)
                .font(.footnote.weight(.bold))
                .frame(width: 32, height: 30)
                .background(Capsule().fill(enabled ? tint.opacity(0.14) : .clear))
                .foregroundStyle(enabled ? tint : theme.colors.onSurface.opacity(0.25))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func change(by step: Int) {
        let next = KitoAnyStepper.stepped(value, by: step, in: stepper.range)
        withAnimation(reduceMotion ? nil : .snappy) { stepper.value.wrappedValue = next }
    }
}

// MARK: - Slider

/// The title and value on one line, the slider under them.
struct KitoSettingsSliderRowView: View {
    let row: KitoSettingsRow
    let slider: KitoAnySlider
    let style: KitoSettingsStyle
    let tint: Color

    @Environment(\.kitoTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.md) {
                KitoSettingsRowLabel(row: row, style: style, tint: tint)
                Spacer(minLength: theme.spacing.sm)
                Text(slider.format(slider.value.wrappedValue))
                    .font(theme.settingsFont(.label))
                    .monospacedDigit()
                    .foregroundStyle(tint)
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xxs)
                    .background(Capsule().fill(tint.opacity(0.12)))
                    .contentTransition(.numericText(value: slider.value.wrappedValue))
            }
            control
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
    }

    @ViewBuilder private var control: some View {
        let label = Text(row.title)
        if let step = slider.step {
            Slider(value: slider.value, in: slider.range, step: step) { label } minimumValueLabel: {
                symbol(slider.minimumSymbol, small: true)
            } maximumValueLabel: {
                symbol(slider.maximumSymbol, small: false)
            }
            .tint(tint)
        } else {
            Slider(value: slider.value, in: slider.range) { label } minimumValueLabel: {
                symbol(slider.minimumSymbol, small: true)
            } maximumValueLabel: {
                symbol(slider.maximumSymbol, small: false)
            }
            .tint(tint)
        }
    }

    @ViewBuilder private func symbol(_ name: String?, small: Bool) -> some View {
        if let name {
            Image(systemName: name)
                .font(small ? .footnote : .body)
                .foregroundStyle(theme.colors.onSurface.opacity(0.45))
        }
    }
}
