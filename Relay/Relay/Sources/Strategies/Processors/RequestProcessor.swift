//
//  RequestProcessor.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public enum RequestProcessorError: Error, LocalizedError {
    case noRequestsToExecute
    public var errorDescription: String? {
        switch self {
        case .noRequestsToExecute:
            return "No requests to execute"
        }
    }
}

public protocol RequestProcessor {
    func process(request: URLRequest) async throws -> NetworkResponse
}

extension Array: RequestProcessor where Element == RequestProcessor {
    public func process(request: URLRequest) async throws -> NetworkResponse {
        for task in self {
            return try await task.process(request: request)
        }
        throw RequestProcessorError.noRequestsToExecute
    }
}
