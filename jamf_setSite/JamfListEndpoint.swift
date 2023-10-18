//
//  JamfListEndpoint.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/17/23.
//

import Foundation

protocol JamfListEndpoint: JamfGetObject {
    var intId: Int { get }
    var name: String { get }
    static var description: String { get }
    static func getItem(id: String) async throws -> any JamfListObject
} // JamfListEndpoint

extension JamfListEndpoint {
    var id: String { "\(intId)" }
} // JamfListEndpoint
