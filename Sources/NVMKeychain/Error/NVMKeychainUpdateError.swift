//
//  NVMKeychainUpdateError.swift
//
//
//  Created by Damian Van de Kauter on 03/03/2024.
//

import Foundation

public enum NVMKeychainUpdateError: Error {
    case status(status: OSStatus)
    
    case duplicateItem
}

public extension NVMKeychainUpdateError {
    
    init(_ status: OSStatus) {
        switch status {
        case -25299:
            self = .duplicateItem
        default:
            self = .status(status: status)
        }
    }
}

extension NVMKeychainUpdateError: LocalizedError {
    var errorCode: Int {
        switch self {
        case .status:
            return 0
            
        case .duplicateItem:
            return 1
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .status(let status):
            return String(localized: "Unable to update the key. OSStatus: \(status)")
            
        case .duplicateItem:
            return String(localized: "Failed to update the key. The item already exists.")
        }
    }
}
