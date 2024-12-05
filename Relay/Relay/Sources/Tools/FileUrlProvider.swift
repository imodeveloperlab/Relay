//
//  FileUrlProvider.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

// MARK: - FileUrlProvider Protocol

public protocol FileUrlProvider {
    func getFileUrl(for request: URLRequest) -> URL
}

// MARK: - Default Implementation

public final class DefaultFileUrlProvider: FileUrlProvider {
    private let fileNameResolver: RequestFileNameGenerator
    private let recordingDirectoryManager: DirectoryManager

    public init(
        fileNameResolver: RequestFileNameGenerator,
        recordingDirectoryManager: DirectoryManager
    ) {
        self.fileNameResolver = fileNameResolver
        self.recordingDirectoryManager = recordingDirectoryManager
    }

    public func getFileUrl(for request: URLRequest) -> URL {
        let fileName = fileNameResolver.generateFileName(
            for: request,
            additionalName: recordingDirectoryManager.folderName
        )
        return URL(
            fileURLWithPath: recordingDirectoryManager.directoryPath
        ).appendingPathComponent(fileName)
    }
}
