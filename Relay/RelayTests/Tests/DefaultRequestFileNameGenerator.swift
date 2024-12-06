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
    func basicInputs() async throws {
        
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
    func emptyHeadersAndBody() async throws {
        
        let url = URL(string: "https://example.com/anotherPath")!
        let request = URLRequest(url: url)
        let testName = "EmptyHeadersAndBody"
        
        let fileName = nameGenerator.generateFileName(for: request, additionalName: testName)
        
        #expect(fileName.contains("GET-example.com-anotherPath_be3c53cd64c8bfe8.json"))
    }
    
    @Test
    func sortedHeaders() async throws {
        
        let url = URL(string: "https://example.com/sortedHeaders")!
        var request = URLRequest(url: url)
        request.addValue("Bearer token", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = "another test body".data(using: .utf8)
        let testName = "SortedHeaders"
        
        let fileName = nameGenerator.generateFileName(for: request, additionalName: testName)
        
        #expect(fileName.contains("GET-example.com-sortedHeaders_94101ec1d09e6a70.json"))
    }
    
    @Test
    func unknownDomain() async throws {
        let url = URL(string: "unknown")!
        var request = URLRequest(url: url)
        request.addValue("Bearer token", forHTTPHeaderField: "Authorization")
        request.httpBody = "body with unknown domain".data(using: .utf8)
        let testName = "UnknownDomain"
        
        let fileName = nameGenerator.generateFileName(for: request, additionalName: testName)
        #expect(fileName.contains("unknown"))
        #expect(fileName.hasSuffix(".json"))
    }
    
    @Test
    func longUrl() async throws {
        
        // Construct a URL with a very long path segment
        let longSegment = "thissegmentiswaytoolongandshouldbetruncatedbecauseitexceedsthemaximumlengthallowedbyourlogic"
        let longSegment2 = "toolongandshouldbetruncatedbecauseitexceedsthemaximumlengthallowedbyourlogic"
        let urlString = "https://dev-api.example.com/en/products/\(longSegment)/\(longSegment2)/?locale=en-US&someparam=12345"
        let url = URL(string: urlString)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let fileName = nameGenerator.generateFileName(for: request, additionalName: "LongSegmentTest")
        
        #expect(fileName.hasSuffix(".json"))
        #expect(fileName.contains("thiss.."))
        #expect(fileName.contains("toolo.."))
        
        // Check that at least one query parameter is included
        #expect(fileName.contains("locale=en-US"))
        #expect(fileName == "GET-example.com-en-products-thiss..-toolo..-locale=en-US_someparam=12345_158b6f96fcfd7add.json")
    }
}
