//
//  SimulatedService.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

// MARK: - Post
struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

// MARK: - Comment
struct Comment: Codable {
    let postId: Int
    let id: Int
    let name: String
    let email: String
    let body: String
}

// MARK: - Album
struct Album: Codable {
    let userId: Int
    let id: Int
    let title: String
}

// MARK: - Photo
struct Photo: Codable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}

// MARK: - User
struct User: Codable {
    struct Address: Codable {
        struct Geo: Codable {
            let lat: String
            let lng: String
        }
        let street: String
        let suite: String
        let city: String
        let zipcode: String
        let geo: Geo
    }
    struct Company: Codable {
        let name: String
        let catchPhrase: String
        let bs: String
    }
    let id: Int
    let name: String
    let username: String
    let email: String
    let address: Address
    let phone: String
    let website: String
    let company: Company
}


import Foundation

// MARK: - JsonplaceholderServiceError
enum JsonplaceholderServiceError: Error, LocalizedError {
    case invalidHTTPResponse(URL, Int?)
    case failedToDecode(URL, String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse(let url, let statusCode):
            return "Invalid HTTP response for URL: \(url.absoluteString). Status code: \(statusCode ?? -1)"
        case .failedToDecode(let url, let description):
            return "Failed to decode response from URL: \(url.absoluteString). Error: \(description)"
        }
    }
}

// MARK: - TestableResultStruct
struct TestableResultStruct<T: Codable>: Codable {
    let result: T
    let headers: [String: String]
    var isSwiftNetworkReplay: Bool {
        return headers["X-RelayReplay"] == "true"
    }
}

// MARK: - JsonplaceholderService
class JsonplaceholderService {
    
    private var baseURL: URL = URL(string: "https://jsonplaceholder.typicode.com")!
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    var urlSession: URLSession
    
    /// Executes a network request with the specified parameters and decodes the response into `TestableResultStruct`.
    private func executeRequest<T: Decodable>(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil,
        decodingType: T.Type
    ) async throws -> TestableResultStruct<T> {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JsonplaceholderServiceError.invalidHTTPResponse(url, nil)
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw JsonplaceholderServiceError.invalidHTTPResponse(url, httpResponse.statusCode)
        }
        
        do {
            let decodedResult = try JSONDecoder().decode(T.self, from: data)
            let responseHeaders = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, pair in
                if let key = pair.key as? String, let value = pair.value as? String {
                    result[key] = value
                }
            }
            return TestableResultStruct(result: decodedResult, headers: responseHeaders)
        } catch {
            throw JsonplaceholderServiceError.failedToDecode(url, error.localizedDescription)
        }
    }
    
    // MARK: - API Methods
    
    func getPosts() async throws -> TestableResultStruct<[Post]> {
        let url = baseURL.appendingPathComponent("/posts")
        return try await executeRequest(url: url, decodingType: [Post].self)
    }
    
    func getPost(byId id: Int) async throws -> TestableResultStruct<Post> {
        let url = baseURL.appendingPathComponent("/posts/\(id)")
        return try await executeRequest(url: url, decodingType: Post.self)
    }
    
    func sendPost(title: String, body: String, userId: Int) async throws -> TestableResultStruct<Post> {
        let url = baseURL.appendingPathComponent("/posts")
        let payload = Post(userId: userId, id: 0, title: title, body: body) // id will be ignored by the server
        let bodyData = try JSONEncoder().encode(payload)
        return try await executeRequest(
            url: url,
            method: "POST",
            headers: ["Content-Type": "application/json"],
            body: bodyData,
            decodingType: Post.self
        )
    }
    
    func getComments(forPostId postId: Int) async throws -> TestableResultStruct<[Comment]> {
        let url = baseURL.appendingPathComponent("/posts/\(postId)/comments")
        return try await executeRequest(url: url, decodingType: [Comment].self)
    }
    
    func getAllComments() async throws -> TestableResultStruct<[Comment]> {
        let url = baseURL.appendingPathComponent("/comments")
        return try await executeRequest(url: url, decodingType: [Comment].self)
    }
    
    func getAlbums() async throws -> TestableResultStruct<[Album]> {
        let url = baseURL.appendingPathComponent("/albums")
        return try await executeRequest(url: url, decodingType: [Album].self)
    }
    
    func getPhotos(forAlbumId albumId: Int) async throws -> TestableResultStruct<[Photo]> {
        let url = baseURL.appendingPathComponent("/albums/\(albumId)/photos")
        return try await executeRequest(url: url, decodingType: [Photo].self)
    }
    
    func getUsers() async throws -> TestableResultStruct<[User]> {
        let url = baseURL.appendingPathComponent("/users")
        return try await executeRequest(url: url, decodingType: [User].self)
    }
    
    func getUser(byId id: Int) async throws -> TestableResultStruct<User> {
        let url = baseURL.appendingPathComponent("/users/\(id)")
        return try await executeRequest(url: url, decodingType: User.self)
    }
}

