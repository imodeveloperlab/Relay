//
//  RecordingConfig.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

/// Configuration for recording network requests.
public struct RecordingConfig {
    /// The root directory path for storing recordings.
    let rootPath: String
    /// The subdirectory for the current session's recordings.
    let subfolder: String
    /// A flag indicating whether recording is enabled.
    let enableRecording: Bool

    /// Initializes a new instance of `RecordingConfig`.
    ///
    /// - Parameters:
    ///   - rootPath: The root directory path for storing recordings.
    ///   - subfolder: The subdirectory for the current session's recordings.
    ///   - enableRecording: A flag indicating whether recording is enabled.
    public init(rootPath: String, subfolder: String, enableRecording: Bool) {
        self.rootPath = rootPath
        self.subfolder = subfolder
        self.enableRecording = enableRecording
    }
}
