//
//  JamfGetObject.swift
//  jamf_begin
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

protocol JamfGetObject: Codable, Identifiable {
    var id: String { get }
    static var getAllEndpoint: String { get }
    
    static func getAll() async throws -> [Self]
    static func getOne(query: String) async throws -> Self
    static func getUrl(server: String, query: String) throws -> URL
    static func getRequest(url: URL, token: String) -> URLRequest
    static func getData(request: URLRequest) async throws -> Data
    static func getJSONDecoder() -> JSONDecoder
    static func parseDecodeError(_ jsonError: Error) -> String
    static func decodeAllResults(data: Data) throws -> [Self]
    static func decodeOneResult(data: Data) throws -> Self
    
} // JamfObject

enum JSSError: Error {
    case getRequestFail(url: String)
    case connectionFailure
    case invalidHttpStatus(Int, String)
    case decode(String)
}

extension JSSError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .getRequestFail:
            return NSLocalizedString("Unable to get URL for the JSS", comment: "")
        case .connectionFailure:
            return NSLocalizedString("Unable to connect to the JSS", comment: "")
        case .invalidHttpStatus(let code, let string):
            return NSLocalizedString("Invalid HTTP status code: \(code) for URL: \(string)", comment: "")
        case .decode(let errString):
            return NSLocalizedString("Error decoding JSON -- \(errString)", comment: "")
        }
    }
}

extension JamfGetObject {
    
    // ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
    // build the URL for the request to fetch all objects
    static func getUrl(server: String, query: String = "") throws -> URL {
        // assemble the URL for the Jamf API
        guard var components = URLComponents(string: server) else {
            throw JSSError.getRequestFail(url: server)
        }
        components.path = "\(getAllEndpoint)\(query)"
        guard let url = components.url else {
            throw JSSError.getRequestFail(url: server + components.path)
        }
        return url
    } // getUrl
    
    // ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
    // build a URLRequest GET from a URL
    static func getRequest(url: URL, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    } // getRequest

    // ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
    // gets data from the server
    static func getData(request: URLRequest) async throws -> Data {
        // send request and get data
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            throw JSSError.connectionFailure
        }
        
        // MARK: Handle error
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            throw JSSError.invalidHttpStatus(statusCode, request.url?.absoluteString ?? "")
        }
        return data
    } // getData
    
    static func getJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
    
    static func parseDecodeError(_ jsonError: Error) -> String {
        switch jsonError {
        case DecodingError.dataCorrupted(let context):
            return "\(context.codingPath): data corrupted: \(context.debugDescription)"
        case DecodingError.keyNotFound(let key, let context):
            return "\(context.codingPath): key \(key) not found: \(context.debugDescription)"
        case DecodingError.valueNotFound(let value, let context):
            return "\(context.codingPath): value \(value) not found: \(context.debugDescription)"
        case DecodingError.typeMismatch(let type, let context):
            return "\(context.codingPath): type \(type) mismatch: \(context.debugDescription)"
        default:
            return "error \(jsonError)"
        }
    }

    // ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
    // gets a list of all objects from the server
    static func getAll() async throws -> [Self] {
        try await Auth.getAuth()
        guard let server = Auth.server,
              let token = Auth.token else {
            throw AuthError.noCredentials
        }
        let url = try getUrl(server: server)
        let request = getRequest(url: url, token: token)
        
        let data = try await getData(request: request)
        return try decodeAllResults(data: data)
    } // getAll
    
    // ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
    // returns a single instance of the object
    static func getOne(query: String) async throws -> Self {
        try await Auth.getAuth()
        guard let server = Auth.server,
              let token = Auth.token else {
            throw AuthError.noCredentials
        }
        let url = try getUrl(server: server, query: "/id/\(query)")
        let request = getRequest(url: url, token: token)

        let data = try await getData(request: request)
        return try decodeOneResult(data: data)
    } // getOne
    
    // ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
    // decodes a class from JSON data
    static func decodeData<T: Codable>(data: Data) throws -> T {
        let decoder = getJSONDecoder()
        do {
            let result = try decoder.decode(T.self, from: data)
            return result
            // handle decoding errors
        } catch DecodingError.dataCorrupted(let context) {
            throw JSSError.decode("\(context.codingPath): data corrupted: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            throw JSSError.decode("\(context.codingPath): key \(key) not found: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let value, let context) {
            throw JSSError.decode("\(context.codingPath): value \(value) not found: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            throw JSSError.decode("\(context.codingPath): type \(type) mismatch: \(context.debugDescription)")
        } catch {
            throw JSSError.decode("error: \(error)")
        }
    } // decodeData
    
    static func decodeAllResults(data: Data) throws -> [Self] {
        do { return (try decodeData(data: data) as JamfResults<Self>).results }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeAllResults
    
    static func decodeOneResult(data: Data) throws -> Self {
        do { return try decodeData(data: data) }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeOneResult


} // JamfObject

struct JamfResults<T: JamfGetObject>: Codable {
    var results: [T]
} // JamfResults
