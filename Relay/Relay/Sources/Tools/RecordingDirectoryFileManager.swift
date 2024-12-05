//
//  RecordingDirectoryFileManager.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


public protocol RecordingDirectoryFileManager {
    func configure(directoryPath: String, folderName: String)
    func createDirectoryIfNeeded() throws
    func removeDirectoryIfExists() throws
    func getFileUrl(for request: URLRequest) -> URL
    func fileExists(for request: URLRequest) -> Bool
}

public final class DefaultRecordingDirectoryFileManager: RecordingDirectoryFileManager {
    
    private let recordingDirectoryManager: DirectoryManager
    public let fileUrlProvider: FileUrlProvider
    public let fileManager: FileManagerProtocol
    
    public init(
        recordingDirectoryManager: DirectoryManager = DefaultDirectoryManager(),
        fileNameResolver: RequestFileNameGenerator = DefaultRequestFileNameGenerator(),
        fileUrlProvider: FileUrlProvider? = nil,
        fileManager: FileManagerProtocol = DefaultFileManager()
    ) {
        self.recordingDirectoryManager = recordingDirectoryManager
        self.fileUrlProvider = fileUrlProvider ?? DefaultFileUrlProvider(
            fileNameResolver: fileNameResolver,
            recordingDirectoryManager: recordingDirectoryManager
        )
        self.fileManager = fileManager
    }
    
    public func configure(directoryPath: String, folderName: String) {
        recordingDirectoryManager.configure(directoryPath: directoryPath, folderName: folderName)
    }
    
    public func createDirectoryIfNeeded() throws {
        try recordingDirectoryManager.createDirectoryIfNeeded()
    }
    
    public func removeDirectoryIfExists() throws {
        try recordingDirectoryManager.removeDirectoryIfExists()
    }
    
    public func getFileUrl(for request: URLRequest) -> URL {
        fileUrlProvider.getFileUrl(for: request)
    }
    
    public func fileExists(for request: URLRequest) -> Bool {
        let fileUrl = self.getFileUrl(for: request)
        return fileManager.fileExists(atPath: fileUrl.path)
    }
}
