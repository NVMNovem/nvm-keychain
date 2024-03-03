import Foundation

public class NVMKeychain {
    
    private let keychainType: NVMKeychainType
    private let keychainSettings: NVMKeychainSettings
    
    public init(_ keychainType: NVMKeychainType, settings: NVMKeychainSettings) {
        self.keychainType = keychainType
        self.keychainSettings = settings
    }
    
    typealias ItemDictionary = [String: Any]
    
    /// Create or update an item in the `Keychain`.
    ///
    /// - Note: Will update the value when the item already exists.
    /// 
    public func set<K: NVMKey>(_ value: K, for key: String) throws {
        do {
            try self.create(value, for: key)
        } catch NVMKeychainError.storeFailed(NVMKeychainStoreError.duplicateItem) {
            try self.update(value, for: key)
        } catch {
            throw error
        }
    }
    
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
    
    // MARK: - Helper functions
    private func store(value: Data, tag: String) throws {
        let addquery = try keychainType.createAddQuery(for: tag, settings: keychainSettings, key: value)
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
    
    private func update(value: Data, tag: String) throws {
        let getquery = try keychainType.createGetQuery(for: tag, settings: keychainSettings)
        let addquery = try keychainType.createAddQuery(for: tag, settings: keychainSettings, key: value)
        
        let status = SecItemUpdate(getquery as CFDictionary, addquery as CFDictionary)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
    
    private func retrieve<K: NVMKey>(type: K.Type, tag: String) throws -> K {
        let getquery = try keychainType.createGetQuery(for: tag, settings: keychainSettings)
        
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
        let getquery = try keychainType.createGetQuery(for: tag, settings: keychainSettings)
        
        let status = SecItemDelete(getquery as CFDictionary)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
}
