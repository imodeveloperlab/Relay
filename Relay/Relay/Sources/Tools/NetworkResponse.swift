//
//  NetworkResponse.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


public struct NetworkResponse {
    let url: URL
    let httpURLResponse: HTTPURLResponse
    let responseData: Data
}
