//
//  String+Conveniences.swift
//  SwiftNetworkReplay
//
//  Created by Ivan Borinschi on 01.12.2024.
//

import Foundation

extension String {
    func addUnderlyingError(_ error: Error?) -> String {
        if let error {
            return self + "\nUnderlyingError: \(error.localizedDescription)"
        }
        return self
    }
}
