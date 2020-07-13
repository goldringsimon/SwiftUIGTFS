//
//  ShapeManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSShapePoint {
    let ptLat: Double
    let ptLon: Double
    let ptSequence: Int
    let distTraveled: Float?
}

extension GTFSShapePoint {
    init(from entry: GTFSShapeEntry) {
        ptLat = entry.ptLat
        ptLon = entry.ptLon
        ptSequence = entry.ptSequence
        distTraveled = entry.distTraveled
    }
}

struct GTFSShapeEntry: Identifiable {
    let id: String
    let ptLat: Double
    let ptLon: Double
    let ptSequence: Int
    let distTraveled: Float?
}
