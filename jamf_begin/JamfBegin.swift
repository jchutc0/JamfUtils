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
        var credentials: Credentials = {
            do {
                let credentials = try Credentials.getFromDefaults()
                print("Jamf URL: \(credentials.server)")
                print("Jamf Username: \(credentials.username)")
                return credentials
            } catch {
                print("Could not load credentials from defaults.")
                print("Enter the URL of the Jamf server:")
                guard let url = readLine(strippingNewline: true) else {
                    print("The URL is required")
                    exit(1)
                }
                print("Enter the username for the Jamf server:")
                guard let username = readLine(strippingNewline: true) else {
                    print("The URL is required")
                    exit(1)
                }
                let credentials = Credentials(username: username, password: "", server: url)
                Credentials.writeToDefaults(cred: credentials)
                return credentials
            } // do...catch
        }()
        do {
            credentials.password = try Keychain.search(credentials: credentials)
            print("Password of \(credentials.password.count) characters found!")
        } catch {
            print("Could not find the password in the keychain.")
            print("Enter the password for the username:")
            guard let password = getpass("") else {
                print("Password is required")
                exit(1)
            }
            credentials.password = String(cString: password)
            try? Keychain.add(credentials: credentials)
        }

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


