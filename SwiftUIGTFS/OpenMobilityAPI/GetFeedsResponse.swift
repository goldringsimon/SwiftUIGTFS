//
//  GetFeedsResponse.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/26/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

extension OpenMobilityAPI {
    
    struct GetFeedsResponse: Decodable {
        let status: String?
        let ts: Int
        let msg: String?
        let results: GetFeedsResponseResults
    }
    
    struct GetFeedsResponseResults: Decodable {
        let input: String?
        let total: Int?
        let limit: Int?
        let page: Int?
        let numPages: Int?
        let feeds: [Feed]?
    }
    
    struct Feed: Decodable, Identifiable, Hashable {
        let id: String
        let ty: String
        let t: String
        let l: Location
    }
}
