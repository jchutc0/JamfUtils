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

    static func add(credentials: Credentials) throws {
        guard credentials.username != "",
              credentials.password != "",
              credentials.server != ""
        else { throw KeychainError.missingCredential }
        
        let query: NSDictionary = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: credentials.server,
            kSecAttrLabel: credentials.server,
            kSecAttrAccount: credentials.username,
            kSecValueData: Data(credentials.password.utf8)
        ] // query

        let status = SecItemAdd(query, nil)
        guard status != errSecDuplicateItem else { throw KeychainError.entryExists }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    } // add
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func search(credentials: Credentials) throws -> String {
        let query = try searchQuery(credentials: credentials)
        
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
    
    static func updateOrAdd(credentials: Credentials) throws {
        guard credentials.password != "" else { throw KeychainError.missingCredential }
        let query = try searchQuery(credentials: credentials)
        
        let attributes = [
            kSecAttrAccount as String: credentials.username,
            kSecValueData as String: credentials.password.data(using: String.Encoding.utf8)!
        ] as [String : Any] as CFDictionary
        
        let status = SecItemUpdate(query, attributes)
        guard status != errSecItemNotFound else { return try add(credentials: credentials) }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    } // updateOrAdd
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func updateOrAdd(credentials: Credentials, retryPassword: String) throws {
        guard retryPassword == credentials.password else { throw KeychainError.passwordMatch }
        try updateOrAdd(credentials: credentials)
    } // updateOrAdd
    
    // ********** ********** ********** ********** ********** ********** **********
    
    static func delete(credentials: Credentials) throws {
        let query = try searchQuery(credentials: credentials)
        
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
    
    static func searchQuery(credentials: Credentials) throws -> NSDictionary {
        guard credentials.username != "",
              credentials.server != ""
        else { throw KeychainError.missingCredential }
        
        return [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: credentials.server,
            kSecAttrAccount: credentials.username,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
    } // searchQuery
    
} // Keychain class
