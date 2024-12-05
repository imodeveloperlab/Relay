//
//  HTTPDataTaskSerializer.swift
//  SwiftNetworkReplay
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public enum HTTPDataTaskSerializerError: Error, LocalizedError {
    case invalidUrlInTheRequest(URLRequest)
    case failedToDeserializeJSONData(URLRequest, Data)
    case responseDataIsMissingOrCorrupted(URLRequest)
    case responseHeadersMissingOrInvalid(URLRequest)
    case statusCodeMissingOrInvalid(URLRequest)
    case failedToCreateHTTPURLResponse(URLRequest)
    
    public var errorDescription: String? {
        switch self {
        case .invalidUrlInTheRequest(let urlRequest):
            return "Invalid URL in the request, \nRequest:\(urlRequest.debugDescription)"
        case .failedToDeserializeJSONData(let urlRequest, let data):
            return "Failed to deserialize JSON data, \nRequest:\(urlRequest.debugDescription)\n\(data.debugDescription)"
        case .responseDataIsMissingOrCorrupted(let urlRequest):
            return "Response data is missing or corrupted, \nRequest:\(urlRequest.debugDescription)"
        case .responseHeadersMissingOrInvalid(let urlRequest):
            return "Response headers are missing or invalid, \nRequest:\(urlRequest.debugDescription)"
        case .statusCodeMissingOrInvalid(let urlRequest):
            return "Status code is missing or invalid, \nRequest:\(urlRequest.debugDescription)"
        case .failedToCreateHTTPURLResponse(let urlRequest):
            return "Failed to create HTTPURLResponse, \nRequest:\(urlRequest.debugDescription)"
        }
    }
}

public protocol HTTPDataTaskSerializer {
    func encode(request: URLRequest, responseData: Data, httpResponse: HTTPURLResponse) throws -> Data
    func decode(request: URLRequest, data: Data) throws -> (httpURLResponse: HTTPURLResponse, responseData: Data)
}

public final class DefaultHTTPDataTaskSerializer: HTTPDataTaskSerializer {
    
    public init() {}
    
    public func encode(request: URLRequest, responseData: Data, httpResponse: HTTPURLResponse) throws -> Data {

        let responseHeaders = convertHeadersToStringDict(httpResponse.allHeaderFields)
        let requestHeaders = request.allHTTPHeaderFields ?? [:]

        let requestContentType = request.value(forHTTPHeaderField: "Content-Type")
        let responseContentType = httpResponse.value(forHTTPHeaderField: "Content-Type")

        let (requestBodyString, isRequestBodyBase64Encoded) = encodeDataToString(request.httpBody, contentType: requestContentType)
        let (responseDataString, isResponseDataBase64Encoded) = encodeDataToString(responseData, contentType: responseContentType)

        let responseObject: [String: Any] = [
            "service": request.url?.absoluteString ?? "unknown_service",
            "requestType": request.httpMethod ?? "GET",
            "requestHeaders": requestHeaders,
            "requestBody": [
                "data": requestBodyString,
                "isBase64Encoded": isRequestBodyBase64Encoded
            ],
            "responseHeaders": responseHeaders,
            "statusCode": httpResponse.statusCode,
            "responseData": [
                "data": responseDataString,
                "isBase64Encoded": isResponseDataBase64Encoded
            ]
        ]

        return try JSONSerialization.data(withJSONObject: responseObject, options: .prettyPrinted)
    }
    
    public func decode(request: URLRequest, data: Data) throws -> (httpURLResponse: HTTPURLResponse, responseData: Data) {
        
        guard let url = request.url else {
            throw Logger.logAndReturn(
                error: HTTPDataTaskSerializerError.invalidUrlInTheRequest(request)
            )
        }
        
        guard let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Logger.logAndReturn(
                error: HTTPDataTaskSerializerError.failedToDeserializeJSONData(request, data)
            )
        }

        guard let responseDataDict = responseObject["responseData"] as? [String: Any],
              let responseDataString = responseDataDict["data"] as? String,
              let isResponseDataBase64Encoded = responseDataDict["isBase64Encoded"] as? Bool,
              let responseData = decodeStringToData(responseDataString, isBase64Encoded: isResponseDataBase64Encoded) else {
            throw Logger.logAndReturn(
                error: HTTPDataTaskSerializerError.responseDataIsMissingOrCorrupted(request)
            )
        }

        guard let responseHeadersAny = responseObject["responseHeaders"] as? [String: Any] else {
            throw Logger.logAndReturn(
                error: HTTPDataTaskSerializerError.responseHeadersMissingOrInvalid(request)
            )
        }
        var responseHeaders = convertHeadersToStringDict(responseHeadersAny)
        responseHeaders["X-RelayReplay"] = "true"
        
        guard let statusCode = responseObject["statusCode"] as? Int else {
            throw Logger.logAndReturn(
                error: HTTPDataTaskSerializerError.statusCodeMissingOrInvalid(request)
            )
        }
        
        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: responseHeaders) else {
            throw Logger.logAndReturn(
                error: HTTPDataTaskSerializerError.failedToCreateHTTPURLResponse(request)
            )
        }
        
        return (httpURLResponse: response, responseData: responseData)
    }
    
    private func convertHeadersToStringDict(_ headers: [AnyHashable: Any]) -> [String: String] {
        var stringHeaders: [String: String] = [:]
        for (key, value) in headers {
            if let keyString = key as? String {
                stringHeaders[keyString] = "\(value)"
            }
        }
        return stringHeaders
    }

    private func encodeDataToString(_ data: Data?, contentType: String?) -> (dataString: String, isBase64Encoded: Bool) {
        guard let data = data else {
            return ("", false)
        }

        if let contentType = contentType, isTextContentType(contentType) {
            let encoding = contentTypeCharset(contentType) ?? .utf8
            if let string = String(data: data, encoding: encoding) {
                return (string, false)
            }
        }

        return (data.base64EncodedString(), true)
    }
    
    private func isTextContentType(_ contentType: String) -> Bool {
        if contentType.lowercased().hasPrefix("text/") {
            return true
        }

        let textTypes: Set<String> = [
            "application/json",
            "application/xml",
            "application/javascript",
            "application/xhtml+xml",
            "application/x-www-form-urlencoded"
        ]

        let mimeType = contentType.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return textTypes.contains(mimeType)
    }

    private func contentTypeCharset(_ contentType: String) -> String.Encoding? {
        let parameters = contentType.components(separatedBy: ";").dropFirst()
        for parameter in parameters {
            let keyValue = parameter.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "=")
            if keyValue.count == 2, keyValue[0].lowercased() == "charset" {
                let charset = keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return stringEncoding(forCharset: charset)
            }
        }
        return .utf8
    }

    private func stringEncoding(forCharset charset: String) -> String.Encoding? {
        switch charset {
        case "utf-8":
            return .utf8
        case "utf-16":
            return .utf16
        case "iso-8859-1", "latin1":
            return .isoLatin1
        default:
            return nil
        }
    }

    private func decodeStringToData(_ string: String, isBase64Encoded: Bool) -> Data? {
        if isBase64Encoded {
            return Data(base64Encoded: string)
        } else {
            return string.data(using: .utf8)
        }
    }
}

