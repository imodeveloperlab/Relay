//
//  FileNameResolver.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import CryptoKit
import Foundation

public protocol RequestFileNameGenerator {
    func generateFileName(for request: URLRequest, additionalName: String) -> String
}

public final class DefaultRequestFileNameGenerator: RequestFileNameGenerator {
    
    public init() {}
    
    public func generateFileName(for request: URLRequest, additionalName: String) -> String {
        
        guard let requestURL = request.url else {
            return "UNKNOWN_UNKNOWN_UNKNOWN.json"
        }
        
        let sanitizedDomain = (requestURL.host ?? "unknown_domain").sanitizedDomain()

        let headersKeyValueString = request.allHTTPHeaderFields?
            .sorted(by: { $0.key < $1.key }) // Sort headers alphabetically by key
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "&") ?? ""

        let requestBodyString = request.httpBody
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        
        let hashInput = "\(additionalName)\(headersKeyValueString)\(requestBodyString)\(requestURL.absoluteString)"
        let fileNameHash = sha256Hash(for: hashInput)

        let httpMethod = request.httpMethod ?? "UNKNOWN"
        
        return "\(httpMethod)_\(sanitizedDomain)_\(fileNameHash).json"
    }

    private func sha256Hash(for input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}

fileprivate extension String {
    func sanitizedDomain() -> String {
        var sanitized = self
        sanitized = sanitized.replacingOccurrences(of: "www.", with: "")
        sanitized = sanitized.replacingOccurrences(of: ":", with: "")
        sanitized = sanitized.replacingOccurrences(of: "/", with: "_")
        return sanitized
    }
}
