//
//  GTFSProcessor.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/30/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSRawData {
    let routes: [GTFSRoute]
    let trips: [GTFSTrip]
    let shapes: [GTFSShapePoint]
    let stops: [GTFSStop]
}

struct GTFSData {
    let tripDictionary: [String: [GTFSTrip]]// key is routeId, value is all trips for that route
    let shapeDictionary: [String: [GTFSShapePoint]] // key is shape Id, value is ShapePoints that make up that shape
    let routeToShapeDictionary: [String: [String]] // key is routeId, value is all unique shapeIds for that route
}

class GTFSProcessor {
    static func processGTFSData(rawData: GTFSRawData, completed: @escaping (Result<GTFSData, GTFSError>) -> Void) {
        let tripDictionary = createTripDictionary(trips: rawData.trips)
        let shapeDictionary = createShapeDictionary(shapes: rawData.shapes)
        let routeToShapeDictionary = createRouteToShapeDictionary(routes: rawData.routes, tripDictionary: tripDictionary)
        completed(.success(GTFSData(tripDictionary: tripDictionary, shapeDictionary: shapeDictionary, routeToShapeDictionary: routeToShapeDictionary)))
    }
    
    static func createTripDictionary(trips: [GTFSTrip]) -> [String: [GTFSTrip]] {
        return Dictionary(grouping: trips, by: { $0.routeId })
    }
    
    static func createShapeDictionary(shapes: [GTFSShapePoint]) -> [String: [GTFSShapePoint]] {
        return Dictionary(grouping: shapes, by: { $0.shapeId })
    }
    
    static func createRouteToShapeDictionary(routes: [GTFSRoute], tripDictionary: [String: [GTFSTrip]]) -> [String: [String]] {
        var routeToShapeDictionary: [String: [String]] = [:]
        
        for route in routes {
            var shapeIds = Set<String>()
            if let routeTrips = tripDictionary[route.routeId] {
                for trip in routeTrips {
                    guard let shapeId = trip.shapeId else { continue }
                    shapeIds.insert(shapeId)
                }
            }
            routeToShapeDictionary[route.routeId] = Array(shapeIds)
        }
        return routeToShapeDictionary
    }
}
