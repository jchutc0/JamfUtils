//
//  MobileListEndpoint.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

struct MobileListEndpoint: JamfGetObject {
    
    enum CodingKeys: String, CodingKey {
        case name
        case intId = "id"
    } // CodingKeys

    var id: String { "\(intId)" }
    var intId: Int
    var name: String

    static let getAllEndpoint = String("/JSSResource/mobiledevices")
    
    struct Results: Codable { let mobile_devices: [MobileListEndpoint] }
        
    static func decodeAllResults(data: Data) throws -> [Self] {
        do { return (try decodeData(data: data) as Results).mobile_devices }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeAllResults

} // ComputerListEndpoint
