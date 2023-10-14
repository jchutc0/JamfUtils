//
//  JamfPutObject.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

protocol JamfPutObject: JamfGetObject {
    
    static func updateOne(id: String, xml: Data) async throws
    static func putRequest(url: URL, token: String, httpBody: Data) -> URLRequest

}

extension JamfPutObject {
    
    static func updateOne(id: String, xml: Data) async throws {
        try await Auth.getAuth()
        guard let server = Auth.server,
              let token = Auth.token else {
            throw AuthError.noCredentials
        }
        let url = try getUrl(server: server, query: "/id/\(id)")
        let request = putRequest(url: url, token: token, httpBody: xml)
        guard let (_, response) = try? await URLSession.shared.data(for: request) else {
            throw JSSError.connectionFailure
        }
        
        // MARK: Handle error
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            throw JSSError.invalidHttpStatus(statusCode, url.absoluteString)
        }

    } // putOne
    
    static func putRequest(url: URL, token: String, httpBody: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        return request
    } // putRequest

} // JamfPutObject
