//
//  ComputerEndpoint.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

struct ComputerEndpoint: JamfListObject {
    
    var general: General
    var extension_attributes: [Extension]
    
    static let getAllEndpoint = String("/JSSResource/computers")
    
    struct Results: Codable { let computer: ComputerEndpoint }
    
    static func decodeOneResult(data: Data) throws -> Self {
        do { return (try decodeData(data: data) as Results).computer }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeOneResult
    
    func updateSite() async throws {
        let rootElement = XMLElement(name: "computer")
        let extsElement = XMLElement(name: "extension_attributes")
        let extElement = XMLElement(name: "extension_attribute")
        let nameElement = XMLElement(name: "id", stringValue: "33")
        let valueElement = XMLElement(name: "value", stringValue: general.site.name)
        rootElement.addChild(extsElement)
        extsElement.addChild(extElement)
        extElement.addChild(nameElement)
        extElement.addChild(valueElement)
        let xml = XMLDocument(rootElement: rootElement).xmlData
        try await Self.updateOne(id: id, xml: xml)
    }
    
} // ComputerEndpoint
