//
//  NVMKeychainType.swift
//
//
//  Created by Damian Van de Kauter on 02/03/2024.
//

import Foundation

public struct NVMKeychainCredentials: NVMKeychainType {
    public var username: String
    public var password: String?
    
    public var server: String
    
    public let cfString = kSecClassInternetPassword
    
    public init(username: String, password: String,
                server: String) {
        self.username = username
        self.password = password
        
        self.server = server
    }
    
    public init(server: String, username: String) {
        self.username = username
        self.password = nil
        
        self.server = server
    }
}

public struct NVMKeychainPassword: NVMKeychainType {
    public var password: String?
    
    public let cfString = kSecClassGenericPassword
    
    public init(_ password: String) {
        self.password = password
    }
    
    public init() {
        self.password = nil
    }
}

public struct NVMKeychainKey: NVMKeychainType {
    public var key: Data?
    
    public let cfString = kSecClassKey
    
    public init(_ key: Data) {
        self.key = key
    }
    
    public init() {
        self.key = nil
    }
}

public protocol NVMKeychainType {
    
    var cfString: CFString { get }
}

extension NVMKeychainType {
    
    func createAddQuery(key: String) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try self.getKeysIdentifier(key: key)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        var mutableQuery: NVMKeychain.ItemDictionary = try [kSecAttrApplicationTag as String: tag]
            .setClass(self)
            .setServer(self)
            .setAccount(self)
            .setKeyData(self)
        
        return mutableQuery
    }
    
    func createGetQuery(key: String) throws -> NVMKeychain.ItemDictionary {
        let keyIdentifier = try self.getKeysIdentifier(key: key)
        guard let tag = keyIdentifier.data(using: .utf8) else { throw NVMKeychainError.tagFailed }
        
        var mutableQuery: NVMKeychain.ItemDictionary = [kSecAttrApplicationTag as String: tag,
                                                        kSecMatchLimit as String: kSecMatchLimitOne,
                                                        kSecReturnAttributes as String: true,
                                                        kSecReturnData as String: true]
            .setClass(self)
            .setServer(self)
            .setAccount(self)
        
        return mutableQuery
    }
    
    private func getKeysIdentifier(key: String) throws -> String {
        let bundleID = Bundle.main.bundleIdentifier
        guard let bundleID else { throw NVMKeychainError.invalidBundleID(bundleID) }
        
        return "\(bundleID).keys.\(key)"
    }
    
    func apply(item: NVMKeychain.ItemDictionary) throws -> Self {
        if var keychainCredentials = self as? NVMKeychainCredentials {
            guard let passwordData = item[kSecValueData as String] as? Data,
                  let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else { throw NVMKeychainError.invalidPasswordData }
            
            keychainCredentials.password = password
            
            guard let keychainType = keychainCredentials as? Self
            else { throw NVMKeychainError.invalidKeychainType }
            return keychainType
        } else
        if var keychainPassword = self as? NVMKeychainPassword {
            guard let passwordData = item[kSecValueData as String] as? Data,
                  let password = String(data: passwordData, encoding: String.Encoding.utf8)
            else { throw NVMKeychainError.invalidPasswordData }
            
            keychainPassword.password = password
            
            guard let keychainType = keychainPassword as? Self
            else { throw NVMKeychainError.invalidKeychainType }
            return keychainType
        } else
        if var keychainKey = self as? NVMKeychainKey {
            guard let passwordData = item[kSecValueData as String] as? Data
            else { throw NVMKeychainError.invalidPasswordData }
            
            keychainKey.key = passwordData
            
            guard let keychainType = keychainKey as? Self
            else { throw NVMKeychainError.invalidKeychainType }
            return keychainType
        } else {
            throw NVMKeychainError.invalidKeychainType
        }
    }
}

fileprivate extension NVMKeychainType {
    
    func getKeyData() throws -> Data {
        if let keychainCredentials = self as? NVMKeychainCredentials {
            guard let keyData = keychainCredentials.password?.data(using: String.Encoding.utf8)
            else { throw NVMKeychainError.invalidPasswordData }
            
            return keyData
        } else
        if let keychainPassword = self as? NVMKeychainPassword {
            guard let keyData = keychainPassword.password?.data(using: String.Encoding.utf8)
            else { throw NVMKeychainError.invalidPasswordData }
            
            return keyData
        } else
        if let keychainKey = self as? NVMKeychainKey {
            guard let keyData = keychainKey.key
            else { throw NVMKeychainError.invalidPasswordData }
            
            return keyData
        } else {
            throw NVMKeychainError.invalidKeychainType
        }
    }
}

extension NVMKeychain.ItemDictionary {
    
    fileprivate func setClass(_ value: NVMKeychainType) -> Self {
        let cfClass = value.cfString
        
        var mutableDictionary = self
        mutableDictionary.updateValue(cfClass, forKey: kSecClass as String)
        
        return mutableDictionary
    }
    
    fileprivate func setAccount(_ value: NVMKeychainType) -> Self {
        guard let account = (value as? NVMKeychainCredentials)?.username
        else { return self }
        
        var mutableDictionary = self
        mutableDictionary.updateValue(account, forKey: kSecAttrAccount as String)
        
        return mutableDictionary
    }
    
    fileprivate func setServer(_ value: NVMKeychainType) -> Self {
        guard let server = (value as? NVMKeychainCredentials)?.server
        else { return self }
        
        var mutableDictionary = self
        mutableDictionary.updateValue(server, forKey: kSecAttrServer as String)
        
        return mutableDictionary
    }
    
    fileprivate func setKeyData(_ value: NVMKeychainType) throws -> Self {
        let keyData = try value.getKeyData()
        
        var mutableDictionary = self
        mutableDictionary.updateValue(keyData, forKey: kSecValueData as String)
        
        return mutableDictionary
    }
}
