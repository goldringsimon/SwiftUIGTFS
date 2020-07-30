//
//  GetLocationsResponse.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/26/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

extension OpenMobilityAPI {
    
    struct GetLocationsResponse: Decodable {
        let status: String?
        let ts: Int?
        let msg: String?
        let results: GetLocationsResponseResults?
    }
    
    struct GetLocationsResponseResults: Decodable {
        let input: String?
        let locations: [Location]?
    }
    
    struct Location: Decodable, Identifiable, Hashable {
        let id: Int
        let pid: Int
        let t: String
        let n: String
        let lat: Double
        let lng: Double
    }
}
