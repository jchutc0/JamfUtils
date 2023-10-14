//
//  MobileEndpoint.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/14/23.
//

import Foundation

struct MobileEndpoint: JamfGetObject, JamfPutObject {
    
    var id: String { "\(general.id)" }
    var general: General
    var extension_attributes: [Extension]
    
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
    
    static let getAllEndpoint = String("/JSSResource/mobiledevices")
    
    struct Results: Codable { let mobile_device: MobileEndpoint }
    
    static func decodeOneResult(data: Data) throws -> Self {
        do { return (try decodeData(data: data) as Results).mobile_device }
        catch { throw JSSError.decode(parseDecodeError(error)) }
    } // decodeOneResult
    
    static func getSiteXml(site: String) -> Data {
        let rootElement = XMLElement(name: "mobile_device")
        let extsElement = XMLElement(name: "extension_attributes")
        let extElement = XMLElement(name: "extension_attribute")
        let nameElement = XMLElement(name: "name", stringValue: "Jamf Site")
        let valueElement = XMLElement(name: "value", stringValue: site)
        rootElement.addChild(extsElement)
        extsElement.addChild(extElement)
        extElement.addChild(nameElement)
        extElement.addChild(valueElement)
        return XMLDocument(rootElement: rootElement).xmlData
    }
    
} // MobileEndpoint
