//
//  NVMKeychainType.swift
//
//
//  Created by Damian Van de Kauter on 02/03/2024.
//

import Foundation

public enum NVMKeychainType {
    
    case internetCredentials(username: String, server: String?)
    case credentials(username: String, server: String? = nil)
    case key
}

internal extension NVMKeychainType {
    
    var cfString: CFString {
        switch self {
        case .internetCredentials:
            return kSecClassInternetPassword
        case .credentials:
            return kSecClassGenericPassword
        case .key:
            return kSecClassKey
        }
    }
    
    var attributes: [CFString] {
        var mutableAttributes: [CFString] = [
            kSecAttrAccess,
            kSecAttrAccessControl,
            kSecAttrAccessible,
            kSecAttrAccessGroup,
            kSecAttrSynchronizable,
            kSecAttrCreationDate,
            kSecAttrModificationDate,
            kSecAttrDescription,
            kSecAttrComment,
            kSecAttrCreator,
            kSecAttrType,
            kSecAttrLabel,
            kSecAttrIsInvisible,
            kSecAttrIsNegative,
            kSecAttrSyncViewHint,
            kSecAttrPersistantReference,
        ]
        #if os(tvOS)
        mutableAttributes.append(kSecUseUserIndependentKeychain)
        #endif
        
        switch self {
        case .internetCredentials:
            mutableAttributes.append(contentsOf: [
                kSecAttrAccount,
                kSecAttrService,
                kSecAttrGeneric,
                kSecAttrSecurityDomain,
                kSecAttrServer,
                kSecAttrProtocol,
                kSecAttrAuthenticationType,
                kSecAttrPort,
                kSecAttrPath
            ])
        case .credentials:
            mutableAttributes.append(contentsOf: [
                kSecAttrAccount,
                kSecAttrService,
                kSecAttrGeneric,
                kSecAttrSecurityDomain,
                kSecAttrServer,
                kSecAttrProtocol,
                kSecAttrAuthenticationType,
                kSecAttrPort,
                kSecAttrPath
            ])
        case .key:
            mutableAttributes.append(contentsOf: [
                kSecAttrKeyClass,
                kSecAttrApplicationLabel,
                kSecAttrApplicationTag,
                kSecAttrKeyType,
                kSecAttrPRF,
                kSecAttrSalt,
                kSecAttrRounds,
                kSecAttrKeySizeInBits,
                kSecAttrEffectiveKeySize,
                kSecAttrTokenID,
                
                kSecAttrIsPermanent,
                kSecAttrIsSensitive,
                kSecAttrIsExtractable,
                kSecAttrCanEncrypt,
                kSecAttrCanDecrypt,
                kSecAttrCanDerive,
                kSecAttrCanSign,
                kSecAttrCanVerify,
                kSecAttrCanWrap,
                kSecAttrCanUnwrap
            ])
        }
        
        return mutableAttributes
    }
}

internal extension NVMKeychainType {
    
    func createAddQuery(for tag: String, accessControl: NVMKeychain.AccessControl?, key: Data) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try self.getTagIdentifier(tag: tag)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        let mutableQuery: NVMKeychain.ItemDictionary = [
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: key
        ]
            .setAccessControl(accessControl)
            .setClass(self)
            .setServer(self)
            .setAccount(self)
        
        return mutableQuery
    }
    
    func createGetQuery(for tag: String, accessControl: NVMKeychain.AccessControl?) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try self.getTagIdentifier(tag: tag)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        let mutableQuery: NVMKeychain.ItemDictionary = [
            kSecAttrApplicationTag as String: tag,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
            .setAccessControl(accessControl)
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
    
    fileprivate func setAccessControl(_ accessControl: NVMKeychain.AccessControl?) -> Self {
        guard let cfAccessControl = accessControl?.cfString else { return self }
        
        var mutableDictionary = self
        mutableDictionary.updateValue(cfAccessControl, forKey: kSecAttrAccessible as String)
        
        return mutableDictionary
    }
    
    fileprivate func setClass(_ type: NVMKeychainType) -> Self {
        let cfClass = type.cfString
        
        var mutableDictionary = self
        mutableDictionary.updateValue(cfClass, forKey: kSecClass as String)
        
        return mutableDictionary
    }
    
    fileprivate func setAccount(_ type: NVMKeychainType) -> Self {
        switch type {
        case .internetCredentials(let username, _):
            return self.addString(username, forKey: kSecAttrAccount)
        case .credentials(let username, _):
            return self.addString(username, forKey: kSecAttrAccount)
        default:
            return self
        }
    }
    
    fileprivate func setServer(_ type: NVMKeychainType) -> Self {
        switch type {
        case .internetCredentials(_, let server):
            return self.addString(server, forKey: kSecAttrServer)
        case .credentials(_, let server):
            return self.addString(server, forKey: kSecAttrServer)
        default:
            return self
        }
    }
    
    private func addString(_ value: String?, forKey key: CFString) -> Self {
        guard let value else { return self }
        
        var mutableDictionary = self
        mutableDictionary.updateValue(value, forKey: key as String)
        
        return mutableDictionary
    }
}
