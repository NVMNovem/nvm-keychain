import Foundation

public class NVMKeychain {
    
    private let keychainType: NVMKeychainType
    
    private var synchronize: Bool
    private var accessControl: AccessControl?
    
    public init(
        _ keychainType: NVMKeychainType,
        synchronize: Bool = false,
        accessControl: AccessControl? = nil
    ) {
        self.keychainType = keychainType
        
        self.synchronize = synchronize
        self.accessControl = accessControl
    }
    
    typealias ItemDictionary = [String: Any]
    
    /// Create an item in the `Keychain`.
    ///
    /// - Throws: An error when the item already exists. Use `add(_:for:)` when you need to create or update an item.
    ///
    public func create<K: NVMKey>(_ value: K, for key: String) throws {
        try self.store(value: value.keyData(), tag: key)
    }
    
    /// Create or update an item in the `Keychain`.
    ///
    /// - Note: Will update the value when the item already exists.
    /// 
    public func add<K: NVMKey>(_ value: K, for key: String) throws {
        do {
            try self.store(value: value.keyData(), tag: key)
        } catch NVMKeychainError.storeFailed(NVMKeychainStoreError.duplicateItem) {
            try self.update(value, for: key)
        } catch {
            throw error
        }
    }
    
    /// Create or update an item in the `Keychain`.
    ///
    /// - Note: Will update the value when the item already exists.
    ///
    public func update<K: NVMKey>(_ value: K, for key: String) throws {
        try self.update(value: value.keyData(), tag: key)
    }
    
    /// Retrieve an item from the `Keychain`.
    ///
    public func get<K: NVMKey>(_ type: K.Type, for key: String) throws -> K {
        return try self.retrieve(type: type, tag: key)
    }
    
    /// Remove an item from the `Keychain`.
    ///
    public func delete(_ key: String) throws {
        return try self.remove(tag: key)
    }
    
    public enum AccessControl {
        case whenPasscodeSetThisDeviceOnly
        case whenUnlockedThisDeviceOnly
        case whenUnlocked
        case afterFirstUnlockThisDeviceOnly
        case afterFirstUnlock
        
        var cfString: CFString {
            switch self {
            case .whenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            }
        }
    }
    
    private func store(value: Data, tag: String) throws {
        let addquery = try keychainType.createAddQuery(for: tag, accessControl: accessControl, key: value)
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
    
    private func update(value: Data, tag: String) throws {
        let getquery = try keychainType.createGetQuery(for: tag, accessControl: accessControl)
        let addquery = try keychainType.createAddQuery(for: tag, accessControl: accessControl, key: value)
        
        let status = SecItemUpdate(getquery as CFDictionary, addquery as CFDictionary)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
    
    private func retrieve<K: NVMKey>(type: K.Type, tag: String) throws -> K {
        let getquery = try keychainType.createGetQuery(for: tag, accessControl: accessControl)
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw NVMKeychainError.notFound }
        guard status == errSecSuccess else { throw NVMKeychainError.retrieveFailed(NVMKeychainRetrieveError(status)) }
        
        guard let existingItem = item as? ItemDictionary
        else { throw NVMKeychainError.invalidKeychainType }
        
        guard let keyData = existingItem[kSecValueData as String] as? Data,
              let nvmKey = type.init(keyData: keyData)
        else { throw NVMKeychainError.invalidPasswordData }
        
        return nvmKey
    }
    
    private func remove(tag: String) throws {
        let getquery = try keychainType.createGetQuery(for: tag, accessControl: accessControl)
        
        let status = SecItemDelete(getquery as CFDictionary)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
}
