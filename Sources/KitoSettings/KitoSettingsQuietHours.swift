//
//  KitoSettingsQuietHours.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// A time on a 24-hour clock, without a date.
public struct KitoTimeOfDay: Hashable, Comparable, Codable, Sendable {
    public var hour: Int
    public var minute: Int

    /// Out-of-range values wrap: 25:10 is 01:10, -1:00 is 23:00.
    public init(hour: Int, minute: Int = 0) {
        let total = Self.wrap(hour * 60 + minute)
        self.hour = total / 60
        self.minute = total % 60
    }

    public init(minutesSinceMidnight: Int) {
        self.init(hour: 0, minute: minutesSinceMidnight)
    }

    /// The time of day of `date` in `calendar`.
    public init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    public var minutesSinceMidnight: Int { hour * 60 + minute }

    /// "22:00".
    public var formatted: String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// Today's date at this time, for a `DatePicker`.
    public func date(on day: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }

    static let minutesPerDay = 24 * 60

    static func wrap(_ minutes: Int) -> Int {
        ((minutes % minutesPerDay) + minutesPerDay) % minutesPerDay
    }
}

/// A daily "do not disturb" window that may cross midnight, such as 22:00 – 07:00.
public struct KitoSettingsQuietHours: Hashable, Codable, Sendable {
    public var isEnabled: Bool
    public var start: KitoTimeOfDay
    public var end: KitoTimeOfDay

    public init(isEnabled: Bool = true,
                start: KitoTimeOfDay = KitoTimeOfDay(hour: 22),
                end: KitoTimeOfDay = KitoTimeOfDay(hour: 7)) {
        self.isEnabled = isEnabled
        self.start = start
        self.end = end
    }

    /// Whether the window runs past midnight.
    public var crossesMidnight: Bool { end < start }

    /// Length in minutes. A window whose start equals its end lasts all day (1440).
    public var durationMinutes: Int {
        let length = KitoTimeOfDay.wrap(end.minutesSinceMidnight - start.minutesSinceMidnight)
        return length == 0 ? KitoTimeOfDay.minutesPerDay : length
    }

    /// Whether `time` falls inside the window: the start is included, the end isn't.
    /// Ignores `isEnabled`; use `isQuiet(at:)` for that.
    public func contains(_ time: KitoTimeOfDay) -> Bool {
        let offset = KitoTimeOfDay.wrap(time.minutesSinceMidnight - start.minutesSinceMidnight)
        return offset < durationMinutes
    }

    /// Whether notifications should be quiet at `date`: enabled and inside the window.
    public func isQuiet(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        isEnabled && contains(KitoTimeOfDay(date, calendar: calendar))
    }

    /// Whether two windows share any minute, each read as a daily repeating window.
    public func overlaps(_ other: KitoSettingsQuietHours) -> Bool {
        contains(other.start) || other.contains(start)
    }

    /// Minutes from `time` until the window next starts (0 when it's already quiet).
    public func minutesUntilQuiet(from time: KitoTimeOfDay) -> Int {
        guard !contains(time) else { return 0 }
        return KitoTimeOfDay.wrap(start.minutesSinceMidnight - time.minutesSinceMidnight)
    }

    /// "22:00 – 07:00".
    public var formatted: String { "\(start.formatted) – \(end.formatted)" }

    /// "9 h" or "8 h 30 min".
    public var formattedDuration: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        if minutes == 0 { return "\(hours) h" }
        if hours == 0 { return "\(minutes) min" }
        return "\(hours) h \(minutes) min"
    }
}
