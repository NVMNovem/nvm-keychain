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
    
    var username: String? {
        switch self {
        case .internetCredentials(let username, _):
            return username
        case .credentials(let username, _):
            return username
        case .key:
            return nil
        }
    }
    
    var server: String? {
        switch self {
        case .internetCredentials(_, let server):
            return server
        case .credentials(_, let server):
            return server
        case .key:
            return nil
        }
    }
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
    
    func createAddQuery(for tag: String, settings: NVMKeychainSettings, key: Data) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try Self.getTagIdentifier(tag: tag)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        let mutableQuery: NVMKeychain.ItemDictionary = [
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: key
        ]
            .setName(settings.label)
            .setAccessControl(settings.accessControl)
            .setSynchronizable(settings)
            .setInvisible(settings)
            .setClass(self)
            .setServer(self.server)
            .setAccount(self.username)
        
        return mutableQuery
    }
    
    func createGetQuery(for tag: String, settings: NVMKeychainSettings) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try Self.getTagIdentifier(tag: tag)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        let mutableQuery: NVMKeychain.ItemDictionary = [
            kSecAttrApplicationTag as String: tag,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
            .setName(settings.label)
            .setAccessControl(settings.accessControl)
            .setSynchronizable(settings)
            .setInvisible(settings)
            .setClass(self)
            .setServer(self.server)
            .setAccount(self.username)
        
        return mutableQuery
    }
    
    static func createGetAllQuery(settings: NVMKeychainSettings, type: Self) throws -> NVMKeychain.ItemDictionary {
        let mutableQuery: NVMKeychain.ItemDictionary = [
            kSecReturnAttributes as String: true,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
            .setName(settings.label)
            .setClass(type)
        
        return mutableQuery
    }
    
    private static func getTagIdentifier(tag: String) throws -> String {
        let bundleID = Bundle.main.bundleIdentifier
        guard let bundleID else { throw NVMKeychainError.invalidBundleID(bundleID) }
        
        return "\(bundleID).keys.\(tag)"
    }
}

internal extension NVMKeychainType {
    
    func populate(from item: NVMKeychain.ItemDictionary) -> Self? {
        switch self {
        case .internetCredentials:
            if let account = item[kSecAttrAccount as String] as? String {
                let server = item[kSecAttrServer as String] as? String
                return NVMKeychainType.internetCredentials(username: account, server: server)
            } else {
                return nil
            }
        case .credentials:
            if let account = item[kSecAttrAccount as String] as? String {
                let server = item[kSecAttrServer as String] as? String
                return NVMKeychainType.credentials(username: account, server: server)
            } else {
                return nil
            }
        case .key:
            return nil
        }
    }
}

internal extension NVMKeychain.ItemDictionary {
    
    fileprivate func setName(_ label: String?) -> Self {
        return self.addString(label, forKey: kSecAttrLabel)
    }
    
    fileprivate func setAccessControl(_ accessControl: NVMKeychainSettings.AccessControl?) -> Self {
        guard let cfAccessControl = accessControl?.cfString else { return self }
        
        var mutableDictionary = self
        mutableDictionary.updateValue(cfAccessControl, forKey: kSecAttrAccessible as String)
        
        return mutableDictionary
    }
    
    fileprivate func setSynchronizable(_ settings: NVMKeychainSettings) -> Self {
        return self.addBool(settings.cfSynchronize, forKey: kSecAttrSynchronizable)
    }
    
    fileprivate func setInvisible(_ settings: NVMKeychainSettings) -> Self {
        return self.addBool(settings.cfInvisible, forKey: kSecAttrIsInvisible)
    }
    
    fileprivate func setClass(_ type: NVMKeychainType) -> Self {
        let cfClass = type.cfString
        
        var mutableDictionary = self
        mutableDictionary.updateValue(cfClass, forKey: kSecClass as String)
        
        return mutableDictionary
    }
    
    fileprivate func setAccount(_ username: String?) -> Self {
        return self.addString(username, forKey: kSecAttrAccount)
    }
    
    fileprivate func setServer(_ server: String?) -> Self {
        return self.addString(server, forKey: kSecAttrServer)
    }
    
    // MARK: - Helper functions
    private func addString(_ value: String?, forKey key: CFString) -> Self {
        guard let value, !value.isEmpty else { return self }
        
        var mutableDictionary = self
        mutableDictionary.updateValue(value, forKey: key as String)
        
        return mutableDictionary
    }
    
    private func addBool(_ value: CFBoolean?, forKey key: CFString) -> Self {
        guard let value else { return self }
        
        var mutableDictionary = self
        mutableDictionary.updateValue(value, forKey: key as String)
        
        return mutableDictionary
    }
}
