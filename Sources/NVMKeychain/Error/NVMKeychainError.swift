//
//  NVMKeychainError.swift
//
//
//  Created by Damian Van de Kauter on 02/03/2024.
//

import Foundation

enum NVMKeychainError: Error {
    case storeFailed(NVMKeychainStoreError)
    case retrieveFailed(NVMKeychainRetrieveError)
    
    case notFound
    
    case invalidBundleID(String?)
    case invalidKeychainType
    case invalidPasswordData
    case tagFailed
}

extension NVMKeychainError: LocalizedError {
    var errorCode: Int {
        switch self {
        case .storeFailed:
            return 1
        case .retrieveFailed:
            return 2
            
        case .notFound:
            return 3
            
        case .invalidBundleID:
            return 4
        case .invalidKeychainType:
            return 5
        case .invalidPasswordData:
            return 6
        case .tagFailed:
            return 7
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let nvmKeychainStoreError):
            return nvmKeychainStoreError.localizedDescription
        case .retrieveFailed(let nvmKeychainRetrieveError):
            return nvmKeychainRetrieveError.localizedDescription
            
        case .notFound:
            return String(localized: "Item not found in the keychain.")
            
        case .invalidBundleID(let bundleID):
            return String(localized: "The Bundle ID \"\(bundleID ?? "")\" is not a valid Bundle Identifier.")
        case .invalidKeychainType:
            return String(localized: "Unable to get a correct Keychain Type.")
        case .invalidPasswordData:
            return String(localized: "Unable to get data from the Password.")
        case .tagFailed:
            return String(localized: "Unable to create the tag.")
        }
    }
}
