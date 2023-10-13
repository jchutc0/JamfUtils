//
//  ComputerListEndpoint.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

struct ComputerListEndpoint: JamfGetObject {
    
    enum CodingKeys: String, CodingKey {
        case name
        case intId = "id"
    } // CodingKeys

    var id: String { "\(intId)" }
    var intId: Int
    var name: String

    static let getAllEndpoint = String("/JSSResource/computers")
    
    struct Results: Codable { let computers: [ComputerListEndpoint] }
        
    static func decodeAllResults(data: Data) throws -> [Self] {
        do { return (try decodeData(data: data) as Results).computers }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeAllResults

} // ComputerListEndpoint
