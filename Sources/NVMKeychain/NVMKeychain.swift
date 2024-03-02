import Foundation

public class NVMKeychain {
    
    private var synchronize: Bool
    private var accessControl: AccessControl?
    
    public init(synchronize: Bool = false,
                accessControl: AccessControl? = nil) {
        self.synchronize = synchronize
        self.accessControl = accessControl
    }
    
    typealias ItemDictionary = [String: Any]
    
    public func add<K: NVMKeychainType>(_ value: K, for key: String) throws {
        try self.store(value: value, key: key)
    }
    
    public func get<K: NVMKeychainType>(_ returnBlock: K, for key: String) throws -> K {
        return try self.retrieve(returnBlock: returnBlock, key: key)
    }
    
    public enum AccessControl {
        case whenPasscodeSetThisDeviceOnly
        
        var cfString: CFString {
            switch self {
            case .whenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            }
        }
    }
    
    private func store<K: NVMKeychainType>(value: K, key: String) throws {
        let addquery = try value.createAddQuery(key: key)
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else { throw NVMKeychainError.storeFailed(status: status) }
    }
    
    private func retrieve<K: NVMKeychainType>(returnBlock: K, key: String) throws -> K {
        let getquery = try returnBlock.createGetQuery(key: key)
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw NVMKeychainError.notFound }
        guard status == errSecSuccess else { throw NVMKeychainError.retrieveFailed(status: status) }
        
        guard let existingItem = item as? ItemDictionary
        else { throw NVMKeychainError.invalidKeychainType }
        
        return try returnBlock.apply(item: existingItem)
    }
}
