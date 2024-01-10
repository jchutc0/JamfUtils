//
//  OAuthCredentials.swift
//  jamf_begin
//
//  Created by jchutc0 on 1/9/24.
//

import Foundation

enum CredentialError: Error{
    case noDefaults
}

// MARK: - OAuthCredentials

struct OAuthCredentials {
    var client_id = String()
    var client_secret = String()
    var server = String()
    static let client_id = "client_id"
    static let client_secret = "client_secret"
    static let server = "server"
    
    static func getFromDefaults() throws -> OAuthCredentials  {
        guard let client_id = UserDefaults.standard.string(forKey: client_id),
              let server = UserDefaults.standard.string(forKey: server)
        else { throw CredentialError.noDefaults }
        return OAuthCredentials(client_id: client_id, client_secret: "", server: server)
    } // getFromDefaults
    
    static func writeToDefaults(cred: OAuthCredentials) {
        UserDefaults.standard.set(cred.client_id, forKey: client_id)
        UserDefaults.standard.set(cred.server, forKey: server)
    } // writeToDefaults
    
    static func promptForCredentials() -> OAuthCredentials {
        var credentials: OAuthCredentials = {
            do {
                let credentials = try OAuthCredentials.getFromDefaults()
                print("Jamf URL: \(credentials.server)")
                print("Client ID: \(credentials.client_id)")
                return credentials
            } catch {
                print("Could not load credentials from defaults.")
                print("Enter the URL of the Jamf server:")
                guard let url = readLine(strippingNewline: true) else {
                    print("The URL is required")
                    exit(1)
                }
                print("Enter the OAuth client ID:")
                guard let client_id = readLine(strippingNewline: true) else {
                    print("The client ID is required")
                    exit(1)
                }
                let credentials = OAuthCredentials(client_id: client_id, client_secret: "", server: url)
                OAuthCredentials.writeToDefaults(cred: credentials)
                return credentials
            } // do...catch
        }()
        do {
            credentials.client_secret = try Keychain.search(credentials)
            print("Client secret of \(credentials.client_secret.count) characters found!")
        } catch {
            print("Could not find the client secret in the keychain.")
            print("Enter the client secret for the client ID:")
            guard let client_secret = getpass("") else {
                print("client secret is required")
                exit(1)
            }
            credentials.client_secret = String(cString: client_secret)
            try? Keychain.add(credentials)
        } // do...catch
        
        return credentials
    } // promptForCredentials
    
} // OAuthCredentials

// MARK: - Keychain

extension Keychain {
    
    static func add(_ c: OAuthCredentials) throws {
        try add(username: c.client_id, password: c.client_secret, server: c.server)
    }
    
    static func searchQuery(_ c: OAuthCredentials) throws -> NSDictionary {
        try searchQuery(username: c.client_id, server: c.server)
    }
    
    static func search(_ c: OAuthCredentials) throws -> String {
        try search(username: c.client_id, server: c.server)
    }
    
    static func updateOrAdd(_ c: OAuthCredentials) throws {
        try updateOrAdd(username: c.client_id, password: c.client_secret, server: c.server)
    }
    
    static func updateOrAdd(credentials c: OAuthCredentials, retryPassword: String) throws {
        try updateOrAdd(username: c.client_id, password: c.client_secret, server: c.server, retryPassword: retryPassword)
    }
    
    static func delete(_ c: OAuthCredentials) throws {
        try delete(username: c.client_id, server: c.server)
    }
    
} // Keychain
