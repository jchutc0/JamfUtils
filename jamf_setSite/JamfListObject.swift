//
//  JamfListObject.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/17/23.
//

import Foundation

struct General: Codable {
    var id: Int
    var name: String
    var site: Site
    struct Site: Codable { var name: String }
} // MobileEndpoint.General

struct Extension: Codable {
    var name: String
    var value: String
}

protocol JamfListObject: JamfGetObject, JamfPutObject {
    var general: General { get }
    var extension_attributes: [Extension] { get }
    var name: String { get }
    var siteName: String { get }
    var extSite: String { get }
    func updateSite() async throws
} // JamfListObject

extension JamfListObject {
    var name: String { general.name }
    var siteName: String { general.site.name }
    var extSite: String { extension_attributes.first(where: {$0.name == "Jamf Site"})?.value ?? "" }
    var id: String { "\(general.id)" }
} // JamfListObject
