//
//  NVMKeychainSettings.swift
//
//
//  Created by Damian Van de Kauter on 03/03/2024.
//

import Foundation

public class NVMKeychainSettings {
    
    internal let label: String
    internal let accessControl: AccessControl?
    
    private var _synchronize: Bool
    private var _invisible: Bool
    
    public init(_ label: String, accessControl: AccessControl? = nil) {
        self.label = label
        self.accessControl = accessControl
        
        self._synchronize = false
        self._invisible = false
    }
    
    // MARK: - Setters
    public func synchronizable() -> Self {
        self._synchronize = true
        return self
    }
    
    public func invisible() -> Self {
        self._invisible = true
        return self
    }
    
    // MARK: - Getters
    internal var cfSynchronize: CFBoolean? {
        return _synchronize ? kCFBooleanTrue : nil
    }
    
    internal var cfInvisible: CFBoolean? {
        return _invisible ? kCFBooleanTrue : nil
    }
    
    // MARK: - AccessControl
    public enum AccessControl {
        case whenPasscodeSetThisDeviceOnly
        case whenUnlockedThisDeviceOnly
        case whenUnlocked
        case afterFirstUnlockThisDeviceOnly
        case afterFirstUnlock
        
        internal var cfString: CFString {
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
}
