//
//  DefaultRequestFileNameGenerator.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//  Universal refactored proposal
//


import CryptoKit
import Foundation

/// A protocol that defines a way to generate a file name for a given HTTP request.
public protocol RequestFileNameGenerator {
    /// Generates a file name for a given request and an additional name string.
    ///
    /// - Parameters:
    ///   - request: The URL request for which the file name is generated.
    ///   - additionalName: An additional string used as part of the hash input for uniqueness.
    /// - Returns: A suggested file name (including `.json` extension).
    func generateFileName(for request: URLRequest, additionalName: String) -> String
}

/// A default implementation that generates readable and unique file names for requests.
public final class DefaultRequestFileNameGenerator: RequestFileNameGenerator {
    
    public init() {}

    public func generateFileName(for request: URLRequest, additionalName: String) -> String {
        
        guard let requestURL = request.url else {
            // If URL is missing:
            // Returns: "UNKNOWN_UNKNOWN_UNKNOWN.json"
            return "UNKNOWN_UNKNOWN_UNKNOWN.json"
        }
        
        // Extract and sanitize domain, then get base domain.
        // Example input domain: "dev-api.example.com"
        // Example output domain: "example.com"
        let sanitizedDomain = (requestURL.host ?? "unknown_domain").sanitizedDomain()
        let baseDomain = extractBaseDomain(from: sanitizedDomain)
        
        // Get HTTP method or "UNKNOWN"
        // Example: If request.httpMethod is "GET", use "GET".
        // If nil, use "UNKNOWN".
        let httpMethod = request.httpMethod ?? "UNKNOWN"
        
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)
        
        // Extract path segments:
        // Example input path: "/en/customers/(ITEM1,ITEM2)/details"
        // Example output segments: ["en", "customers", "ARRAY_OF_ITEMS", "details"]
        let pathSegments = extractPathSegments(from: components?.path ?? "")
        
        // Extract a limited set of query parameters:
        // Example query: "locale=en-US&start=20"
        // Output: "locale=en-US_start=20" (if truncated to first 3 and sorted)
        let queryPart = extractSomeQueryParameters(from: components?.queryItems ?? [])
        
        // Construct base name parts:
        // Example: method="GET", domain="example.com",
        // pathSegments=["en","customers","auth"], queryPart="locale=en-US"
        // Output parts: ["GET","example.com","en","customers","auth","locale=en-US"]
        let baseNameParts = constructBaseNameParts(
            method: httpMethod,
            domain: baseDomain,
            pathSegments: pathSegments,
            queryPart: queryPart
        )
        
        // Join parts with "-"
        // Example:
        // ["GET","example.com","en","customers","auth","locale=en-US"]
        // "GET_example.com_en_customers_auth_locale=en-US"
        let baseName = baseNameParts.joined(separator: "-")
        
        // Compute a unique hash:
        // Example output: "a1b2c3d4"
        let fileNameHash = computeRequestHash(request: request, additionalName: additionalName)
        
        // Final:
        // "GET_example.com_en_customers_auth_locale=en-US_a1b2c3d4.json"
        return "\(baseName)_\(fileNameHash).json"
    }

    // Extracts base domain by taking the last two parts if there are more than two parts.
    // Example input: "dev-api.example.com"
    // Example output: "example.com"
    // Example input: "example.com"
    // Example output: "example.com"
    private func extractBaseDomain(from domain: String) -> String {
        let parts = domain.split(separator: ".").map { String($0) }
        if parts.count > 2 {
            return parts.suffix(2).joined(separator: ".")
        }
        return domain
    }

    // Splits path into segments, converts array-like segments to "ARRAY_OF_ITEMS",
    // and truncates long segments.
    // Example input: "/en/customers/(ITEM1,ITEM2)/details"
    // Example output: ["en", "customers", "ARRAY_OF_ITEMS", "details"]
    // Example input: "/en/products/verylongsegmentnamehere"
    // Output: ["en","products","verylongsegm..."]
    private func extractPathSegments(from path: String) -> [String] {
        let originalSegments = path
            .split(separator: "/")
            .map { String($0) }
            .filter { !$0.isEmpty }
        
        let processed = originalSegments.map { segment -> String in
            if segment.contains("(") && segment.contains(")") {
                return "ARRAY_OF_ITEMS"
            }
            return truncateIfTooLong(segment, maxLength: 20)
        }
        
        return processed
    }

    // Extracts up to 3 query parameters, sorts them alphabetically, and truncates long values.
    // Example input queries: "locale=en-US&start=20&expand=availability"
    // Sorted: expand, locale, start
    // Output: "expand=availability_locale=en-US_start=20"
    private func extractSomeQueryParameters(from queryItems: [URLQueryItem]) -> String {
        guard !queryItems.isEmpty else { return "" }
        
        let sortedItems = queryItems.sorted { $0.name < $1.name }
        let pickedItems = sortedItems.prefix(3)
        
        let params = pickedItems.compactMap { item -> String? in
            guard let value = item.value else { return nil }
            let truncatedValue = truncateIfTooLong(value, maxLength: 15)
            return "\(item.name)=\(truncatedValue)"
        }
        
        return params.joined(separator: "_")
    }

    // Constructs array of parts: method, domain, path segments, query part if any.
    // Example:
    // method="GET", domain="example.com"
    // pathSegments=["en","customers","auth"], queryPart="locale=en-US"
    // Output: ["GET","example.com","en","customers","auth","locale=en-US"]
    private func constructBaseNameParts(method: String, domain: String, pathSegments: [String], queryPart: String) -> [String] {
        var parts = [method, domain]
        parts.append(contentsOf: pathSegments)
        if !queryPart.isEmpty { parts.append(queryPart) }
        return parts
    }

    // Truncates a string if longer than maxLength.
    // Keeps first 10 chars and appends "...".
    // Example:
    // Input: "this-is-a-very-long-segment"
    // Output: "this-is-a-..."
    private func truncateIfTooLong(_ input: String, maxLength: Int) -> String {
        guard input.count > maxLength else { return input }
        let truncationMark = ".."
        let cutLength = 5
        let prefix = input.prefix(cutLength)
        return "\(prefix)\(truncationMark)"
    }

    // Computes a short hash from request details and additionalName.
    // Ensures uniqueness if requests differ slightly.
    // Example:
    // Input: request + "MyTestName"
    // Output: "a1b2c3d4"
    private func computeRequestHash(request: URLRequest, additionalName: String) -> String {
        let headersKeyValueString = request.allHTTPHeaderFields?
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "&") ?? ""

        let requestBodyString = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let urlString = request.url?.absoluteString ?? ""
        let hashInput = "\(additionalName)\(headersKeyValueString)\(requestBodyString)\(urlString)"
        return sha256Hash(for: hashInput)
    }

    // Computes first 8 chars of SHA-256 hash hex digest.
    // Example:
    // Input: "test"
    // Output: "9f86d08f" (example)
    private func sha256Hash(for input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - String Sanitization

fileprivate extension String {
    /// Sanitizes the domain by removing "www.", and replacing certain characters:
    /// colons and slashes are removed or replaced with underscores to make it file-system safe.
    ///
    /// **Example**
    /// ```swift
    /// "www.dev-api:8080/example".sanitizedDomain()
    /// // returns "dev-api8080_example"
    /// ```
    func sanitizedDomain() -> String {
        var sanitized = self
        sanitized = sanitized.replacingOccurrences(of: "www.", with: "")
        sanitized = sanitized.replacingOccurrences(of: ":", with: "")
        sanitized = sanitized.replacingOccurrences(of: "/", with: "_")
        return sanitized
    }
}
