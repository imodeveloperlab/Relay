//
//  FileManagerProtocol.swift
//  SwiftNetworkReplay
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public protocol FileManagerProtocol {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(atPath path: String, attributes: [FileAttributeKey : Any]?) throws
    func removeItem(atPath path: String) throws
}

public final class DefaultFileManager: FileManagerProtocol {
    
    public init() {}
    
    let fileManager: FileManager = .default
    
    public func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    public func createDirectory(atPath path: String, attributes: [FileAttributeKey : Any]?) throws {
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: attributes)
    }
    
    public func removeItem(atPath path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
}
