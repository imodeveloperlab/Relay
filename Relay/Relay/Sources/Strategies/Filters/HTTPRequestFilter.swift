//
//  HTTPRequestFilter.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public final class HTTPRequestFilter: RequestFilter {
    
    private func isHttpRequest(url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }
    
    public func shouldProcess(request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        guard isHttpRequest(url: url) else {
            return false
        }
        return true
    }
}
