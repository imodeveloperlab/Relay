//
//  URLSessionConfigurationInterceptor.swift
//  SwiftNetworkReplayExplorer
//
//  Created by Ivan Borinschi on 01.12.2024.
//


class URLSessionConfigurationInterceptor {
    static let shared = URLSessionConfigurationInterceptor()
    private var isInstalled = false

    func setup() {
        guard !isInstalled else { return }
        isInstalled = true

        swizzleSessionConfigurations()
    }

    private func swizzleSessionConfigurations() {
        let cls: AnyClass = URLSessionConfiguration.self

        // Swizzle defaultSessionConfiguration
        if let originalMethod = class_getClassMethod(cls, #selector(getter: URLSessionConfiguration.default)),
           let swizzledMethod = class_getClassMethod(cls, #selector(URLSessionConfiguration.swizzled_default)) {

            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        // Swizzle ephemeralSessionConfiguration
        if let originalMethod = class_getClassMethod(cls, #selector(getter: URLSessionConfiguration.ephemeral)),
           let swizzledMethod = class_getClassMethod(cls, #selector(URLSessionConfiguration.swizzled_ephemeral)) {

            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension URLSessionConfiguration {

    @objc class func swizzled_default() -> URLSessionConfiguration {
        // This actually calls the original default method due to method swizzling
        let configuration = swizzled_default()

        // Add custom protocol
        if let protocols = configuration.protocolClasses, !protocols.contains(where: { $0 == RelayURLProtocol.self }) {
            configuration.protocolClasses?.insert(RelayURLProtocol.self, at: 0)
        } else {
            configuration.protocolClasses = [RelayURLProtocol.self]
        }

        return configuration
    }

    @objc class func swizzled_ephemeral() -> URLSessionConfiguration {
        // This actually calls the original ephemeral method due to method swizzling
        let configuration = swizzled_ephemeral()

        // Add custom protocol
        if let protocols = configuration.protocolClasses, !protocols.contains(where: { $0 == RelayURLProtocol.self }) {
            configuration.protocolClasses?.insert(RelayURLProtocol.self, at: 0)
        } else {
            configuration.protocolClasses = [RelayURLProtocol.self]
        }

        return configuration
    }
}
