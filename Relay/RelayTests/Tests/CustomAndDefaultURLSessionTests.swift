//
//  CustomAndDefaultNetworkSessionTests.swift
//  SwiftNetworkReplayTests
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Testing
@testable import Relay

struct CustomAndDefaultURLSessionTests {
    
    @Test
    func defaultSession() async throws {
        Relay.recordAndReplay()
        let service = JsonplaceholderService()
        let posts = try await service.getPosts()
        print(posts.headers)
        #expect(!posts.result.isEmpty)
        #expect(posts.isSwiftNetworkReplay)
    }
    
    @Test
    func customSession() async throws {
        Relay.recordAndReplay()
        
        let customURLSession: URLSession = {
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = ["x-api-key": "someKey" ,"x-platform": "ios", "x-app-version": "1.0.0"]
            return URLSession(configuration: config)
        }()
        
        let service = JsonplaceholderService(urlSession: customURLSession)
        let posts = try await service.getPosts()
        print(posts.headers)
        #expect(!posts.result.isEmpty)
        #expect(posts.isSwiftNetworkReplay)
    }
}
