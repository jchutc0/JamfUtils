//
//  JamfSetSite.swift
//  jamf_setSite
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

@main
struct JamfSetSite {
    static func main() async {
        print("JamfSetSite")
        let credentials = Credentials.promptForCredentials()
        
        print("Attempting to get an auth token from the Jamf server")
        do {
            try await Auth.getAuth(credentials: credentials)
            print("Got auth token: \(Auth.token ?? "")")
        }
        catch {
            print("Unable to get token!")
            exit(1)
        } // do...catch

        do {
            // MARK: Computers
            let computerList = try await ComputerListEndpoint.getAll()
            let count = computerList.count
            print("Found \(computerList.count) computer objects")
            for (index, element) in computerList.enumerated() {
                let computer = try await ComputerEndpoint.getOne(query: element.id)
                let id = computer.id
                let name = computer.general.name
                let site = computer.general.site.name
                let extSite = computer.extension_attributes.first(where: {$0.name == "Jamf Site"})?.value ?? ""
                var action = "(correct)"
                if site != extSite {
                    action = "(updated)"
                    let xml = ComputerEndpoint.getSiteXml(site: site)
                    try await ComputerEndpoint.updateOne(id: element.id, xml: xml)
                } // if site needs updating
                print("\(index)/\(count)\t\(id) - \(name)\t\(site) \(action)")
            }
            // MARK: Mobile Devices
            let mobileList = try await MobileListEndpoint.getAll()
            let mobileCount = mobileList.count
            print("Found \(mobileCount) mobile objects")
            for (index, element) in mobileList.enumerated() {
                let mobile = try await MobileEndpoint.getOne(query: element.id)
                let id = mobile.id
                let name = mobile.general.name
                let site = mobile.general.site.name
                let extSite = mobile.extension_attributes.first(where: {$0.name == "Jamf Site"})?.value ?? ""
                var action = "(correct)"
                if site != extSite {
                    action = "(updated)"
                    let xml = MobileEndpoint.getSiteXml(site: site)
                    try await MobileEndpoint.updateOne(id: element.id, xml: xml)
                } // if site needs updating
                print("\(index)/\(mobileCount)\t\(id) - \(name)\t\(site) \(action)")
            }
        } catch {
            print(error.localizedDescription)
        }

    } // main
} // JamfSetSite
