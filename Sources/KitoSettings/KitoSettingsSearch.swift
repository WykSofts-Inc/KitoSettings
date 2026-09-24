//
//  KitoSettingsSearch.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Anything the settings search can find: a title, an optional subtitle and extra keywords
/// ("wifi", "network") that never show on screen.
public protocol KitoSettingsSearchable {
    var searchTitle: String { get }
    var searchSubtitle: String? { get }
    var searchKeywords: [String] { get }
}

/// Matching for the settings search field. Every word of the query has to match: the start of a
/// word in the title, subtitle or keywords, or anywhere inside the title. Case and accents are
/// ignored, so "cafe" finds "Café".
public enum KitoSettingsSearch {
    /// How well `item` matches `query`, from 0 (no match) to 1 (the title starts with the query).
    /// An empty query matches everything with a score of 1.
    public static func score(_ item: some KitoSettingsSearchable, query: String) -> Double {
        let words = tokens(query)
        guard !words.isEmpty else { return 1 }
        let title = normalize(item.searchTitle)
        let whole = words.joined(separator: " ")
        if title.hasPrefix(whole) { return 1 }
        let titleWords = tokens(item.searchTitle)
        let subtitleWords = tokens(item.searchSubtitle ?? "")
        let keywordWords = item.searchKeywords.flatMap { tokens($0) }
        var total = 0.0
        for word in words {
            let best = wordScore(word, title: title, titleWords: titleWords,
                                 subtitleWords: subtitleWords, keywordWords: keywordWords)
            guard best > 0 else { return 0 }
            total += best
        }
        return total / Double(words.count)
    }

    /// Whether `item` matches `query` at all.
    public static func matches(_ item: some KitoSettingsSearchable, query: String) -> Bool {
        score(item, query: query) > 0
    }

    /// The items that match `query`, best first; ties keep their original order.
    /// An empty query returns `items` unchanged.
    public static func filter<Item: KitoSettingsSearchable>(_ items: [Item], query: String) -> [Item] {
        guard !tokens(query).isEmpty else { return items }
        let scored = items.enumerated().compactMap { index, item -> (Int, Double, Item)? in
            let value = score(item, query: query)
            return value > 0 ? (index, value, item) : nil
        }
        return scored.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0 < $1.0 }.map(\.2)
    }

    /// Where the query's first word appears in `text`, for highlighting. Nil when it doesn't.
    public static func highlightRange(in text: String, query: String) -> Range<String.Index>? {
        guard let word = query.split(whereSeparator: \.isWhitespace).first else { return nil }
        return text.range(of: String(word), options: [.caseInsensitive, .diacriticInsensitive])
    }

    /// Lowercased, accent-free, trimmed.
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Normalised words, split on anything that isn't a letter or digit.
    static func tokens(_ text: String) -> [String] {
        normalize(text)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private static func wordScore(_ word: String, title: String, titleWords: [String],
                                  subtitleWords: [String], keywordWords: [String]) -> Double {
        if titleWords.contains(where: { $0.hasPrefix(word) }) { return 0.9 }
        if keywordWords.contains(where: { $0.hasPrefix(word) }) { return 0.75 }
        if subtitleWords.contains(where: { $0.hasPrefix(word) }) { return 0.6 }
        if word.count >= 3, title.contains(word) { return 0.5 }
        return 0
    }
}
