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
    case invalidCredentials
} // AuthError

/// Auth
///
/// Structure to hold auth tokens
/// Functions:
/// getAuth(), getCredentials(), validToken(), expireToken()
struct Auth {
    static var cred: OAuthCredentials?
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
            
            expire = Date().addingTimeInterval(-Double(newToken.expires_in))
            if expire == nil { throw AuthError.invalidDateFormat }
            token = newToken.access_token
        } catch {
            token = nil
            expire = nil
            throw error
        }
    } // getAuth
    
    /// getAuth
    ///
    /// Sets an authorization token with credentials
    @MainActor
    static func getAuth(credentials: OAuthCredentials) async throws {
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
        var access_token: String
        var expires_in: Int
        
        static func get(
            server: String,
            client_id: String,
            client_secret: String
        ) async throws -> JamfAuthToken {
            
            // MARK: Prepare Request
            // assemble the URL for the Jamf API
            guard var components = URLComponents(string: server) else {
                throw AuthError.getRequestFail(url: server)
            }
            components.path = "/api/oauth/token"
            guard let url = components.url else {
                throw AuthError.getRequestFail(url: server + components.path)
            }
            
            // Assemble the data to send
            guard let grantType = "grant_type=client_credentials"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let clientId = "client_id=\(client_id)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let clientSecret = "client_secret=\(client_secret)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                throw AuthError.invalidCredentials
            }

            let dataString = "\(grantType)&\(clientId)&\(clientSecret)"

            // MARK: Send request and get data
            var authRequest = URLRequest(url: url)
            authRequest.httpMethod = "POST"
            authRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            authRequest.httpBody = dataString.data(using: .utf8)
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
        
        static func get(cred: OAuthCredentials) async throws -> JamfAuthToken {
            try await JamfAuthToken.get(
                server: cred.server,
                client_id: cred.client_id,
                client_secret: cred.client_secret
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

} // Auth

