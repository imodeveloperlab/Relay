//
//  Relay.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

/// A class responsible for handling network request recording, replaying, interception, and modification.
public final class Relay {

    // MARK: - Sugar Methods

    /// Starts recording and replaying network requests with convenience parameters.
    ///
    /// - Parameters:
    ///   - recordingRootFolder: The root directory path for storing recordings.
    ///   - recordingFolder: The subdirectory for the current session's recordings.
    ///   - isRecordingEnabled: A flag indicating whether recording is enabled.
    ///   - urlKeywords: A list of keywords to filter URLs for interception.
    ///   - jsonValueOverrides: A dictionary of JSON keys and their replacement values in responses.
    /// - Returns: A `RecordingAndReplayingRequestProcessor` instance for handling requests.
    @discardableResult
    public static func recordAndReplay(
        recordingRootFolder: String = #file,
        recordingFolder: String = #function,
        isRecordingEnabled: Bool = false,
        urlKeywords: [String] = [],
        jsonValueOverrides: [String: String] = [:]
    ) -> RecordingAndReplayingRequestProcessor {

        let recordingConfig = RecordingConfig(
            rootPath: recordingRootFolder,
            subfolder: recordingFolder,
            enableRecording: isRecordingEnabled
        )

        let interceptionConfig = InterceptionConfig(
            urlKeywords: urlKeywords,
            jsonValueOverrides: jsonValueOverrides
        )

        return Relay.startRecordingAndReplaying(
            recordingConfig: recordingConfig,
            interceptionConfig: interceptionConfig
        )
    }

    /// Starts intercepting and modifying network requests with convenience parameters.
    ///
    /// - Parameters:
    ///   - requestProcessor: The request processor to handle requests.
    ///   - urlKeywords: A list of keywords to filter URLs for interception.
    ///   - jsonValueOverrides: A dictionary of JSON keys and their replacement values in responses.
    public static func interceptAndModify(
        requestProcessor: RequestProcessor = LiveRequestAndReplayRequestProcessor(),
        urlKeywords: [String] = [],
        jsonValueOverrides: [String: String] = [:]
    ) {
        let interceptionConfig = InterceptionConfig(
            urlKeywords: urlKeywords,
            jsonValueOverrides: jsonValueOverrides
        )

        Relay.startInterceptingAndModifying(
            requestProcessor: requestProcessor,
            interceptionConfig: interceptionConfig
        )
    }

    // MARK: - Core Methods

    /// Starts recording and replaying network requests.
    ///
    /// - Parameters:
    ///   - recordingConfig: Configuration for recording requests.
    ///   - interceptionConfig: Configuration for intercepting and modifying requests.
    /// - Returns: A `RecordingAndReplayingRequestProcessor` instance for handling requests.
    @discardableResult
    public static func startRecordingAndReplaying(
        recordingConfig: RecordingConfig = RecordingConfig(
            rootPath: #file,
            subfolder: #function,
            enableRecording: false
        ),
        interceptionConfig: InterceptionConfig = InterceptionConfig(
            urlKeywords: [],
            jsonValueOverrides: [:]
        )
    ) -> RecordingAndReplayingRequestProcessor {

        let requestProcessor = RecordingAndReplayingRequestProcessor(
            directoryPath: recordingConfig.rootPath,
            sessionFolderName: recordingConfig.subfolder,
            isRecordingEnabled: recordingConfig.enableRecording
        )

        Relay.startInterceptingAndModifying(
            requestProcessor: requestProcessor,
            interceptionConfig: interceptionConfig
        )

        return requestProcessor
    }

    /// Starts intercepting and modifying network requests.
    ///
    /// - Parameters:
    ///   - requestProcessor: The request processor to handle requests.
    ///   - interceptionConfig: Configuration for intercepting and modifying requests.
    public static func startInterceptingAndModifying(
        requestProcessor: RequestProcessor = LiveRequestAndReplayRequestProcessor(),
        interceptionConfig: InterceptionConfig = InterceptionConfig(
            urlKeywords: [],
            jsonValueOverrides: [:]
        )
    ) {
        let httpRequestFilter = HTTPRequestFilter()

        let keywordRequestFilter = KeywordRequestFilter(
            urlKeywordsForReplay: interceptionConfig.urlKeywords
        )

        let replaceValueForKeyResponseModifier = ReplaceJSONValueForKeyResponseModifier(
            keyValues: interceptionConfig.jsonValueOverrides
        )

        RelayURLProtocol.start(
            filter: [httpRequestFilter, keywordRequestFilter],
            request: [requestProcessor],
            modify: [replaceValueForKeyResponseModifier]
        )
    }
}
