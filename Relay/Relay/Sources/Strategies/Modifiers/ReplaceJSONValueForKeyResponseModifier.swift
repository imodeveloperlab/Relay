//
//  ReplaceJSONValueForKeyResponseModifier.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

final class ReplaceJSONValueForKeyResponseModifier: ResponseModifier {
    
    let keyValues: [String: String]
    
    init(keyValues: [String : String]) {
        self.keyValues = keyValues
    }
    
    func modify(response: NetworkResponse) async throws -> NetworkResponse {
        guard !keyValues.isEmpty else {
            return response
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: response.responseData, options: [])
            let modifiedJsonObject = process(jsonObject: jsonObject)
            let modifiedData = try JSONSerialization.data(withJSONObject: modifiedJsonObject, options: [])
            return NetworkResponse(url: response.url, httpURLResponse: response.httpURLResponse, responseData: modifiedData)
        } catch {
            return response
        }
    }
    
    private func process(jsonObject: Any) -> Any {
        if let dictionary = jsonObject as? [String: Any] {
            var modifiedDictionary = [String: Any]()
            for (key, value) in dictionary {
                if let newValue = keyValues[key] {
                    modifiedDictionary[key] = newValue
                } else {
                    modifiedDictionary[key] = process(jsonObject: value)
                }
            }
            return modifiedDictionary
        } else if let array = jsonObject as? [Any] {
            return array.map { process(jsonObject: $0) }
        } else {
            return jsonObject
        }
    }
}

