//
//  RequestFilter.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


public protocol RequestFilter {
    func shouldProcess(request: URLRequest) -> Bool
}

extension Array: RequestFilter where Element == RequestFilter {
    public func shouldProcess(request: URLRequest) -> Bool {
        for task in self {
            if task.shouldProcess(request: request) {
                continue
            } else {
                return false
            }
        }
        return true
    }
}
