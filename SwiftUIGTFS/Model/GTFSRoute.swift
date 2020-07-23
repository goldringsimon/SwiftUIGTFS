//
//  GTFSRouteManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSRoute: Identifiable, Decodable {
    var id: String { return routeId }
    let routeId: String
    let agencyId: String?
    let routeShortName: String?
    let routeLongName: String?
    let routeDesc: String?
    let routeType: Int
    let routeUrl: String?
    let routeColor: String?
    let routeTextColor: String?
    let routeSortOrder: String?
    let routeFareClass: String?
    let lineId: String?
    let listedRoute: String?
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case agencyId = "agency_id"
        case routeShortName = "route_short_name"
        case routeLongName = "route_long_name"
        case routeDesc = "route_desc"
        case routeType = "route_type"
        case routeUrl = "route_url"
        case routeColor = "route_color"
        case routeTextColor = "route_text_color"
        case routeSortOrder = "route_sort_order"
        case routeFareClass = "route_fare_class"
        case lineId = "line_id"
        case listedRoute = "listed_route"
    }
}

enum GTFSRouteType: Int, CaseIterable {
    case trams = 0
    case metro = 1
    case rail = 2
    case buses = 3
}
