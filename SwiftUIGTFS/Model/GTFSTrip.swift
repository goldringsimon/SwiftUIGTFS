//
//  GTFSTripManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSTrip: Identifiable {
    var id: String { return routeId }
    let routeId: String
    let serviceId: String
    let tripId: String
    let tripHeadsign: String
    let directionId: Int // 6
    let shapeId: String // 8
}
