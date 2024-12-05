//
//  DefaultHTTPDataTaskSerializerTests.swift
//  SwiftNetworkReplayTests
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Testing
@testable import Relay

struct DefaultHTTPDataTaskSerializerTests {
    
    let serializer = DefaultHTTPDataTaskSerializer()

    @Test
    func encodeWithValidInputs() async throws {
        
        // Arrange
        let url = URL(string: "https://example.com/api/call")!
        var newRequest = URLRequest(url: url)
        newRequest.httpMethod = "POST"
        newRequest.httpBody = "test body".data(using: .utf8)
        newRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let responseData = "{\"key\":\"value\"}".data(using: .utf8)!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )

        // Act
        let encodedData = try serializer.encode(
            request: newRequest,
            responseData: responseData,
            httpResponse: httpResponse
        )

        // Assert
        let json = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any]
        #expect(json != nil)
        #expect(json?["service"] as? String == "https://example.com/api/call")
        #expect(json?["requestType"] as? String == "POST")
        #expect((json?["requestHeaders"] as? [String: String])?["Content-Type"] == "application/json")

        let requestBody = try #require(json?["requestBody"] as? [String: Any])
        #expect(requestBody["data"] as? String == "test body")
        #expect(requestBody["isBase64Encoded"] as? Bool == false)
        #expect(json?["statusCode"] as? Int == 200)

        let responseDataDict = try #require(json?["responseData"] as? [String: Any])
        #expect(responseDataDict["data"] as? String == "{\"key\":\"value\"}")
        #expect(responseDataDict["isBase64Encoded"] as? Bool == false)
    }

    @Test
    func decodeWithValidInputs() async throws {
        
        // Arrange
        let url = URL(string: "https://example.com/api")!
        let request = URLRequest(url: url)

        let responseObject: [String: Any] = [
            "service": "example.com",
            "requestType": "GET",
            "requestHeaders": ["Accept": "application/json"],
            "requestBody": [
                "data": "",
                "isBase64Encoded": false
            ],
            "responseHeaders": ["Content-Type": "application/json"],
            "statusCode": 200,
            "responseData": [
                "data": "{\"key\":\"value\"}",
                "isBase64Encoded": false
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])

        // Act
        let (httpURLResponse, responseData) = try serializer.decode(request: request, data: data)

        // Assert
        #expect(httpURLResponse.statusCode == 200)
        #expect(httpURLResponse.allHeaderFields["Content-Type"] as? String == "application/json")
        #expect(httpURLResponse.allHeaderFields["X-RelayReplay"] as? String == "true")

        let responseString = String(data: responseData, encoding: .utf8)
        #expect(responseString == "{\"key\":\"value\"}")
    }

    @Test
    func dncodeWithBinaryData() async throws {
        // Arrange
        let url = URL(string: "https://example.com/binary")!
        var newRequest = URLRequest(url: url)
        newRequest.httpMethod = "PUT"
        newRequest.httpBody = Data([0x00, 0xFF, 0xAA, 0x55])
        newRequest.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let responseData = Data([0x11, 0x22, 0x33, 0x44])
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 201,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/octet-stream"]
            )
        )

        // Act
        let encodedData = try serializer.encode(
            request: newRequest,
            responseData: responseData,
            httpResponse: httpResponse
        )

        // Assert
        let json = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any]
        #expect(json != nil, "Encoded data should be valid JSON")

        let requestBody = try #require(json?["requestBody"] as? [String: Any])
        #expect(requestBody["isBase64Encoded"] as? Bool == true)
        let requestDataString = requestBody["data"] as? String
        let decodedData = Data(base64Encoded: requestDataString ?? "")
        #expect(decodedData == Data([0x00, 0xFF, 0xAA, 0x55]))

        let responseDataDict = try #require(json?["responseData"] as? [String: Any])
        #expect(responseDataDict["isBase64Encoded"] as? Bool == true)
        let responseDataString = responseDataDict["data"] as? String
        let responseDecodedData = Data(base64Encoded: responseDataString ?? "")
        #expect(responseDecodedData == Data([0x11, 0x22, 0x33, 0x44]))
    }

    @Test
    func decodeWithMissingFields() async throws {
        // Arrange
        let url = URL(string: "https://example.com/missingFields")!
        let request = URLRequest(url: url)

        let responseObject: [String: Any] = [
            // Intentionally omitting 'responseData' and 'statusCode'
            "service": "example.com",
            "requestType": "GET",
            "requestHeaders": [:],
            "requestBody": [
                "data": "",
                "isBase64Encoded": false
            ],
            "responseHeaders": [:]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])
        let result = try? serializer.decode(request: request, data: data)
        #expect(result == nil)
    }

    @Test
    func decodeWithCorruptedData() async throws {
        // Arrange
        let url = URL(string: "https://example.com/corruptedData")!
        let request = URLRequest(url: url)
        let corruptedData = "Not a JSON string".data(using: .utf8)!

        // Act & Assert
        #expect(throws: Error.self) {
            try serializer.decode(request: request, data: corruptedData)
        }
    }

    @Test
    func decodeWithBase64EncodedResponseData() async throws {
        // Arrange
        let url = URL(string: "https://example.com/base64Response")!
        let request = URLRequest(url: url)

        let binaryData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let base64String = binaryData.base64EncodedString()

        let responseObject: [String: Any] = [
            "service": "example.com",
            "requestType": "GET",
            "requestHeaders": [:],
            "requestBody": [
                "data": "",
                "isBase64Encoded": false
            ],
            "responseHeaders": [:],
            "statusCode": 200,
            "responseData": [
                "data": base64String,
                "isBase64Encoded": true
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])

        // Act
        let (httpURLResponse, responseData) = try serializer.decode(request: request, data: data)

        // Assert
        #expect(responseData == binaryData)
        #expect(httpURLResponse.statusCode == 200)
    }

    @Test
    func encodeWithNoRequestBody() async throws {
        // Arrange
        let url = URL(string: "https://example.com/noBody")!
        var newRequest = URLRequest(url: url)
        newRequest.httpMethod = "DELETE"

        let responseData = Data()
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 204,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        // Act
        let encodedData = try serializer.encode(
            request: newRequest,
            responseData: responseData,
            httpResponse: httpResponse
        )

        // Assert
        let json = try JSONSerialization.jsonObject(with: encodedData, options: []) as? [String: Any]
        #expect(json != nil, "Encoded data should be valid JSON")
        #expect((json?["requestBody"] as? [String: Any])?["data"] as? String == "")
    }

    @Test
    func decodeWithEmptyResponseData() async throws {
        // Arrange
        let url = URL(string: "https://example.com/emptyResponse")!
        let request = URLRequest(url: url)

        let responseObject: [String: Any] = [
            "service": "example.com",
            "requestType": "GET",
            "requestHeaders": [:],
            "requestBody": [
                "data": "",
                "isBase64Encoded": false
            ],
            "responseHeaders": [:],
            "statusCode": 204,
            "responseData": [
                "data": "",
                "isBase64Encoded": false
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: responseObject, options: [])

        // Act
        let (httpURLResponse, responseData) = try serializer.decode(request: request, data: data)

        // Assert
        #expect(responseData.isEmpty)
        #expect(httpURLResponse.statusCode == 204)
    }
    
    @Test
    func encodeAndDecodeWithNestedJsonString() async throws {
        // Arrange
        let url = URL(string: "https://example.com/api/nestedjson")!
        var newRequest = URLRequest(url: url)
        newRequest.httpMethod = "GET"
        newRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Response data is JSON that contains a property with a JSON string in it
        let nestedJsonString = """
            {"key1":"value1","key2":{"subkey1":"subvalue1","subkey2":["item1","item2",{"deepkey":"deepvalue"}]},"key3":[{"arraykey1":"arrayvalue1"},{"arraykey2":"arrayvalue2"}]}
            """
        let responseObject: [String: Any] = [
            "id": 1,
            "nestedJson": nestedJsonString
        ]
        let responseData = try JSONSerialization.data(withJSONObject: responseObject, options: [])

        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        // Act
        let encodedData = try serializer.encode(
            request: newRequest,
            responseData: responseData,
            httpResponse: httpResponse
        )

        // Decode the data back
        let (decodedResponse, decodedData) = try serializer.decode(request: newRequest, data: encodedData)

        // Assert
        #expect(decodedResponse.statusCode == 200)
        #expect(decodedResponse.allHeaderFields["Content-Type"] as? String == "application/json")
        
        // Convert decodedData back to JSON object
        let decodedResponseObject = try JSONSerialization.jsonObject(with: decodedData, options: []) as? [String: Any]
        #expect(decodedResponseObject != nil)
        #expect(decodedResponseObject?["id"] as? Int == 1)
        #expect(decodedResponseObject?["nestedJson"] as? String == nestedJsonString)
    }
}
