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
    
    public func add<K: NVMKey>(_ value: K, for key: String) throws {
        try self.store(value: value.keyData(), tag: key)
    }
    
    public func get<K: NVMKey>(_ type: K.Type, for key: String) throws -> K {
        return try self.retrieve(type: type, tag: key)
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
}
