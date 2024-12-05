//
//  ReplayRequestFilter.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


public final class ReplayRequestFilter: RequestFilter {
    public func shouldProcess(request: URLRequest) -> Bool {
        return request.value(forHTTPHeaderField: "X-RelayReplay") == nil
    }
}
