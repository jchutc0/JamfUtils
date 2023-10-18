//
//  ComputerListEndpoint.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

struct ComputerListEndpoint: JamfListEndpoint {
    
    enum CodingKeys: String, CodingKey {
        case name
        case intId = "id"
    } // CodingKeys

    var intId: Int
    var name: String

    static let getAllEndpoint = String("/JSSResource/computers")
    static let description = String("computer objects")
    
    struct Results: Codable { let computers: [ComputerListEndpoint] }
        
    static func decodeAllResults(data: Data) throws -> [Self] {
        do { return (try decodeData(data: data) as Results).computers }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeAllResults
    
    static func getItem(id: String) async throws -> any JamfListObject {
        return try await ComputerEndpoint.getOne(query: id)
    }

} // ComputerListEndpoint
