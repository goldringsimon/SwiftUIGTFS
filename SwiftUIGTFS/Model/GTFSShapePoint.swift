//
//  ShapeManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSShapePoint: Identifiable {
    var id: String { return shapeId}
    let shapeId: String
    let ptLat: Double
    let ptLon: Double
    let ptSequence: Int
    let distTraveled: Float?
}
