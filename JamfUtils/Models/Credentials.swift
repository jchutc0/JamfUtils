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
    
} // Credentials
