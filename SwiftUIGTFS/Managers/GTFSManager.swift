//
//  GTFSManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

class GTFSManager: ObservableObject {
    @Published var routes: [GTFSRoute] = []
    @Published var trips: [GTFSTrip] = []
    @Published var shapes: [Int: [GTFSShapePoint]] = [:]
    
    
    init() {
        guard let routesPath = Bundle.main.path(forResource: "mbtaRoutes", ofType: "txt") else {
            return
        }
        loadRoutes(from: routesPath)
        
        guard let tripsPath = Bundle.main.path(forResource: "mbtaTrips", ofType: "txt") else {
            return
        }
        loadTrips(from: tripsPath)
        
        guard let shapesPath = Bundle.main.path(forResource: "mbtaShapes", ofType: "txt") else {
            return
        }
        loadShapes(from: shapesPath)
    }
    
    func loadRoutes(from filename:String) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOfFile: filename) else {
                print("couldn't read fileString")
                return
            }
            let fileLines = fileString.components(separatedBy: "\n")
            let limit = fileLines.count
            var tempRoutes = [GTFSRoute]()
            
            for i in 1..<limit { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                guard splitLine.count > 7 else { break }
                
                let routeId = splitLine[0]
                let agencyId = splitLine[1]
                let routeShortName = splitLine[2]
                let routeLongName = splitLine[3]
                let routeDesc = splitLine[4]
                let routeType = splitLine[5]
                let routeUrl = splitLine[6]
                let routeColor = splitLine[7]
                let routeTextColor = splitLine[8]
                let routeSortOrder = splitLine[9]
                let routeFareClass = splitLine[10]
                let lineId = splitLine[11]
                let listedRoute = splitLine[12]
                
                tempRoutes.append(GTFSRoute(routeId: routeId, agencyId: agencyId, routeShortName: routeShortName, routeLongName: routeLongName, routeDesc: routeDesc, routeType: routeType, routeUrl: routeUrl, routeColor: routeColor, routeTextColor: routeTextColor, routeSortOrder: routeSortOrder, routeFareClass: routeFareClass, lineId: lineId, listedRoute: listedRoute))
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.routes = tempRoutes
                print(self?.routes[5] ?? "")
            }
        }
    }
    
    func loadTrips(from filename:String) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOfFile: filename) else {
                print("couldn't read fileString")
                return
            }
            let fileLines = fileString.components(separatedBy: "\n")
            let limit = fileLines.count
            var tempTrips = [GTFSTrip]()
            
            for i in 1..<limit { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                guard splitLine.count > 7 else { break }
                
                let routeId = splitLine[0]
                let serviceId = splitLine[1]
                let tripId = splitLine[2]
                let tripHeadsign = splitLine[3]
                let directionId = Int(splitLine[5]) ?? 0
                let shapeId = splitLine[7]
                
                tempTrips.append(GTFSTrip(routeId: routeId, serviceId: serviceId, tripId: tripId, tripHeadsign: tripHeadsign, directionId: directionId, shapeId: shapeId))
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.trips = tempTrips
            }
        }
    }
    
    func loadShapes(from filename:String) {
        DispatchQueue.global().async {
            var shapeEntries: [GTFSShapeEntry] = []
            
            guard let fileString = try? String(contentsOfFile: filename) else {
                print("couldn't read fileString")
                return
            }
            let fileLines = fileString.components(separatedBy: "\n")
            let limit = fileLines.count //50000
            for i in 1..<limit { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                
                guard let id = Int(splitLine[0]) else { break }
                guard let ptLat = Double(splitLine[1]) else { break }
                guard let ptLon = Double(splitLine[2]) else { break }
                guard let ptSequence = Int(splitLine[3]) else { break }
                let distTraveled = Float(splitLine[4])
                shapeEntries.append(GTFSShapeEntry(id: id, ptLat: ptLat, ptLon: ptLon, ptSequence: ptSequence, distTraveled: distTraveled))
            }
            
            var shapes = [Int: [GTFSShapePoint]]()
            
            for entry in shapeEntries {
                if let _ = shapes[entry.id] {
                    shapes[entry.id]?.append(GTFSShapePoint(from: entry))
                } else {
                    shapes[entry.id] = [GTFSShapePoint(from: entry)]
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.shapes = shapes
            }
        }
    }
}
