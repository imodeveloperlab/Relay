//
//  InterceptionConfig.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

/// Configuration for intercepting and modifying network requests.
public struct InterceptionConfig {
    /// A list of keywords to filter URLs for interception.
    let urlKeywords: [String]
    /// A dictionary of JSON keys and their replacement values in responses.
    let jsonValueOverrides: [String: String]

    /// Initializes a new instance of `InterceptionConfig`.
    ///
    /// - Parameters:
    ///   - urlKeywords: A list of keywords to filter URLs for interception.
    ///   - jsonValueOverrides: A dictionary of JSON keys and their replacement values in responses.
    public init(urlKeywords: [String], jsonValueOverrides: [String: String]) {
        self.urlKeywords = urlKeywords
        self.jsonValueOverrides = jsonValueOverrides
    }
}
