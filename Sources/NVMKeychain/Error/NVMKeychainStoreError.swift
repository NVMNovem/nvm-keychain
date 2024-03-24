//
//  NVMKeychainStoreError.swift
//  
//
//  Created by Damian Van de Kauter on 03/03/2024.
//

import Foundation

public enum NVMKeychainStoreError: Error {
    case status(status: OSStatus)
    
    case duplicateItem
}

public extension NVMKeychainStoreError {
    
    init(_ status: OSStatus) {
        switch status {
        case -25299:
            self = .duplicateItem
        default:
            self = .status(status: status)
        }
    }
}

extension NVMKeychainStoreError: LocalizedError {
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
            return String(localized: "Unable to store the key. OSStatus: \(status)")
            
        case .duplicateItem:
            return String(localized: "Failed to store the key. The item already exists.")
        }
    }
}
