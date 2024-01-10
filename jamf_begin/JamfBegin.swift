//
//  JamfBegin.swift
//  jamf_begin
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

@main
struct JamfBegin {
    static func main() async {
        print("JamfUtils")
        let credentials = OAuthCredentials.promptForCredentials()

        print("Attempting to get an auth token from the Jamf server")
        do {
            try await Auth.getAuth(credentials: credentials)
            print("Got auth token: \(Auth.token ?? "")")
        }
        catch {
            print("Unable to get token!")
            exit(1)
        } // do...catch
        
        print("Getting category list")
        do {
            let categories = try await CategoryEndpoint.getAll()
            for category in categories {
                print(
                    category.id,
                    category.name,
                    category.priority
                )
            } // for category
        } catch {
            print("There was an error! \(error.localizedDescription)")
        } // do...catch
    } // main
} // JamfBegin


