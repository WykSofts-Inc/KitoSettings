//
//  KitoAppearanceParts.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// One face of `KitoPhonePreview`.
struct KitoPhoneFace: View {
    let isDark: Bool
    let accent: Color

    private var screen: Color { isDark ? Color(white: 0.09) : Color(white: 0.97) }
    private var card: Color { isDark ? Color(white: 0.17) : .white }
    private var ink: Color { isDark ? .white : .black }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let shape = RoundedRectangle(cornerRadius: width * 0.2, style: .continuous)
            ZStack(alignment: .top) {
                shape.fill(screen)
                VStack(alignment: .leading, spacing: width * 0.07) {
                    Capsule().fill(Color.black).frame(width: width * 0.34, height: width * 0.09)
                        .frame(maxWidth: .infinity)
                    RoundedRectangle(cornerRadius: width * 0.06).fill(accent.gradient).frame(height: width * 0.26)
                    rows(width)
                    Spacer(minLength: 0)
                }
                .padding(width * 0.09)
                shape.strokeBorder(ink.opacity(0.12), lineWidth: 1)
            }
        }
    }

    private func rows(_ width: CGFloat) -> some View {
        VStack(spacing: width * 0.06) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: width * 0.05) {
                    Circle().fill(accent.opacity(0.35 + Double(index) * 0.2)).frame(width: width * 0.12)
                    Capsule().fill(ink.opacity(0.22)).frame(height: width * 0.05)
                    if index == 0 {
                        Capsule().fill(accent).frame(width: width * 0.18, height: width * 0.1)
                    }
                }
                .padding(width * 0.04)
                .background(RoundedRectangle(cornerRadius: width * 0.05).fill(card))
            }
        }
    }
}

// MARK: - Accent grid

/// Colour swatches; the chosen one gets a ring and a check that springs in.
public struct KitoAccentGrid: View {
    @Binding private var selection: String
    private let options: [KitoAccentOption]

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 38

    public init(selection: Binding<String>, options: [KitoAccentOption] = KitoAccentOption.defaults) {
        _selection = selection
        self.options = options
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 8), spacing: theme.spacing.sm)],
                      spacing: theme.spacing.md) {
                ForEach(options) { option in swatch(option) }
            }
            if let current = options.first(where: { $0.id == selection }) {
                Text(current.name)
                    .font(theme.settingsFont(.label))
                    .foregroundStyle(current.color)
                    .contentTransition(.opacity)
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func swatch(_ option: KitoAccentOption) -> some View {
        let isSelected = option.id == selection
        return Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.65)) { selection = option.id }
        } label: {
            Circle()
                .fill(LinearGradient(colors: [option.color.opacity(0.75), option.color],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.38, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .overlay(Circle().strokeBorder(option.color, lineWidth: 2.5).padding(-5).opacity(isSelected ? 1 : 0))
                .shadow(color: option.color.opacity(isSelected ? 0.45 : 0.2), radius: isSelected ? 8 : 3, x: 0, y: 3)
                .frame(width: size + 10, height: size + 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - App icon grid

/// The app's icons; tapping one switches to it with `UIApplication.setAlternateIconName`.
public struct KitoAppIconGrid: View {
    private let options: [KitoAppIconOption]
    private let accent: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var current: String?
    @State private var message: String?
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 60

    public init(options: [KitoAppIconOption], accent: Color? = nil) {
        self.options = options
        self.accent = accent
    }

    private var tint: Color { accent ?? theme.colors.primary }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 16), spacing: theme.spacing.md)],
                      spacing: theme.spacing.lg) {
                ForEach(options) { option in icon(option) }
            }
            if let message {
                Label(message, systemImage: "info.circle")
                    .font(theme.settingsFont(.caption))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                    .transition(.opacity)
            }
        }
        .onAppear { current = KitoAppIcon.current }
        .sensoryFeedback(.success, trigger: current)
    }

    private func icon(_ option: KitoAppIconOption) -> some View {
        let isSelected = option.alternateIconName == current
        let shape = RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
        return Button { choose(option) } label: {
            VStack(spacing: theme.spacing.xs) {
                KitoAppIconArtwork(option: option, size: size)
                    .clipShape(shape)
                    .overlay(shape.strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                    .overlay(shape.strokeBorder(tint, lineWidth: 2.5).padding(-5).opacity(isSelected ? 1 : 0))
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, tint)
                                .font(.title3)
                                .offset(x: 10, y: -10)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                Text(option.title)
                    .font(theme.settingsFont(.caption).weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(theme.colors.onSurface)
                    .lineLimit(1)
            }
            .padding(.top, 6)
        }
        .buttonStyle(KitoSettingsScaleButtonStyle())
        .accessibilityLabel("\(option.title) icon")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func choose(_ option: KitoAppIconOption) {
        let animation: Animation? = reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)
        Task { @MainActor in
            do {
                try await KitoAppIcon.set(option.alternateIconName)
                withAnimation(animation) { current = option.alternateIconName; message = nil }
            } catch {
                withAnimation(animation) {
                    message = KitoAppIcon.isSupported ? "The icon couldn't be changed." : "Alternate icons aren't available here."
                }
            }
        }
    }
}

/// The icon's preview image, or a gradient stand-in with a symbol.
struct KitoAppIconArtwork: View {
    let option: KitoAppIconOption
    let size: CGFloat

    var body: some View {
        Group {
            if let name = option.previewImageName {
                Image(name).resizable().scaledToFill()
            } else {
                LinearGradient(colors: option.colors.isEmpty ? [.gray] : option.colors,
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(
                        Image(systemName: option.systemImage)
                            .font(.system(size: size * 0.42, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Text size

/// A slider from 80% to 140% with a message preview that grows as you drag.
public struct KitoTextSizeControl: View {
    @Binding private var scale: Double
    private let range: ClosedRange<Double>
    private let accent: Color?

    @Environment(\.kitoTheme) private var theme

    public init(scale: Binding<Double>, in range: ClosedRange<Double> = 0.8...1.4, accent: Color? = nil) {
        _scale = scale
        self.range = range
        self.accent = accent
    }

    private var tint: Color { accent ?? theme.colors.primary }

    /// "Default" at 100%, otherwise "115%".
    static func label(_ scale: Double) -> String {
        let percent = Int((scale * 100).rounded())
        return percent == 100 ? "Default" : "\(percent)%"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            preview
            HStack(spacing: theme.spacing.md) {
                Text("A").font(.system(size: 13, weight: .semibold))
                Slider(value: $scale, in: range, step: 0.05) { Text("Text size") }
                    .tint(tint)
                    .accessibilityValue(Self.label(scale))
                Text("A").font(.system(size: 24, weight: .semibold))
            }
            .foregroundStyle(theme.colors.onSurface.opacity(0.6))
            HStack {
                Text(Self.label(scale))
                    .font(theme.settingsFont(.label))
                    .monospacedDigit()
                    .foregroundStyle(tint)
                    .contentTransition(.numericText(value: scale))
                Spacer()
                if abs(scale - 1) > 0.001 {
                    Button("Reset") { withAnimation(.snappy) { scale = 1 } }
                        .font(theme.settingsFont(.label).weight(.semibold))
                        .foregroundStyle(tint)
                        .transition(.opacity)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: scale)
        .animation(.snappy, value: scale)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            bubble("Habari! Is the matatu stage still on Moi Avenue?", mine: false)
            bubble("Yes, next to the bookshop. See you at 5.", mine: true)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous).fill(theme.colors.surfaceMuted))
        .accessibilityHidden(true)
    }

    private func bubble(_ text: String, mine: Bool) -> some View {
        Text(text)
            .font(.system(size: 15 * scale))
            .foregroundStyle(mine ? Color.white : theme.colors.onSurface)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(mine ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(theme.colors.surface))
            )
            .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }
}
