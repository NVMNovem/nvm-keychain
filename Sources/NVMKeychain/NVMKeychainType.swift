//
//  NVMKeychainType.swift
//
//
//  Created by Damian Van de Kauter on 02/03/2024.
//

import Foundation

public enum NVMKeychainType {
    
    case credentials(username: String, server: String? = nil)
    case password
    case key
}

internal extension NVMKeychainType {
    
    var cfString: CFString {
        switch self {
        case .credentials:
            return kSecClassInternetPassword
        case .password:
            return kSecClassGenericPassword
        case .key:
            return kSecClassKey
        }
    }
}

internal extension NVMKeychainType {
    
    func createAddQuery(for tag: String, key: Data) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try self.getTagIdentifier(tag: tag)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        var mutableQuery: NVMKeychain.ItemDictionary = [
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: key
        ]
            .setClass(self)
            .setServer(self)
            .setAccount(self)
        
        return mutableQuery
    }
    
    func createGetQuery(for tag: String) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try self.getTagIdentifier(tag: tag)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        var mutableQuery: NVMKeychain.ItemDictionary = [
            kSecAttrApplicationTag as String: tag,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
            .setClass(self)
            .setServer(self)
            .setAccount(self)
        
        return mutableQuery
    }
    
    private func getTagIdentifier(tag: String) throws -> String {
        let bundleID = Bundle.main.bundleIdentifier
        guard let bundleID else { throw NVMKeychainError.invalidBundleID(bundleID) }
        
        return "\(bundleID).keys.\(tag)"
    }
}

extension NVMKeychain.ItemDictionary {
    
    fileprivate func setClass(_ type: NVMKeychainType) -> Self {
        let cfClass = type.cfString
        
        var mutableDictionary = self
        mutableDictionary.updateValue(cfClass, forKey: kSecClass as String)
        
        return mutableDictionary
    }
    
    fileprivate func setAccount(_ type: NVMKeychainType) -> Self {
        switch type {
        case .credentials(let username, _):
            var mutableDictionary = self
            mutableDictionary.updateValue(username, forKey: kSecAttrAccount as String)
            
            return mutableDictionary
        default:
            return self
        }
    }
    
    fileprivate func setServer(_ type: NVMKeychainType) -> Self {
        switch type {
        case .credentials(_, let server):
            guard let server else { return self }
            
            var mutableDictionary = self
            mutableDictionary.updateValue(server, forKey: kSecAttrServer as String)
            
            return mutableDictionary
        default:
            return self
        }
    }
}
