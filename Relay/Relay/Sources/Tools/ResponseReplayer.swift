//
//  ResponseReplayer.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

public enum ResponseReplayerError: Error, LocalizedError {
    case invalidRecordedResponseData(URLRequest)
    public var errorDescription: String? {
        switch self {
        case .invalidRecordedResponseData(let request):
            return "Invalid recorded data for request:\n\(request.debugDescription)"
        }
    }
}

// MARK: - Response Replayer Protocol

public protocol ResponseReplayer {
    func replay(for request: URLRequest) throws -> (data: Data, reponse: HTTPURLResponse)
    func doesRecordingExist(for request: URLRequest) -> Bool
    func configure(directoryPath: String, sessionFolderName: String)
}

// MARK: - Default Implementation

public final class DefaultResponseReplayer: ResponseReplayer {
    
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
    
    public func replay(for request: URLRequest) throws -> (data: Data, reponse: HTTPURLResponse) {
        let fileUrl = recordingDirectoryFileManager.getFileUrl(for: request)
        let recordedData = try Data(contentsOf: fileUrl)
        
        guard let result = try? dataTaskSerializer.decode(request: request, data: recordedData) else {
            Logger.log(
                "Failed to parse recorded data",
                type: .error,
                info: ["URL": request.url?.absoluteString ?? "Missing URL"]
            )
            throw Logger.logAndReturn(error: ResponseReplayerError.invalidRecordedResponseData(request))
        }
        
        return (data: result.responseData, reponse: result.httpURLResponse)
    }
    
    public func doesRecordingExist(for request: URLRequest) -> Bool {
        recordingDirectoryFileManager.fileExists(for: request)
    }
}
