//
//  GTFSStop.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/13/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSStop: Identifiable {
    var id: String { return stopId }
    let stopId: String
    let stopCode: String?
    let stopName: String?
    //let stopDesc: String
    //let platformCode: String
    //let platformName: String
    let stopLat: Double?
    let stopLon: Double?
    //let zoneId: String
    //let stopAddress: String
    //let stopUrl: String
    //let levelId: String
    //let locationType: String
    //let parentStation: String
    //let wheelchairBoarding: String
    //let municipality: String
    //let onStreet: String
    //let atStreet: String
    //let vehicleType: String
}
