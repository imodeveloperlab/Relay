//
//  StrategyHandler.swift
//  RSSParserTests
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public enum RelayURLProtocolError: Error, LocalizedError {
    case noRequestsToExecute
    public var errorDescription: String? {
        switch self {
        case .noRequestsToExecute:
            return "No request to execute"
        }
    }
}

public final class RelayURLProtocol: URLProtocol {
    
    static var filter: [RequestFilter] = []
    static var request: [RequestProcessor] = []
    static var modify: [ResponseModifier] = []

    public override class func canInit(with request: URLRequest) -> Bool {
        
        guard !filter.isEmpty else {
            return false
        }
        
        if filter.shouldProcess(request: request) {
            Logger.log("Intercepting request", info: ["URL": request.url?.absoluteString ?? ""])
            return true
        }
        return false
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        Logger.log("Canonicalizing request", info: ["URL": request.url?.absoluteString ?? "Unknown URL"])
        return request
    }

    public override func startLoading() {
        guard !Self.request.isEmpty else {
            client?.urlProtocol(self, didFailWithError: Logger.logAndReturn(
                error: RelayURLProtocolError.noRequestsToExecute
            ))
            return
        }
        
        Task {
            do {
                var result = try await Self.request.process(request: request)
                result = try await Self.modify.modify(response: result)
                client?.urlProtocol(self, didReceive: result.httpURLResponse, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: result.responseData)
                client?.urlProtocolDidFinishLoading(self)
                Logger.log("Replayed data", info: ["URL": result.url.absoluteString])
            } catch {
                client?.urlProtocol(self, didFailWithError: Logger.logAndReturn(error: error))
            }
        }
    }

    public override func stopLoading() {
        Logger.log(
            "Stopped loading for URL",
            info: ["URL": request.url?.absoluteString ?? "Unknown URL"]
        )
    }
}

public extension RelayURLProtocol {
    
    static func start(
        filter: [RequestFilter],
        request: [RequestProcessor],
        modify: [ResponseModifier] = [ResponseModifier]()
    ) {
        // We need replay filter to not handle the requests that are already a replay. 
        var filter = filter
        let replayRequestFilter = ReplayRequestFilter()
        filter.append(replayRequestFilter)
        
        self.filter = filter
        self.request = request
        self.modify = modify
        URLProtocol.registerClass(RelayURLProtocol.self)
        URLSessionConfigurationInterceptor.shared.setup()
    }
}
