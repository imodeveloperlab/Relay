//
//  SwiftNetworkReplayTests.swift
//  SwiftNetworkReplayTests
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Testing
@testable import Relay

struct SwiftNetworkReplayTests {
    
    let service = JsonplaceholderService()
    
    @Test
    func handleNoRecordFound() async throws {
        let strategy = Relay.recordAndReplay()
        try strategy.removeRecordingSessionFolder()
        await #expect(throws: Error.self) {
            let _ = try await service.getPosts()
        }
    }
    
    @Test
    func addAndReadNewRecord() async throws {

        var strategy = Relay.recordAndReplay(isRecordingEnabled: true)
        try strategy.removeRecordingSessionFolder()
        
        // Perform the GET request
        var post = try await service.getPost(byId: 1)
        #expect(post.result.id == 1)
        
        strategy = Relay.recordAndReplay()
        
        post = try await service.getPost(byId: 1)
        #expect(post.result.id == 1)
        #expect(post.isSwiftNetworkReplay)
        
        try strategy.removeRecordingSessionFolder()
    }
    
    @Test
    func retrievePostsSuccessfully() async throws {
        Relay.recordAndReplay()
        let posts = try await service.getPosts()
        print(posts.headers)
        #expect(!posts.result.isEmpty)
        #expect(posts.isSwiftNetworkReplay)
    }
    
    @Test
    func sendPostSuccessfully() async throws {
        Relay.recordAndReplay()
        let newPost = try await service.sendPost(title: "Hello World", body: "This is a test", userId: 1)
        #expect(newPost.result.id != 0)
        #expect(newPost.isSwiftNetworkReplay)
    }
    
    @Test
    func retrieveUserSuccessfully() async throws {
        Relay.recordAndReplay()
        let user = try await service.getUser(byId: 1)
        #expect(user.result.name == "Leanne Graham")
        #expect(user.isSwiftNetworkReplay)
    }
    
    @Test
    func handleMultipleRequests() async throws {
        Relay.recordAndReplay()
        let posts = try await service.getPosts()
        let newPost = try await service.sendPost(title: "Hello World", body: "This is a test", userId: 1)
        let user = try await service.getUser(byId: 1)
        #expect(!posts.result.isEmpty)
        #expect(newPost.result.id != 0)
        #expect(user.result.name == "Leanne Graham")
        #expect(posts.isSwiftNetworkReplay)
        #expect(newPost.isSwiftNetworkReplay)
        #expect(user.isSwiftNetworkReplay)
    }
    
    @Test
    func restrictToAllowedDomains() async throws {
        Relay.recordAndReplay(urlKeywords: ["google.com"])
        let user = try await service.getUser(byId: 1)
        #expect(user.result.name == "Leanne Graham")
        #expect(!user.isSwiftNetworkReplay)
        
        Relay.recordAndReplay(urlKeywords: ["jsonplaceholder.typicode.com"])
        let newPost = try await service.sendPost(title: "Hello World", body: "This is a test", userId: 1)
        #expect(newPost.isSwiftNetworkReplay)
    }
    
    @Test
    func replaceValueInResult() async throws {
        Relay.recordAndReplay(jsonValueOverrides: ["body" : "This is a replaced value"])
        let newPost = try await service.sendPost(title: "Hello World", body: "This is a test", userId: 1)
        #expect(newPost.isSwiftNetworkReplay)
        #expect(newPost.result.body == "This is a replaced value")
    }
}
