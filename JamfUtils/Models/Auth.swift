//
//  Auth.swift
//  JamfUtils
//
//  Created by jchutc0 on 10/12/23.
//

import Foundation

enum AuthError: Error {
    case getRequestFail(url: String)
    case connectionFailure
    case invalidHttpStatus(Int, String)
    case decode(String)
    case noCredentials
    case invalidDateFormat
} // AuthError

/// Auth
///
/// Structure to hold auth tokens
/// Functions:
/// getAuth(), getCredentials(), validToken(), expireToken()
struct Auth {
    static var cred: Credentials?
    static var token: String?
    static var expire: Date?
    static var server: String? { cred?.server }
    
    /// getAuth
    ///
    /// Sets an authorization token
    static func getAuth() async throws {
        if cred == nil { try getCredentials() }
        guard let cred else { throw AuthError.noCredentials }
        
        if validToken() { return }
        
        do {
            let newToken = try await JamfAuthToken.get(cred: cred)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            expire = dateFormatter.date(from: newToken.expires)?.addingTimeInterval(-300)
            if expire == nil { throw AuthError.invalidDateFormat }
            token = newToken.token
        } catch {
            token = nil
            expire = nil
            throw error
        }
    } // getAuth
    
    /// getAuth
    ///
    /// Sets an authorization token with credentials
    static func getAuth(credentials: Credentials) async throws {
        cred = credentials
        do {
            return try await getAuth()
        } catch {
            cred = nil
            token = nil
            expire = nil
            throw error
        }
    } // getAuth

    /// getCredentials
    ///
    /// Set up to override for particular cases
    static func getCredentials() throws {
        throw AuthError.noCredentials
    }
    
    /// validToken
    ///
    /// Checks whether the token is valid
    static func validToken() -> Bool {
        guard let expire else { return false }
        return (
            cred != nil &&
            token != nil &&
            expire >= Date()
        )
    }
    
    /// expireToken
    ///
    /// Removes the token variables and attempts to invalidate the token on the Jamf server
    static func expireToken() async {
        defer {
            token = nil
            expire = nil
        }
        guard let token, let cred else { return }
        await JamfAuthToken.expireToken(token: token, server: cred.server)
    } // expireToken
    
    
    // MARK: - JamfAuthToken
    struct JamfAuthToken: Codable {
        var token: String
        var expires: String
        
        static func get(
            server: String,
            username: String,
            password: String
        ) async throws -> JamfAuthToken {
            
            // MARK: Prepare Request
            // encode username and password
            let base64 = "\(username):\(password)"
                .data(using: .utf8)!
                .base64EncodedString()
            
            // assemble the URL for the Jamf API
            guard var components = URLComponents(string: server) else {
                throw AuthError.getRequestFail(url: server)
            }
            components.path = "/api/v1/auth/token"
            guard let url = components.url else {
                throw AuthError.getRequestFail(url: server + components.path)
            }
            
            // MARK: Send request and get data
            var authRequest = URLRequest(url: url)
            authRequest.httpMethod = "POST"
            authRequest.addValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            guard let (data, response) = try? await URLSession.shared.data(for: authRequest) else {
                throw AuthError.connectionFailure
            }
            
            // MARK: Handle errors
            
            // check the response code
            let authStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200...299).contains(authStatusCode) else {
                throw AuthError.invalidHttpStatus(authStatusCode, url.absoluteString)
            }
            
            // MARK: Parse JSON
            guard let auth = try? JSONDecoder().decode(JamfAuthToken.self, from: data) else {
                throw AuthError.decode("")
            }
            
            return auth
        } // get
        
        static func get(cred: Credentials) async throws -> JamfAuthToken {
            try await JamfAuthToken.get(
                server: cred.server,
                username: cred.username,
                password: cred.password
            )
        } // get with credentials
        
        static func expireToken(token: String, server: String) async {
            // MARK: Prepare Request
            guard var components = URLComponents(string: server) else { return }
            components.path = "/api/v1/auth/invalidate-token"
            guard let url = components.url else { return }

            // MARK: Send request and get data
            var authRequest = URLRequest(url: url)
            authRequest.httpMethod = "POST"
            authRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: authRequest)
        }

                
    } // struct

}
