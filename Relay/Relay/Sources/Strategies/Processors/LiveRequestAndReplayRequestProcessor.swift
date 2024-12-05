//
//  LiveRequestAndReplayRequestProcessor.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public enum LiveRequestAndReplayRequestProcessorError: Error, LocalizedError {
    case invalidUrlInRequest(URLRequest)
    public var errorDescription: String? {
        switch self {
        case .invalidUrlInRequest(let request):
            return "Invalid URL in the request. Request: \(request.debugDescription)"
        }
    }
}

public final class LiveRequestAndReplayRequestProcessor: RequestProcessor {
    public init() { }
    let liveRequestPerformer = DefaultLiveRequestPerformer()
    public func process(request: URLRequest) async throws -> NetworkResponse {
        guard let url = request.url else {
            throw Logger.logAndReturn(error: LiveRequestAndReplayRequestProcessorError.invalidUrlInRequest(request))
        }
        let (data, response) = try await liveRequestPerformer.performRequest(request)
        return NetworkResponse(
            url: url,
            httpURLResponse: response,
            responseData: data
        )
    }
}
