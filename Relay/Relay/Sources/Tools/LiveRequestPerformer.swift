//
//  LiveRequestPerformer.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public enum LiveRequestPerformerError: Error, LocalizedError {
    
    case invalidResponse(URLRequest)
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let request):
            return "Invalid response for request:\n\(request.debugDescription)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

// MARK: - Live Request Performer Protocol

public protocol LiveRequestPerformer {
    func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

// MARK: - Default Implementation

public final class DefaultLiveRequestPerformer: LiveRequestPerformer {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.asyncData(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Logger.logAndReturn(error: LiveRequestPerformerError.invalidResponse(request))
        }
        return (data, httpResponse)
    }
}

// MARK: - URLSession Extension

extension URLSession {
    func asyncData(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(
                        throwing: LiveRequestPerformerError.unknownError
                    )
                }
            }
            task.resume()
        }
    }
}
