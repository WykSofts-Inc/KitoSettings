//
//  KitoDeleteConfirmation.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// The "type DELETE to confirm" check used by `KitoDeleteAccountFlow`.
public struct KitoDeleteConfirmation: Hashable, Sendable {
    /// What has to be typed, e.g. "DELETE".
    public var phrase: String
    /// When false, "delete" also confirms.
    public var isCaseSensitive: Bool

    public init(phrase: String = "DELETE", isCaseSensitive: Bool = true) {
        self.phrase = phrase
        self.isCaseSensitive = isCaseSensitive
    }

    /// Whether `input` confirms. Surrounding spaces and new lines are ignored.
    public func isConfirmed(by input: String) -> Bool {
        guard !phrase.isEmpty else { return false }
        return normalized(input) == normalized(phrase)
    }

    /// How many of the phrase's characters `input` has typed correctly from the start,
    /// for lighting up letters as they're typed. "DEL" → 3, "DEX" → 2.
    public func matchedCount(of input: String) -> Int {
        let typed = Array(normalized(input))
        let target = Array(normalized(phrase))
        var count = 0
        while count < min(typed.count, target.count), typed[count] == target[count] { count += 1 }
        return count
    }

    /// Whether `input` has gone wrong: it's not a start of the phrase.
    public func hasMistake(in input: String) -> Bool {
        let typed = normalized(input)
        return !typed.isEmpty && matchedCount(of: input) < typed.count
    }

    /// 0 to 1: how much of the phrase has been typed correctly.
    public func progress(of input: String) -> Double {
        guard !phrase.isEmpty else { return 0 }
        return Double(matchedCount(of: input)) / Double(normalized(phrase).count)
    }

    private func normalized(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return isCaseSensitive ? trimmed : trimmed.uppercased()
    }
}
