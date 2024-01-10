//
//  Keychain.swift
//  JamfUtils
//
//  Created by jchutc0 on 10/12/23.
//

import Foundation

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case entryExists
    case missingCredential
    case passwordMatch
    case unhandledError(status: OSStatus)
}

struct Keychain {
    

    // ********** ********** ********** ********** ********** ********** **********
    
    static func add(username: String, password: String, server: String) throws {
        guard username != "",
              password != "",
              server != ""
        else { throw KeychainError.missingCredential }
        
        let query: NSDictionary = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecAttrLabel: server,
            kSecAttrAccount: username,
            kSecValueData: Data(password.utf8)
        ] // query

        let status = SecItemAdd(query, nil)
        guard status != errSecDuplicateItem else { throw KeychainError.entryExists }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    } // add
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func search(username: String, server: String) throws -> String {
        let query = try searchQuery(username: username, server: server)
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        
        guard let passwordData = item as? Data,
              let password = String(data: passwordData, encoding: .utf8)
        else { throw KeychainError.unexpectedPasswordData }
        
        return password
    } // search function
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func updateOrAdd(username: String, password: String, server: String) throws {
        guard password != "" else { throw KeychainError.missingCredential }
        let query = try searchQuery(username: username, server: server)
        
        let attributes = [
            kSecAttrAccount as String: username,
            kSecValueData as String: password.data(using: String.Encoding.utf8)!
        ] as [String : Any] as CFDictionary
        
        let status = SecItemUpdate(query, attributes)
        guard status != errSecItemNotFound else {
            return try add(username: username, password: password, server: server)
        }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    } // updateOrAdd
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func updateOrAdd(
        username: String, password: String, server: String, retryPassword: String
    ) throws {
        guard retryPassword == password else { throw KeychainError.passwordMatch }
        try updateOrAdd(username: username, password: password, server: server)
    } // updateOrAdd
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func delete(username: String, server: String) throws {
        let query = try searchQuery(username: username, server: server)
        
        let status = SecItemDelete(query)
        guard status == errSecSuccess || status != errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    } // delete
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func decodeStatus(status: OSStatus) -> String? {
        return SecCopyErrorMessageString(status, nil) as String?
    } // decodeStatus
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func searchQuery(username: String, server: String) throws -> NSDictionary {
        guard username != "", server != ""
        else { throw KeychainError.missingCredential }
        
        return [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecAttrAccount: username,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
    } // searchQuery
    
} // Keychain class
