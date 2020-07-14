//
//  GTFSManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

enum GTFSError: Error {
    case invalidRouteData(issue: String)
    case invalidTripData(issue: String)
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
        guard let shapeId = firstTrip.shapeId else { return [] }
        return shapes[shapeId] ?? []
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
            let colTitles = fileLines[0].components(separatedBy: ",")
            
            var routeIdCol: Int?
            var agencyIdCol: Int?
            var routeShortNameCol: Int?
            var routeLongNameCol: Int?
            var routeDescCol: Int?
            var routeTypeCol: Int?
            var routeUrlCol: Int?
            var routeColorCol: Int?
            var routeTextColorCol: Int?
            var routeSortOrderCol: Int?
            var routeFareClassCol: Int?
            var lineIdCol: Int?
            var listedRouteCol: Int?
            
            for i in 0..<colTitles.count {
                switch colTitles[i] {
                case "route_id":
                    routeIdCol = i
                case "agency_id":
                    agencyIdCol = i
                case "route_short_name":
                    routeShortNameCol = i
                case "route_long_name":
                    routeLongNameCol = i
                case "route_desc":
                    routeDescCol = i
                case "route_type":
                    routeTypeCol = i
                case "route_url":
                    routeUrlCol = i
                case "route_color":
                    routeColorCol = i
                case "route_text_color":
                    routeTextColorCol = i
                case "route_sort_order":
                    routeSortOrderCol = i
                case "route_fare_class":
                    routeFareClassCol = i
                case "line_id":
                    lineIdCol = i
                case "listed_route":
                    listedRouteCol = i
                default:
                    break
                }
            }
            
            guard let routeIdColumn = routeIdCol else {
                completed(.failure(.invalidRouteData(issue: "Missing route_id column in routes.txt")))
                return
            }
            
            guard let routeTypeColumn = routeTypeCol else {
                completed(.failure(.invalidRouteData(issue: "Missing route_type column in routes.txt")))
                return
            }
            
            if routeShortNameCol == nil && routeLongNameCol == nil {
                completed(.failure(.invalidRouteData(issue: "routes.txt must contain at least one of route_short_name and route_long_name")))
                return
            }
            
            var routes = [GTFSRoute]()
            
            for i in 1..<fileLines.count { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                guard splitLine.count == colTitles.count else { break }
                
                let routeId = splitLine[routeIdColumn] // GTFS required field, non-optional
                let agencyId = agencyIdCol == nil ? nil : splitLine[agencyIdCol!]
                let routeShortName = routeShortNameCol == nil ? nil : splitLine[routeShortNameCol!]
                let routeLongName = routeLongNameCol == nil ? nil : splitLine[routeLongNameCol!]
                let routeDesc = routeDescCol == nil ? nil : splitLine[routeDescCol!]
                let routeType = splitLine[routeTypeColumn] // GTFS required field, non-optional
                let routeUrl = routeUrlCol == nil ? nil : splitLine[routeUrlCol!]
                let routeColor = routeColorCol == nil ? nil : splitLine[routeColorCol!]
                let routeTextColor = routeTextColorCol == nil ? nil : splitLine[routeTextColorCol!]
                let routeSortOrder = routeSortOrderCol == nil ? nil : splitLine[routeSortOrderCol!]
                let routeFareClass = routeFareClassCol == nil ? nil : splitLine[routeFareClassCol!]
                let lineId = lineIdCol == nil ? nil : splitLine[lineIdCol!]
                let listedRoute = listedRouteCol == nil ? nil : splitLine[listedRouteCol!]
                
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
            let colTitles = fileLines[0].components(separatedBy: ",")
            
            var routeIdCol: Int?
            var serviceIdCol: Int?
            var tripIdCol: Int?
            var tripHeadsignCol: Int?
            var tripShortNameCol: Int?
            var directionIdCol: Int?
            var shapeIdCol: Int?
            
            for i in 0..<colTitles.count {
                switch colTitles[i] {
                case "route_id":
                    routeIdCol = i
                case "service_id":
                    serviceIdCol = i
                case "trip_id":
                    tripIdCol = i
                case "trip_headsign":
                    tripHeadsignCol = i
                case "trip_short_name":
                    tripShortNameCol = i
                case "direction_id":
                    directionIdCol = i
                case "shape_id":
                    shapeIdCol = i
                default:
                    break
                }
            }
            
            guard let routeIdColumn = routeIdCol else {
                completed(.failure(.invalidTripData(issue: "Missing route_id column in trips.txt")))
                return
            }
            
            guard let serviceIdColumn = serviceIdCol else {
                completed(.failure(.invalidTripData(issue: "Missing service_id column in trips.txt")))
                return
            }
            
            guard let tripIdColumn = tripIdCol else {
                completed(.failure(.invalidTripData(issue: "Missing trip_id column in trips.txt")))
                return
            }
                
            let limit = fileLines.count
            var trips = [GTFSTrip]()
            
            for i in 1..<limit { // Don't want first (header) line
                let splitLine = fileLines[i].components(separatedBy: ",")
                guard splitLine.count == colTitles.count else { break }
                
                let routeId = splitLine[routeIdColumn]
                let serviceId = splitLine[serviceIdColumn]
                let tripId = splitLine[tripIdColumn]
                let tripHeadsign = tripHeadsignCol == nil ? nil : splitLine[tripHeadsignCol!]
                let tripShortName = tripShortNameCol == nil ? nil: splitLine[tripShortNameCol!]
                let directionId = directionIdCol == nil ? nil : Int(splitLine[directionIdCol!])
                let shapeId = shapeIdCol == nil ? nil : splitLine[shapeIdCol!]
                
                trips.append(GTFSTrip(routeId: routeId, serviceId: serviceId, tripId: tripId, tripHeadsign: tripHeadsign, tripShortName: tripShortName, directionId: directionId, shapeId: shapeId))
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
