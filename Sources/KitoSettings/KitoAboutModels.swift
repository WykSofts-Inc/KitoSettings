//
//  KitoAboutModels.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// An open-source library the app uses, for the acknowledgements list.
public struct KitoLicense: Identifiable, Hashable, Sendable {
    public var name: String
    /// "MIT", "Apache 2.0".
    public var license: String
    public var url: URL?
    /// The full licence text, shown when the row is opened.
    public var text: String?

    public var id: String { name }

    public init(_ name: String, license: String, url: URL? = nil, text: String? = nil) {
        self.name = name
        self.license = license
        self.url = url
        self.text = text
    }
}

/// A link on the About screen: website, support, terms, rate the app.
public struct KitoAboutLink: Identifiable, Hashable, Sendable {
    public var title: String
    public var systemImage: String
    public var color: Color
    public var url: URL

    public var id: String { title }

    public init(_ title: String, systemImage: String, color: Color = .blue, url: URL) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.url = url
    }
}
