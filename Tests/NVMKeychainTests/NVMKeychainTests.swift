import XCTest
@testable import NVMKeychain

final class NVMKeychainTests: XCTestCase {
    
    func testSet() throws {
        let testPassword = "123456789"
        let testKey = "testKeychain"
        
        let testPassword2 = "1234567890"
        let testKey2 = "testKeychain2"
        
        let settings = NVMKeychainSettings("KeychainTest")
        
        let keychain = NVMKeychain(.internetCredentials(username: "keychainTest", server: "NVMKeychain"), settings: settings)
        let keychain2 = NVMKeychain(.internetCredentials(username: "keychainTest2", server: "NVMKeychain2"), settings: settings)
        try keychain.set(testPassword, for: testKey)
        try keychain2.set(testPassword2, for: testKey2)
            
        let password = try keychain.get(String.self, for: testKey)
        
        XCTAssertEqual(testPassword, password)
    }
    
    func testGetAll() throws {
        let credentials = try NVMKeychain.getAll(as: .internetCredentials(username: "", server: ""),
                                                 keychainSettings: NVMKeychainSettings("KeychainTest"))
        let accounts = credentials.compactMap({ "\($0.server ?? "--"): \(String(describing: $0.username))" }).joined(separator: ", ")
        print(accounts)
        XCTAssertGreaterThan(credentials.count, 0, accounts)
    }
}
