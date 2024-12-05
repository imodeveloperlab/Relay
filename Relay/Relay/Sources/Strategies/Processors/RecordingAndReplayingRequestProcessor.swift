//
//  RecordingAndReplayingRequestProcessor.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

public enum RecordingAndReplayingRequestProcessorError: Error, LocalizedError {
    
    case missingStrategy
    case invalidUrlInRequest(URLRequest)
    case sessionReplayNotConfigured(URLRequest)
    case noRecordFoundForRequest(URLRequest, URL)
    case failedToReplay(URL, Error)
    case failedToPerformLiveRequest(URL, Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidUrlInRequest(let request):
            return "Invalid URL in the request. Request: \(request.debugDescription)"
        case .sessionReplayNotConfigured:
            return "Session replay is not configured."
        case .noRecordFoundForRequest(let request, let fileUrl):
            return "No record was found for the request.\nRequest: \(request.debugDescription),\nRecording File URL: \(fileUrl.absoluteString)"
        case .failedToReplay(let url, let error):
            return "Failed to replay the\nURL: \(url.absoluteString).\nError: \(error.localizedDescription)"
        case .failedToPerformLiveRequest(let url, let error):
            return "Failed to perform live request for\nURL: \(url.absoluteString).\nError: \(error.localizedDescription)"
        case .missingStrategy:
            return "Missing strategy"
        }
    }
}

public final class RecordingAndReplayingRequestProcessor: RequestProcessor {
    
    let liveRequestPerformer = DefaultLiveRequestPerformer()
    let dataTaskSerializer = DefaultHTTPDataTaskSerializer()
    let recordingDirectoryFileManager = DefaultRecordingDirectoryFileManager()
    
    lazy var responseRecorder = DefaultResponseRecorder(
        dataTaskSerializer: dataTaskSerializer,
        recordingDirectoryFileManager: recordingDirectoryFileManager
    )
    
    lazy var responseReplayer = DefaultResponseReplayer(
        dataTaskSerializer: dataTaskSerializer,
        recordingDirectoryFileManager: recordingDirectoryFileManager
    )
    
    // MARK: - Start/Stop Replay

    private var isRecordingEnabled: Bool = false
    
    public init(
        directoryPath: String,
        sessionFolderName: String,
        isRecordingEnabled: Bool = false
    ) {
        self.responseRecorder.configure(directoryPath: directoryPath, sessionFolderName: sessionFolderName)
        self.responseReplayer.configure(directoryPath: directoryPath, sessionFolderName: sessionFolderName)
        self.isRecordingEnabled = isRecordingEnabled
    }
    
    public func removeRecordingSessionFolder() throws {
        try self.responseRecorder.removeRecordingSessionFolder()
    }
    
    public func process(request: URLRequest) async throws -> NetworkResponse {
        guard let url = request.url else {
            throw Logger.logAndReturn(error: RecordingAndReplayingRequestProcessorError.invalidUrlInRequest(request))
        }
        
        Logger.log("Start loading for URL", info: ["URL": url.absoluteString])
        
        var newRequest = request
        newRequest.setValue("true", forHTTPHeaderField: "X-RelayReplay")
        
        if shouldReplay(newRequest: newRequest) {
            return try await replayRecordedRequest(newRequest: newRequest, url: url)
        } else if isRecordingEnabled {
            return try await performRequestAndRecord(request: newRequest, url: url)
        } else {
            throw Logger.logAndReturn(
                error: RecordingAndReplayingRequestProcessorError.noRecordFoundForRequest(
                    newRequest,
                    recordingDirectoryFileManager.getFileUrl(for: newRequest)
                )
            )
        }
    }
    
    // MARK: - Helper Methods

    private func shouldReplay(newRequest: URLRequest) -> Bool {
        return responseReplayer.doesRecordingExist(for: newRequest) && !isRecordingEnabled
    }

    private func replayRecordedRequest(newRequest: URLRequest, url: URL) async throws -> NetworkResponse {
        do {
            let result = try responseReplayer.replay(for: newRequest)
            return NetworkResponse(
                url: url,
                httpURLResponse: result.reponse,
                responseData: result.data
            )
        } catch {
            throw Logger.logAndReturn(
                error: RecordingAndReplayingRequestProcessorError.failedToReplay(url, error)
            )
        }
    }
    
    private func performRequestAndRecord(request: URLRequest, url: URL) async throws -> NetworkResponse {
        
        let (data, response) = try await liveRequestPerformer.performRequest(request)
        try responseRecorder.record(data: data, response: response, for: request)
        let (replayData, replayResponse) = try responseReplayer.replay(for: request)
        
        return NetworkResponse(
            url: url,
            httpURLResponse: replayResponse,
            responseData: replayData
        )
    }
}


