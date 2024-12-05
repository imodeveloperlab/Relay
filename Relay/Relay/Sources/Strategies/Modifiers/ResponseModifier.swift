//
//  ResponseModifier.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public protocol ResponseModifier {
    func modify(response: NetworkResponse) async throws -> NetworkResponse
}

extension Array: ResponseModifier where Element == ResponseModifier {
    public func modify(response: NetworkResponse) async throws -> NetworkResponse {
        var processedResponse = response
        for task in self {
            processedResponse = try await task.modify(response: processedResponse)
        }
        return processedResponse
    }
}
