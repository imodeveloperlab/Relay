//
//  RecordingDirectoryPathResolver.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

public enum DirectoryManagerError: Error, LocalizedError {
    case directoryCreationFailed(String, Error?)
    case directoryRemovalFailed(String, Error?)
    
    public var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let path, let underlyingError):
            return "Failed to create directory at path: \(path)".addUnderlyingError(underlyingError)
        case .directoryRemovalFailed(let path, let underlyingError):
            return "Failed to remove directory at path: \(path)".addUnderlyingError(underlyingError)
        }
    }
}

public protocol DirectoryManager {
    
    func configure(directoryPath: String, folderName: String)
    func createDirectoryIfNeeded() throws
    func removeDirectoryIfExists() throws
    func reset()
    
    var directoryPath: String { get }
    var folderName: String { get }
}

public final class DefaultDirectoryManager: DirectoryManager {
    
    private var _directoryPath: String = ""
    private var _folderName: String = ""
    
    public init() {}
    
    var fileManager: FileManagerProtocol = DefaultFileManager()
        
    public func reset() {
        _directoryPath = ""
        _folderName = ""
    }
    
    public func configure(directoryPath: String, folderName: String) {
        _folderName = folderName.replacingOccurrences(of: "()", with: "")
        let directoryUrl = URL(fileURLWithPath: directoryPath, isDirectory: false)
        let finalDirectoryUrl = directoryUrl.deletingLastPathComponent()
            .appendingPathComponent("__RelayRecords__")
            .appendingPathComponent(_folderName)
        _directoryPath = finalDirectoryUrl.path
    }
    
    public var directoryPath: String {
        return _directoryPath
    }
    
    public var folderName: String {
        return _folderName
    }
    
    public func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: directoryPath) {
            do {
                try fileManager.createDirectory(
                    atPath: directoryPath,
                    attributes: nil
                )
                Logger.log(
                    "Successfully created directory",
                    info: ["Path": directoryPath]
                )
            } catch {
                throw Logger.logAndReturn(
                    error: DirectoryManagerError.directoryCreationFailed(directoryPath, error)
                )
            }
        }
    }
    
    public func removeDirectoryIfExists() throws {
        if fileManager.fileExists(atPath: directoryPath) {
            do {
                try fileManager.removeItem(atPath: directoryPath)
                Logger.log(
                    "Successfully removed directory",
                    info: ["Path": directoryPath]
                )
            } catch {
                throw Logger.logAndReturn(
                    error: DirectoryManagerError.directoryRemovalFailed(directoryPath, error)
                )
            }
        } else {
            Logger.log(
                "No directory exists at path", info: ["Path": directoryPath]
            )
        }
    }
}
