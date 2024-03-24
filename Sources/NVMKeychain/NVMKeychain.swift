import Foundation


/// A pure Swift library that allows you to easily access the keychain.
///
/// - Note: This project is created and maintained by Novem.
///
public class NVMKeychain {
    
    internal typealias ItemDictionary = [String: Any]
    
    private let keychainType: NVMKeychainType
    private let keychainSettings: NVMKeychainSettings
    
    public init(_ keychainType: NVMKeychainType, settings: NVMKeychainSettings) {
        self.keychainType = keychainType
        self.keychainSettings = settings
    }
    
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
    
    /// Retrieve an item from the `Keychain`.
    ///
    public static func getAll(as type: NVMKeychainType, keychainSettings: NVMKeychainSettings) throws -> [NVMKeychainType] {
        return try Self.retrieveAll(type: type, keychainSettings: keychainSettings)
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
        guard status != errSecNotAvailable else { throw NVMKeychainError.keychainDisabled }
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
    
    private func update(value: Data, tag: String) throws {
        let getquery = try keychainType.createGetQuery(for: tag, settings: keychainSettings)
        let addquery = try keychainType.createAddQuery(for: tag, settings: keychainSettings, key: value)
        
        let status = SecItemUpdate(getquery as CFDictionary, addquery as CFDictionary)
        guard status != errSecNotAvailable else { throw NVMKeychainError.keychainDisabled }
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
    
    private func retrieve<K: NVMKey>(type: K.Type, tag: String) throws -> K {
        let getquery = try keychainType.createGetQuery(for: tag, settings: keychainSettings)
        
        var ref: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &ref)
        guard status != errSecItemNotFound else { throw NVMKeychainError.notFound }
        guard status != errSecNotAvailable else { throw NVMKeychainError.keychainDisabled }
        guard status == errSecSuccess else { throw NVMKeychainError.retrieveFailed(NVMKeychainRetrieveError(status)) }
        
        guard let item = ref as? ItemDictionary
        else { throw NVMKeychainError.invalidKeychainType }
        
        guard let keyData = item[kSecValueData as String] as? Data,
              let nvmKey = type.init(keyData: keyData)
        else { throw NVMKeychainError.invalidPasswordData }
        
        return nvmKey
    }
    
    private static func retrieveAll(type: NVMKeychainType, keychainSettings: NVMKeychainSettings) throws -> [NVMKeychainType] {
        let getquery = try NVMKeychainType.createGetAllQuery(settings: keychainSettings, type: type)
        
        var ref: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &ref)
        guard status != errSecItemNotFound else { throw NVMKeychainError.notFound }
        guard status != errSecNotAvailable else { throw NVMKeychainError.keychainDisabled }
        guard status == errSecSuccess else { throw NVMKeychainError.retrieveFailed(NVMKeychainRetrieveError(status)) }
        
        var keychainTypes: [NVMKeychainType] = []
        if let items = ref as? Array<ItemDictionary> {
            for item in items {
                if let keychainType = type.populate(from: item) {
                    keychainTypes.append(keychainType)
                }
            }
        } else {
            guard let item = ref as? ItemDictionary
            else { throw NVMKeychainError.invalidKeychainType }
            
            if let keychainType = type.populate(from: item) {
                keychainTypes.append(keychainType)
            }
        }
        
        return keychainTypes
    }
    
    private func remove(tag: String) throws {
        let getquery = try keychainType.createGetQuery(for: tag, settings: keychainSettings)
        
        let status = SecItemDelete(getquery as CFDictionary)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(NVMKeychainStoreError(status)) }
    }
}
