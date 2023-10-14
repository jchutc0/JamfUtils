//
//  Credentials.swift
//  JamfUtils
//
//  Created by jchutc0 on 10/12/23.
//

import Foundation

enum CredentialError: Error{
    case noDefaults
}

struct Credentials {
    var username = String()
    var password = String()
    var server = String()
    static let userKey = "jssUsername"
    static let urlKey = "jssUrl"
    
    static func getFromDefaults() throws -> Credentials  {
        guard let dUsername = UserDefaults.standard.string(forKey: userKey)
        else { throw CredentialError.noDefaults }
        guard let dUrl = UserDefaults.standard.string(forKey: urlKey)
        else { throw CredentialError.noDefaults }
        return Credentials(username: dUsername, password: "", server: dUrl)
    } // getFromDefaults
    
    static func writeToDefaults(cred: Credentials) {
        UserDefaults.standard.set(cred.username, forKey: userKey)
        UserDefaults.standard.set(cred.server, forKey: urlKey)
    } // writeToDefaults
    
    static func promptForCredentials() -> Credentials {
        var credentials: Credentials = {
            do {
                let credentials = try Credentials.getFromDefaults()
                print("Jamf URL: \(credentials.server)")
                print("Jamf Username: \(credentials.username)")
                return credentials
            } catch {
                print("Could not load credentials from defaults.")
                print("Enter the URL of the Jamf server:")
                guard let url = readLine(strippingNewline: true) else {
                    print("The URL is required")
                    exit(1)
                }
                print("Enter the username for the Jamf server:")
                guard let username = readLine(strippingNewline: true) else {
                    print("The URL is required")
                    exit(1)
                }
                let credentials = Credentials(username: username, password: "", server: url)
                Credentials.writeToDefaults(cred: credentials)
                return credentials
            } // do...catch
        }()
        do {
            credentials.password = try Keychain.search(credentials: credentials)
            print("Password of \(credentials.password.count) characters found!")
        } catch {
            print("Could not find the password in the keychain.")
            print("Enter the password for the username:")
            guard let password = getpass("") else {
                print("Password is required")
                exit(1)
            }
            credentials.password = String(cString: password)
            try? Keychain.add(credentials: credentials)
        }
        
        return credentials

    } // promptForCredentials
    
} // Credentials
