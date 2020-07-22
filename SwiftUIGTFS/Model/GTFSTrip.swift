//
//  GTFSTripManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSTrip: Identifiable, Decodable {
    var id: String { return routeId }
    let routeId: String
    let serviceId: String
    let tripId: String
    let tripHeadsign: String?
    let tripShortName: String?
    let directionId: Int?
    let shapeId: String?
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case serviceId = "service_id"
        case tripId = "trip_id"
        case tripHeadsign = "trip_headsign"
        case tripShortName = "trip_short_name"
        case directionId = "direction_id"
        case shapeId = "shape_id"
    }
}
