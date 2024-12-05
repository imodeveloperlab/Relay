//
//  ReplaceJSONValueForKeyResponseModifierTests.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


import Testing
@testable import Relay

struct ReplaceJSONValueForKeyResponseModifierTests {
    
    @Test
    func modifyWithFlatJSON() async throws {
        // Arrange
        let jsonString = """
        {
            "name": "Alice",
            "age": 30,
            "city": "San Francisco"
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob", "city": "New York"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        #expect(modifiedJson != nil)
        #expect(modifiedJson?["name"] as? String == "Bob")
        #expect(modifiedJson?["age"] as? Int == 30)
        #expect(modifiedJson?["city"] as? String == "New York")
    }
    
    @Test
    func modifyWithNestedJSON() async throws {
        // Arrange
        let jsonString = """
        {
            "user": {
                "name": "Alice",
                "details": {
                    "city": "San Francisco",
                    "hobbies": ["reading", "swimming"]
                }
            },
            "status": "active"
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/user")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob", "city": "New York"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        let userDict = modifiedJson?["user"] as? [String: Any]
        let detailsDict = userDict?["details"] as? [String: Any]
        
        #expect(userDict?["name"] as? String == "Bob")
        #expect(detailsDict?["city"] as? String == "New York")
        #expect(modifiedJson?["status"] as? String == "active")
    }
    
    @Test
    func modifyWithArrayJSON() async throws {
        // Arrange
        let jsonString = """
        [
            {"name": "Alice", "city": "San Francisco"},
            {"name": "Charlie", "city": "Los Angeles"}
        ]
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/users")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJsonArray = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [[String: Any]]
        #expect(modifiedJsonArray != nil)
        #expect(modifiedJsonArray?.count == 2)
        #expect(modifiedJsonArray?[0]["name"] as? String == "Bob")
        #expect(modifiedJsonArray?[1]["name"] as? String == "Bob")
    }
    
    @Test
    func modifyWithNonJSONData() async throws {
        // Arrange
        let responseData = "Just a plain string, not JSON".data(using: .utf8)!
        let url = URL(string: "https://example.com/plain")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/plain"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedString = String(data: modifiedResponse.responseData, encoding: .utf8)
        #expect(modifiedString == "Just a plain string, not JSON")
    }
    
    @Test
    func modifyWithEmptyData() async throws {
        // Arrange
        let responseData = Data()
        let url = URL(string: "https://example.com/empty")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 204,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        #expect(modifiedResponse.responseData.isEmpty)
    }
    
    @Test
    func modifyWithSpecialCharactersInJSON() async throws {
        // Arrange
        let jsonString = """
        {
            "name": "Ålice",
            "city": "São Paulo",
            "emoji": "😀"
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/specialchars")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json; charset=utf-8"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bøb", "city": "München"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        #expect(modifiedJson?["name"] as? String == "Bøb")
        #expect(modifiedJson?["city"] as? String == "München")
        #expect(modifiedJson?["emoji"] as? String == "😀")
    }
    
    @Test
    func modifyWithKeyNotPresent() async throws {
        // Arrange
        let jsonString = """
        {
            "title": "Developer",
            "company": "TechCorp"
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/job")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        #expect(modifiedJson?["title"] as? String == "Developer")
        #expect(modifiedJson?["company"] as? String == "TechCorp")
        #expect(modifiedJson?["name"] == nil)
    }
    
    @Test
    func modifyWithArrayOfPrimitives() async throws {
        // Arrange
        let jsonString = """
        ["apple", "banana", "cherry"]
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/fruits")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["apple": "grape"]  // Since keys are not present, nothing should change
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedArray = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String]
        #expect(modifiedArray == ["apple", "banana", "cherry"])
    }
    
    @Test
    func modifyWithComplexNestedJSON() async throws {
        // Arrange
        let jsonString = """
        {
            "level1": {
                "level2": {
                    "level3": {
                        "name": "Alice",
                        "details": {
                            "city": "San Francisco",
                            "zip": "94105"
                        }
                    }
                }
            }
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/complex")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob", "city": "New York", "zip": "10001"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        let level1 = modifiedJson?["level1"] as? [String: Any]
        let level2 = level1?["level2"] as? [String: Any]
        let level3 = level2?["level3"] as? [String: Any]
        let details = level3?["details"] as? [String: Any]
        
        #expect(level3?["name"] as? String == "Bob")
        #expect(details?["city"] as? String == "New York")
        #expect(details?["zip"] as? String == "10001")
    }
    
    @Test
    func modifyWithMalformedJSON() async throws {
        // Arrange
        let malformedJsonString = """
        { "name": "Alice", "age": 30,  // Missing closing brace
        """
        let responseData = malformedJsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/malformed")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        #expect(modifiedResponse.responseData == response.responseData)
    }
    
    @Test
    func modifyWithJSONContainingNull() async throws {
        // Arrange
        let jsonString = """
        {
            "name": null,
            "age": 30,
            "city": "San Francisco"
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/nullname")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues = ["name": "Bob"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        #expect(modifiedJson?["name"] as? String == "Bob")
        #expect(modifiedJson?["age"] as? Int == 30)
        #expect(modifiedJson?["city"] as? String == "San Francisco")
    }
    
    @Test
    func modifyWithDifferentDataTypes() async throws {
        // Arrange
        let jsonString = """
        {
            "name": "Alice",
            "age": 30,
            "verified": true,
            "scores": [100, 95, 85]
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/userdata")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        // Intentionally replacing "age" (Int) with a String value
        let keyValues = ["name": "Bob", "age": "40"]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        #expect(modifiedJson?["name"] as? String == "Bob")
        #expect(modifiedJson?["age"] as? String == "40")
        #expect(modifiedJson?["verified"] as? Bool == true)
        #expect(modifiedJson?["scores"] as? [Int] == [100, 95, 85])
    }
    
    @Test
    func modifyWhenKeyValueIsEmpty() async throws {
        // Arrange
        let jsonString = """
        {
            "name": "Alice",
            "city": "San Francisco"
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/emptykeyvalues")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        let keyValues: [String: String] = [:]
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        #expect(modifiedResponse.responseData == response.responseData)
    }
    
    @Test
    func modifyWithNonStringValuesInKeyValues() async throws {
        // Arrange
        let jsonString = """
        {
            "name": "Alice",
            "age": 30
        }
        """
        let responseData = jsonString.data(using: .utf8)!
        let url = URL(string: "https://example.com/nonstring")!
        let httpResponse = try #require(
            HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
        )
        let response = NetworkResponse(
            url: url,
            httpURLResponse: httpResponse,
            responseData: responseData
        )
        
        // Since the ReplaceJSONValueForKeyResponseModifier expects [String: String], we cannot have non-string values in keyValues.
        // This test ensures that the code handles the replacement correctly even if types don't match.
        let keyValues = ["age": "40"]  // Replacing an Int value with a String
        
        let modifier = ReplaceJSONValueForKeyResponseModifier(keyValues: keyValues)
        
        // Act
        let modifiedResponse = try await modifier.modify(response: response)
        
        // Assert
        let modifiedJson = try JSONSerialization.jsonObject(with: modifiedResponse.responseData, options: []) as? [String: Any]
        #expect(modifiedJson?["name"] as? String == "Alice")
        #expect(modifiedJson?["age"] as? String == "40")  // The Int value should be replaced with String
    }
}
