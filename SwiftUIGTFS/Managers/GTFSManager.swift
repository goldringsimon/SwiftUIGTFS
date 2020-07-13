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
    @Published var shapes: [String: [GTFSShapePoint]] = [:]
    @Published var stops: [GTFSStop] = []
    
    @Published var viewport: CGRect = CGRect.zero
    
    
    init() {
        loadMbtaData()
    }
    
    private func loadMbtaData() {
        guard let routesPath = Bundle.main.path(forResource: "mbtaRoutes", ofType: "txt"),
            let tripsPath = Bundle.main.path(forResource: "mbtaTrips", ofType: "txt"),
            let shapesPath = Bundle.main.path(forResource: "mbtaShapes", ofType: "txt"),
            let stopsPath = Bundle.main.path(forResource: "mbtaStops", ofType: "txt") else {
            return
        }
        loadRoutes(from: routesPath)
        loadTrips(from: tripsPath)
        loadShapes(from: shapesPath)
        loadStops(from: stopsPath)
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
                guard splitLine.count > 11 else { break }
                
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
            
            var minLat: Double?
            var maxLat: Double?
            var minLon: Double?
            var maxLon: Double?
            
            for i in 1..<limit { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                guard splitLine.count > 4 else { break }
                
                let id = splitLine[0]
                guard let ptLat = Double(splitLine[1]) else { break }
                guard let ptLon = Double(splitLine[2]) else { break }
                guard let ptSequence = Int(splitLine[3]) else { break }
                let distTraveled = Float(splitLine[4])
                shapeEntries.append(GTFSShapeEntry(id: id, ptLat: ptLat, ptLon: ptLon, ptSequence: ptSequence, distTraveled: distTraveled))
                
                if minLat == nil || ptLat < minLat! { minLat = ptLat }
                if maxLat == nil || ptLat > maxLat! { maxLat = ptLat }
                if minLon == nil || ptLon < minLon! { minLon = ptLon }
                if maxLon == nil || ptLon > maxLon! { maxLon = ptLon }
            }
            
            var shapes = [String: [GTFSShapePoint]]()
            
            for entry in shapeEntries {
                if let _ = shapes[entry.id] {
                    shapes[entry.id]?.append(GTFSShapePoint(from: entry))
                } else {
                    shapes[entry.id] = [GTFSShapePoint(from: entry)]
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let minLat = minLat,
                    let maxLat = maxLat,
                    let minLon = minLon,
                    let maxLon = maxLon else { return }
                
                self?.viewport = CGRect(x: minLon, y: minLat, width: maxLon - minLon, height: maxLat - minLat)
                self?.shapes = shapes
            }
        }
    }
    
    func loadStops(from filename:String) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOfFile: filename) else {
                print("couldn't read fileString")
                return
            }
            let fileLines = fileString.components(separatedBy: "\n")
            let limit = fileLines.count
            var stops = [GTFSStop]()
            
            for i in 1..<limit { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                guard splitLine.count > 7 else { break }
                
                let stopId = splitLine[0]
                let stopCode = splitLine[1]
                let stopName = splitLine[2]
                let stopLat = Double(splitLine[6]) ?? 0.0
                let stopLon = Double(splitLine[7]) ?? 0.0
                
                stops.append(GTFSStop(stopId: stopId, stopCode: stopCode, stopName: stopName, stopLat: stopLat, stopLon: stopLon))
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.stops = stops
            }
        }
    }
}
