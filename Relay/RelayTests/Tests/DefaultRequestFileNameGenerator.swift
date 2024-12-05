//
//  DefaultRequestFileNameGenerator.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


import Testing
@testable import Relay

struct DefaultRequestFileNameGeneratorTests {
    
    let nameGenerator = DefaultRequestFileNameGenerator()

    @Test
    func generateFileNameWithBasicInputs() async throws {
        
        let url = URL(string: "https://example.com/path")!
        var request = URLRequest(url: url)
        request.addValue("Bearer token", forHTTPHeaderField: "Authorization")
        request.httpBody = "test body".data(using: .utf8)
        let testName = "TestCase"

        let fileName = nameGenerator.generateFileName(for: request, additionalName: testName)

        #expect(fileName.hasSuffix(".json"))
        #expect(fileName.contains("example.com"))
    }

    @Test
    func generateFileNameWithEmptyHeadersAndBody() async throws {
        
        let url = URL(string: "https://example.com/anotherPath")!
        let request = URLRequest(url: url)
        let testName = "EmptyHeadersAndBody"

        let fileName = nameGenerator.generateFileName(for: request, additionalName: testName)
        
        #expect(fileName.contains("GET_example.com_be3c53cd64c8bfe8.json"))
    }

    @Test
    func generateFileNameWithSortedHeaders() async throws {
        
        let url = URL(string: "https://example.com/sortedHeaders")!
        var request = URLRequest(url: url)
        request.addValue("Bearer token", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = "another test body".data(using: .utf8)
        let testName = "SortedHeaders"

        let fileName = nameGenerator.generateFileName(for: request, additionalName: testName)
        
        #expect(fileName.contains("GET_example.com_94101ec1d09e6a70.json"))
    }

    @Test
    func generateFileNameWithUnknownDomain() async throws {
        let url = URL(string: "unknown")!
        var request = URLRequest(url: url)
        request.addValue("Bearer token", forHTTPHeaderField: "Authorization")
        request.httpBody = "body with unknown domain".data(using: .utf8)
        let testName = "UnknownDomain"

        let fileName = nameGenerator.generateFileName(for: request, additionalName: testName)
        #expect(fileName.contains("unknown"))
        #expect(fileName.hasSuffix(".json"))
    }
}

