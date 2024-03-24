//
//  NVMKeychainRetrieveError.swift
//
//
//  Created by Damian Van de Kauter on 03/03/2024.
//

import Foundation

public enum NVMKeychainRetrieveError: Error {
    case status(status: OSStatus)
}

public extension NVMKeychainRetrieveError {
    
    init(_ status: OSStatus) {
        switch status {
        default:
            self = .status(status: status)
        }
    }
}

extension NVMKeychainRetrieveError: LocalizedError {
    var errorCode: Int {
        switch self {
        case .status:
            return 0
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .status(let status):
            return String(localized: "Unable to retrieve the key. OSStatus: \(status)")
        }
    }
}
