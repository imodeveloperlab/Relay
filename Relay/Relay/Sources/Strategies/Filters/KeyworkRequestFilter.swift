//
//  KeywordRequestFilter.swift
//  SwiftNetworkReplay
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public final class KeywordRequestFilter: RequestFilter {
    
    private var urlKeywordsForReplay: [String] = []
    
    init(urlKeywordsForReplay: [String]) {
        self.urlKeywordsForReplay = urlKeywordsForReplay
    }
    
    public func shouldProcess(request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }
        if !urlKeywordsForReplay.isEmpty && !containsReplayKeyword(in: url) {
            return false
        }
        return true
    }
    
    private func containsReplayKeyword(in url: URL) -> Bool {
        let urlString = url.absoluteString
        return urlKeywordsForReplay.contains { keyword in
            urlString.contains(keyword)
        }
    }
}
