//
//  KitoQuietHoursEditor.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A quiet hours switch; when on, a 24-hour dial of the window, From and To pickers, and whether
/// it's quiet right now.
public struct KitoQuietHoursEditor: View {
    @Binding private var quietHours: KitoSettingsQuietHours
    private let tint: Color?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.kitoSettingsTint) private var environmentTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(quietHours: Binding<KitoSettingsQuietHours>, tint: Color? = nil) {
        _quietHours = quietHours
        self.tint = tint
    }

    private var accent: Color { tint ?? environmentTint ?? theme.colors.primary }
    private var motion: Animation? { reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85) }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            Toggle(isOn: $quietHours.isEnabled.animation(motion)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiet hours").font(theme.settingsFont(.body)).foregroundStyle(theme.colors.onSurface)
                    Text(quietHours.isEnabled ? quietHours.formatted : "Off")
                        .font(theme.settingsFont(.caption))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                        .monospacedDigit()
                }
            }
            .tint(accent)
            if quietHours.isEnabled {
                details.transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
    }

    private var details: some View {
        VStack(spacing: theme.spacing.lg) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                HStack(spacing: theme.spacing.lg) {
                    KitoQuietHoursDial(quietHours: quietHours, now: KitoTimeOfDay(context.date), tint: accent)
                        .frame(width: 124, height: 124)
                    status(at: KitoTimeOfDay(context.date))
                }
            }
            HStack(spacing: theme.spacing.md) {
                picker("From", time: $quietHours.start, symbol: "moon.fill")
                picker("To", time: $quietHours.end, symbol: "sun.max.fill")
            }
        }
    }

    private func status(at now: KitoTimeOfDay) -> some View {
        let isQuiet = quietHours.contains(now)
        let wait = quietHours.minutesUntilQuiet(from: now)
        return VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Label(isQuiet ? "Quiet now" : "Not quiet", systemImage: isQuiet ? "moon.zzz.fill" : "bell.fill")
                .font(theme.settingsFont(.label).weight(.semibold))
                .foregroundStyle(isQuiet ? accent : theme.colors.onSurface)
            Text(isQuiet ? "Until \(quietHours.end.formatted)" : "Starts in \(Self.duration(wait))")
                .font(theme.settingsFont(.caption))
                .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                .monospacedDigit()
            Text("\(quietHours.formattedDuration) of quiet")
                .font(theme.settingsFont(.caption))
                .foregroundStyle(theme.colors.onSurface.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    static func duration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }

    private func picker(_ title: String, time: Binding<KitoTimeOfDay>, symbol: String) -> some View {
        let date = Binding<Date>(
            get: { time.wrappedValue.date() },
            set: { newValue in withAnimation(motion) { time.wrappedValue = KitoTimeOfDay(newValue) } }
        )
        return VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Label(title, systemImage: symbol)
                .font(theme.settingsFont(.caption).weight(.semibold))
                .foregroundStyle(theme.colors.onSurface.opacity(0.6))
            DatePicker(title, selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(accent)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous).fill(theme.colors.surfaceMuted))
    }
}

/// A 24-hour ring with the quiet window drawn as an arc, midnight at the top, and a dot for now.
public struct KitoQuietHoursDial: View {
    private let quietHours: KitoSettingsQuietHours
    private let now: KitoTimeOfDay?
    private let tint: Color

    @Environment(\.kitoTheme) private var theme

    public init(quietHours: KitoSettingsQuietHours, now: KitoTimeOfDay? = nil, tint: Color) {
        self.quietHours = quietHours
        self.now = now
        self.tint = tint
    }

    private static let day = Double(KitoTimeOfDay.minutesPerDay)
    private var startFraction: Double { Double(quietHours.start.minutesSinceMidnight) / Self.day }
    private var lengthFraction: Double { Double(quietHours.durationMinutes) / Self.day }

    public var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let line = side * 0.11
            ZStack {
                Circle().stroke(theme.colors.surfaceMuted, lineWidth: line).padding(line / 2)
                arc(line)
                ticks(side)
                if let now { nowDot(now, side: side, line: line) }
                center
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Quiet hours \(quietHours.formatted)")
    }

    private func arc(_ line: CGFloat) -> some View {
        Circle()
            .trim(from: 0, to: lengthFraction)
            .stroke(AngularGradient(colors: [tint.opacity(0.6), tint], center: .center,
                                    startAngle: .zero, endAngle: .degrees(360 * lengthFraction)),
                    style: StrokeStyle(lineWidth: line, lineCap: .round))
            .rotationEffect(.degrees(startFraction * 360 - 90))
            .padding(line / 2)
            .shadow(color: tint.opacity(0.35), radius: 4)
    }

    private func ticks(_ side: CGFloat) -> some View {
        ForEach([0, 6, 12, 18], id: \.self) { hour in
            Text(hour == 0 ? "00" : "\(hour)")
                .font(.system(size: side * 0.075, weight: .semibold).monospacedDigit())
                .foregroundStyle(theme.colors.onSurface.opacity(0.4))
                .offset(Self.offset(hour: Double(hour), radius: side * 0.3))
        }
    }

    private func nowDot(_ time: KitoTimeOfDay, side: CGFloat, line: CGFloat) -> some View {
        let hour = Double(time.minutesSinceMidnight) / 60
        return Circle()
            .fill(theme.colors.surface)
            .overlay(Circle().strokeBorder(theme.colors.onSurface, lineWidth: 2))
            .frame(width: line * 0.9, height: line * 0.9)
            .offset(Self.offset(hour: hour, radius: (side - line) / 2))
    }

    private var center: some View {
        VStack(spacing: 0) {
            Image(systemName: "moon.stars.fill").foregroundStyle(tint).font(.title3)
            Text(quietHours.formattedDuration)
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(theme.colors.onSurface)
        }
    }

    /// Where `hour` sits on a circle of `radius`, midnight at the top, clockwise.
    static func offset(hour: Double, radius: CGFloat) -> CGSize {
        let angle = (hour / 24) * 2 * Double.pi - Double.pi / 2
        return CGSize(width: radius * CGFloat(cos(angle)), height: radius * CGFloat(sin(angle)))
    }
}
