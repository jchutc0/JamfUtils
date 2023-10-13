//
//  CategoryEndpoint.swift
//  jamf_begin
//
//  Created by jchutc0 on 10/13/23.
//

import Foundation

struct CategoryEndpoint: JamfGetObject {
    var id: String
    var name: String
    var priority: Int

    static let getAllEndpoint = String("/api/v1/categories")
}
