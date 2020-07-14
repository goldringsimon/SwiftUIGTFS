//
//  GTFSManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

enum GTFSError: Error {
    case invalidData
}

class GTFSManager: ObservableObject {
    @Published var routes: [GTFSRoute] = []
    @Published var trips: [GTFSTrip] = []
    @Published var shapes: [String: [GTFSShapePoint]] = [:]
    @Published var stops: [GTFSStop] = []
    
    @Published var viewport: CGRect = CGRect.zero
    
    
    init() {
        loadMbtaData()
    }
    
    func getShapeId(for routeId: String) -> [GTFSShapePoint] {
        //let possibleRoutes = routes.filter({ $0.routeId == routeId })
        //guard let route = possibleRoutes.first else { return [] }
        let routeTrips = trips.filter({ $0.routeId == routeId })
        guard let firstTrip = routeTrips.first else { return [] }
        return shapes[firstTrip.shapeId] ?? []
    }
    
    private func loadMbtaData() {
        guard let routesUrl = Bundle.main.url(forResource: "mbtaRoutes", withExtension: "txt"),
            let tripsUrl = Bundle.main.url(forResource: "mbtaTrips", withExtension: "txt"),
            let shapesUrl = Bundle.main.url(forResource: "mbtaShapes", withExtension: "txt"),
            let stopsUrl = Bundle.main.url(forResource: "mbtaStops", withExtension: "txt") else {
                print("couldn't create an Url for MBTA data")
                return
        }
        
        loadRoutes(from: routesUrl) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let routes):
                DispatchQueue.main.async { self.routes = routes }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        loadTrips(from: tripsUrl) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let trips):
                DispatchQueue.main.async { self.trips = trips }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        loadShapes(from: shapesUrl) { [weak self] result in
                   guard let self = self else { return }
                   switch result {
                   case .success(let (shapes, viewport)):
                       DispatchQueue.main.async {
                        self.shapes = shapes
                        self.viewport = viewport
                    }
                   case .failure(let error):
                       print(error.localizedDescription)
                   }
               }
        
        loadStops(from: stopsUrl) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let stops):
                DispatchQueue.main.async { self.stops = stops }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func loadRoutes(from fileUrl: URL, completed: @escaping (Result<[GTFSRoute], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOf: fileUrl) else {
                print("couldn't read fileString")
                return
            }
            let fileLines = fileString.components(separatedBy: "\n")
            let limit = fileLines.count
            var routes = [GTFSRoute]()
            
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
                
                routes.append(GTFSRoute(routeId: routeId, agencyId: agencyId, routeShortName: routeShortName, routeLongName: routeLongName, routeDesc: routeDesc, routeType: routeType, routeUrl: routeUrl, routeColor: routeColor, routeTextColor: routeTextColor, routeSortOrder: routeSortOrder, routeFareClass: routeFareClass, lineId: lineId, listedRoute: listedRoute))
            }
            
            completed(.success(routes))
        }
    }
    
    func loadTrips(from fileUrl: URL, completed: @escaping (Result<[GTFSTrip], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOf: fileUrl) else {
                print("couldn't read fileString")
                return
            }
            let fileLines = fileString.components(separatedBy: "\n")
            let limit = fileLines.count
            var trips = [GTFSTrip]()
            
            for i in 1..<limit { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                guard splitLine.count > 7 else { break }
                
                let routeId = splitLine[0]
                let serviceId = splitLine[1]
                let tripId = splitLine[2]
                let tripHeadsign = splitLine[3]
                let directionId = Int(splitLine[5]) ?? 0
                let shapeId = splitLine[7]
                
                trips.append(GTFSTrip(routeId: routeId, serviceId: serviceId, tripId: tripId, tripHeadsign: tripHeadsign, directionId: directionId, shapeId: shapeId))
            }
            
            completed(.success(trips))
        }
    }
    
    func loadShapes(from fileUrl: URL, completed: @escaping (Result<([String: [GTFSShapePoint]], CGRect), GTFSError>) -> Void) {
        DispatchQueue.global().async {
            var shapeEntries: [GTFSShapeEntry] = []
            
            guard let fileString = try? String(contentsOf: fileUrl) else {
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
            
            /*DispatchQueue.main.async { [weak self] in
                guard let minLat = minLat,
                    let maxLat = maxLat,
                    let minLon = minLon,
                    let maxLon = maxLon else { return }
                
                self?.viewport = CGRect(x: minLon, y: minLat, width: maxLon - minLon, height: maxLat - minLat)
                self?.shapes = shapes
            }*/
            
            guard minLat != nil,
            maxLat != nil,
            minLon != nil,
            maxLon != nil else { return }
            
            let viewport = CGRect(x: minLon!, y: minLat!, width: maxLon! - minLon!, height: maxLat! - minLat!)
            completed(.success((shapes, viewport)))
        }
    }
    
    func loadStops(from fileUrl: URL, completed: @escaping (Result<[GTFSStop], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOf: fileUrl) else {
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
            
            completed(.success(stops))
        }
    }
}
