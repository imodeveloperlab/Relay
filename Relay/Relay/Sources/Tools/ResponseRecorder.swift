//
//  ResponseRecorder.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

// MARK: - Response Recorder Protocol

public protocol ResponseRecorder {
    func configure(directoryPath: String, sessionFolderName: String)
    func record(data: Data, response: HTTPURLResponse, for request: URLRequest) throws
    func removeRecordingSessionFolder() throws
}

// MARK: - Default Implementation

public final class DefaultResponseRecorder: ResponseRecorder {
    
    private let dataTaskSerializer: HTTPDataTaskSerializer
    private let recordingDirectoryFileManager: RecordingDirectoryFileManager

    public init(
        dataTaskSerializer: HTTPDataTaskSerializer,
        recordingDirectoryFileManager: RecordingDirectoryFileManager
    ) {
        self.dataTaskSerializer = dataTaskSerializer
        self.recordingDirectoryFileManager = recordingDirectoryFileManager
    }

    public func configure(directoryPath: String, sessionFolderName: String) {
        recordingDirectoryFileManager.configure(
            directoryPath: directoryPath,
            folderName: sessionFolderName
        )
    }

    public func record(data: Data, response: HTTPURLResponse, for request: URLRequest) throws {
        
        try recordingDirectoryFileManager.createDirectoryIfNeeded()

        let recordedResponseData = try dataTaskSerializer.encode(
            request: request,
            responseData: data,
            httpResponse: response
        )

        let fileUrl = recordingDirectoryFileManager.getFileUrl(for: request)
        try recordedResponseData.write(to: fileUrl, options: .atomic)

        Logger.log(
            "Successfully recorded response for URL",
            info: ["URL": request.url?.absoluteString ?? "Unknown URL", "File Path": fileUrl.absoluteString]
        )
    }

    public func removeRecordingSessionFolder() throws {
        try recordingDirectoryFileManager.removeDirectoryIfExists()
    }
}

