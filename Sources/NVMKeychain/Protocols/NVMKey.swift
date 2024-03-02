//
//  NVMKey.swift
//  
//
//  Created by Damian Van de Kauter on 02/03/2024.
//

import Foundation


public protocol NVMKey {
    
    func keyData() throws -> Data
    
    init?(keyData: Data)
}

extension Data: NVMKey {
    
    public func keyData() throws -> Data {
        return self
    }
    
    public init?(keyData: Data) {
        self = keyData
    }
}

extension String: NVMKey {
    
    public func keyData() throws -> Data {
        guard let data = self.data(using: .utf8) else { throw NVMKeychainError.invalidPasswordData }
        return data
    }
    
    public init?(keyData: Data) {
        guard let nvmKey = String(data: keyData, encoding: String.Encoding.utf8) else { return nil }
        self = nvmKey
    }
}
