//
//  Logger.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


import Foundation
import os.log

public struct Logger {
    // Default logger is public so it can be used as a fallback
    public static let defaultLogger = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "SwiftNetworkReplayLogger",
        category: "SwiftNetworkReplay"
    )
    
    public static func log(
        _ message: String,
        type: OSLogType = .info,
        info: [String: Any] = [:],
        logger: OSLog? = nil
    ) {
        // Use the provided logger or fallback to the default one
        let activeLogger = logger ?? defaultLogger
        
        var formattedMessage = "[SwiftNetworkReplay] \(message)"
        info.forEach { key, value in
            formattedMessage += "\n\(key): \(value)"
        }
        os_log("%{public}@", log: activeLogger, type: type, formattedMessage)
    }
    
    public static func logAndReturn(error: Error) -> Error {
        Self.log("\(type(of: error))\(Self.getCaseName(of: error)) \n\(error.localizedDescription)", type: .error)
        return error
    }
    
    private static func getCaseName(of error: Error) -> String {
        let mirror = Mirror(reflecting: error)
        if let label = mirror.children.first?.label {
            return "." + label
        }
        return ""
    }
}
