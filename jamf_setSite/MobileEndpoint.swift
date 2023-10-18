//
//  MobileEndpoint.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/14/23.
//

import Foundation

struct MobileEndpoint: JamfListObject {

    var general: General
    var extension_attributes: [Extension]
    
    static let getAllEndpoint = String("/JSSResource/mobiledevices")
    
    struct Results: Codable { let mobile_device: MobileEndpoint }
    
    static func decodeOneResult(data: Data) throws -> Self {
        do { return (try decodeData(data: data) as Results).mobile_device }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeOneResult
    
    func updateSite() async throws {
        let rootElement = XMLElement(name: "mobile_device")
        let extsElement = XMLElement(name: "extension_attributes")
        let extElement = XMLElement(name: "extension_attribute")
        let nameElement = XMLElement(name: "name", stringValue: "Jamf Site")
        let valueElement = XMLElement(name: "value", stringValue: general.site.name)
        rootElement.addChild(extsElement)
        extsElement.addChild(extElement)
        extElement.addChild(nameElement)
        extElement.addChild(valueElement)
        let xml = XMLDocument(rootElement: rootElement).xmlData
        try await Self.updateOne(id: id, xml: xml)
    }
    
} // MobileEndpoint
