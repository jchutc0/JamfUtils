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
            try await checkList(list: ComputerListEndpoint.getAll())
            
            // MARK: Mobile Devices
            try await checkList(list: MobileListEndpoint.getAll())
        } catch {
            print(error.localizedDescription)
        }

    } // main
    
    static func checkList(list: [some JamfListEndpoint]) async throws {
        let count = list.count
        print("Found \(count) \(type(of: list).Element.description)")
        for (index, element) in list.enumerated() {
            let item = try await type(of: element).getItem(id: element.id)
            var action = "(correct)"
            if item.siteName != item.extSite {
                action = "(updated)"
                try await item.updateSite()
            } // if site needs updating
            print("\(index)/\(count)\t\(item.id) - \(item.name)\t\(item.siteName) \(action)")
        }
    }
} // JamfSetSite
