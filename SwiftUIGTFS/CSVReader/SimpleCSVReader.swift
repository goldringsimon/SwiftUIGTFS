//
//  SimpleGTFSLoader.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/16/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI
import Combine

class SimpleCSVReader: GtfsCSVReader {
        
    private static let csvRegEx = """
(?:,|\n|^)("(?:(?:"")*[^"]*)*"|[^",\n]*|(?:\n|$))
"""
    
    static func routesPublisher(from fileUrl: URL) -> Future<[GTFSRoute], GTFSError> {
        return Future<[GTFSRoute], GTFSError> { promise in
            return self.loadRoutes(from: fileUrl) { (result) in
                promise(result)
            }
        }
    }
    
    static func tripsPublisher(from fileUrl: URL) -> Future<[GTFSTrip], GTFSError> {
        return Future<[GTFSTrip], GTFSError> { promise in
            return self.loadTrips(from: fileUrl) { (result) in
                promise(result)
            }
        }
    }
    
    static func shapesPublisher(from fileUrl: URL) -> Future<[GTFSShapePoint], GTFSError> {
        return Future<[GTFSShapePoint], GTFSError> { promise in
            return self.loadShapes(from: fileUrl) { (result) in
                promise(result)
            }
        }
    }
    
    static func stopsPublisher(from fileUrl: URL) -> Future<[GTFSStop], GTFSError> {
        return Future<[GTFSStop], GTFSError> { promise in
            return self.loadStops(from: fileUrl) { (result) in
                promise(result)
            }
        }
    }
    
    static private func loadRoutes(from fileUrl: URL, completed: @escaping (Result<[GTFSRoute], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOf: fileUrl) else {
                completed(.failure(.invalidFile(issue: "Couldn't read routes.txt as string")))
                return
            }
            
            let fileLines = fileString.components(separatedBy: "\n")
            guard let headerLine = fileLines.first else {
                completed(.failure(.missingCSVHeader(issue: "Missing header row in routes.txt")))
                return
            }
            
            guard let regex = try? NSRegularExpression(pattern: SimpleCSVReader.csvRegEx, options: []) else {
                print("failed creating regex")
                completed(.failure(.invalidRegEx(issue: "Couldn't init RegEx for routes.txt")))
                return
            }
            let range = NSRange(headerLine.startIndex..<headerLine.endIndex, in: headerLine)
            let colTitles = regex.matches(in: headerLine, options: [], range: range).map { (result) -> String in
                return String(headerLine[Range(result.range(at: 1), in: headerLine)!])
            }
            
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
                completed(.failure(.missingColumn(issue: "Missing route_id column in routes.txt")))
                return
            }
            
            guard let routeTypeColumn = routeTypeCol else {
                completed(.failure(.missingColumn(issue: "Missing route_type column in routes.txt")))
                return
            }
            
            if routeShortNameCol == nil && routeLongNameCol == nil {
                completed(.failure(.missingColumn(issue: "routes.txt must contain at least one of route_short_name and route_long_name")))
                return
            }
            
            var routes = [GTFSRoute]()
            
            for i in 1..<fileLines.count { // Don't want first (header) line
                let currentLine = fileLines[i]
                let range = NSRange(currentLine.startIndex..<fileLines[i].endIndex, in: currentLine)
                let splitLine = regex.matches(in: currentLine, options: [], range: range).map { (result) -> String in
                    return String(currentLine[Range(result.range(at: 1), in: currentLine)!])
                }
                guard splitLine.count == colTitles.count else {
                    print("This route line didn't have the same number of columns as the header row:")
                    print(fileLines[i])
                    continue
                }
                
                guard let routeType = Int(splitLine[routeTypeColumn]) else { // GTFS required field, non-optional
                    completed(.failure(.invalidRowFormat(issue: "route_type wasn't an Int value")))
                    return
                }
                
                let routeId = splitLine[routeIdColumn] // GTFS required field, non-optional
                let agencyId = agencyIdCol == nil ? nil : splitLine[agencyIdCol!]
                let routeShortName = routeShortNameCol == nil ? nil : splitLine[routeShortNameCol!]
                let routeLongName = routeLongNameCol == nil ? nil : splitLine[routeLongNameCol!]
                let routeDesc = routeDescCol == nil ? nil : splitLine[routeDescCol!]
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
    
    static private func loadTrips(from fileUrl: URL, completed: @escaping (Result<[GTFSTrip], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOf: fileUrl) else {
                completed(.failure(.invalidFile(issue: "Couldn't read trips.txt as string")))
                return
            }
            
            let fileLines = fileString.components(separatedBy: "\n")
            guard let headerLine = fileLines.first else {
                completed(.failure(.missingCSVHeader(issue: "Missing header row in trips.txt")))
                return
            }
            
            guard let regex = try? NSRegularExpression(pattern: SimpleCSVReader.csvRegEx, options: []) else {
                print("failed creating regex")
                completed(.failure(.invalidRegEx(issue: "Couldn't init RegEx for trips.txt")))
                return
            }
            let range = NSRange(headerLine.startIndex..<headerLine.endIndex, in: headerLine)
            let colTitles = regex.matches(in: headerLine, options: [], range: range).map { (result) -> String in
                return String(headerLine[Range(result.range(at: 1), in: headerLine)!])
            }
            
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
                completed(.failure(.missingColumn(issue: "Missing route_id column in trips.txt")))
                return
            }
            
            guard let serviceIdColumn = serviceIdCol else {
                completed(.failure(.missingColumn(issue: "Missing service_id column in trips.txt")))
                return
            }
            
            guard let tripIdColumn = tripIdCol else {
                completed(.failure(.missingColumn(issue: "Missing trip_id column in trips.txt")))
                return
            }
            
            var trips = [GTFSTrip]()
            
            for i in 1..<fileLines.count { // Don't want first (header) line
                let currentLine = fileLines[i]
                //let splitLine = currentLine.components(separatedBy: ",")
                let range = NSRange(currentLine.startIndex..<currentLine.endIndex, in: currentLine)
                let splitLine = regex.matches(in: currentLine, options: [], range: range).map { (result) -> String in
                    return String(currentLine[Range(result.range(at: 1), in: currentLine)!])
                }
                guard splitLine.count == colTitles.count else {
                    print("This line didn't have the same number of columns as the header row:")
                    print(fileLines[i])
                    continue
                }
                
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
    
    static private func loadShapes(from fileUrl: URL, completed: @escaping (Result<[GTFSShapePoint], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            var shapePoints: [GTFSShapePoint] = []
            
            guard let fileString = try? String(contentsOf: fileUrl) else {
                completed(.failure(.invalidFile(issue: "Couldn't read shapes.txt as string")))
                return
            }
            
            let fileLines = fileString.components(separatedBy: "\n")
            guard let headerLine = fileLines.first else {
                completed(.failure(.missingCSVHeader(issue: "Missing header row in shapes.txt")))
                return
            }
            guard let regex = try? NSRegularExpression(pattern: SimpleCSVReader.csvRegEx, options: []) else {
                print("failed creating regex")
                completed(.failure(.invalidRegEx(issue: "Couldn't init RegExp for shapes.txt")))
                return
            }
            let range = NSRange(headerLine.startIndex..<headerLine.endIndex, in: headerLine)
            let colTitles = regex.matches(in: headerLine, options: [], range: range).map { (result) -> String in
                return String(headerLine[Range(result.range(at: 1), in: headerLine)!])
            }
            
            var shapeIdCol: Int?
            var shapePtLatCol: Int?
            var shapePtLonCol: Int?
            var shapePtSequenceCol: Int?
            var shapeDistTravelledCol: Int?
            
            for i in 0..<colTitles.count {
                switch colTitles[i] {
                case "shape_id":
                    shapeIdCol = i
                case "shape_pt_lat":
                    shapePtLatCol = i
                case "shape_pt_lon":
                    shapePtLonCol = i
                case "shape_pt_sequence":
                    shapePtSequenceCol = i
                case "shape_dist_travelled":
                    shapeDistTravelledCol = i
                default:
                    break
                }
            }
            
            guard let shapeIdColumn = shapeIdCol else {
                completed(.failure(.missingColumn(issue: "Missing shape_id column in shapes.txt")))
                return
            }
            
            guard let shapePtLatColumn = shapePtLatCol else {
                completed(.failure(.missingColumn(issue: "Missing shape_pt_lat column in shapes.txt")))
                return
            }
            
            guard let shapePtLonColumn = shapePtLonCol else {
                completed(.failure(.missingColumn(issue: "Missing shape_pt_lon column in shapes.txt")))
                return
            }
            
            guard let shapePtSequenceColumn = shapePtSequenceCol else {
                completed(.failure(.missingColumn(issue: "Missing shape_pt_lon column in shapes.txt")))
                return
            }
            
            for i in 1..<fileLines.count { // Don't want first (header) line
                let currentLine = fileLines[i]
                let range = NSRange(currentLine.startIndex..<currentLine.endIndex, in: currentLine)
                let splitLine = regex.matches(in: currentLine, options: [], range: range).map { (result) -> String in
                    return String(currentLine[Range(result.range(at: 1), in: currentLine)!])
                }
                guard splitLine.count == colTitles.count else {
                    print("This shape line didn't have the same number of columns as the header row:")
                    print(fileLines[i])
                    continue
                }
                
                let shapeId = splitLine[shapeIdColumn]
                guard let ptLat = Double(splitLine[shapePtLatColumn]) else { break }
                guard let ptLon = Double(splitLine[shapePtLonColumn]) else { break }
                guard let ptSequence = Int(splitLine[shapePtSequenceColumn]) else { break }
                let distTraveled = shapeDistTravelledCol == nil ? nil : Float(splitLine[shapeDistTravelledCol!])
                shapePoints.append(GTFSShapePoint(shapeId: shapeId, ptLat: ptLat, ptLon: ptLon, ptSequence: ptSequence, distTraveled: distTraveled))
            }
            completed(.success(shapePoints))
        }
    }
    
    static private func loadStops(from fileUrl: URL, completed: @escaping (Result<[GTFSStop], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOf: fileUrl) else {
                completed(.failure(.invalidFile(issue: "Couldn't read stops.txt as string")))
                return
            }
            let fileLines = fileString.components(separatedBy: "\n")
            guard let headerLine = fileLines.first else {
                completed(.failure(.missingCSVHeader(issue: "Missing header row in stops.txt")))
                return
            }
            
            guard let regex = try? NSRegularExpression(pattern: SimpleCSVReader.csvRegEx, options: []) else {
                print("failed creating regex")
                completed(.failure(.invalidRegEx(issue: "Couldn't init RegExp for stops.txt")))
                return
            }
            let range = NSRange(headerLine.startIndex..<headerLine.endIndex, in: headerLine)
            let colTitles = regex.matches(in: headerLine, options: [], range: range).map { (result) -> String in
                return String(headerLine[Range(result.range(at: 1), in: headerLine)!])
            }
            
            var stopIdCol: Int?
            var stopCodeCol: Int?
            var stopNameCol: Int?
            var stopLatCol: Int?
            var stopLonCol: Int?
            
            for i in 0..<colTitles.count {
                switch colTitles[i] {
                case "stop_id":
                    stopIdCol = i
                case "stop_code":
                    stopCodeCol = i
                case "stop_name":
                    stopNameCol = i
                case "stop_lat":
                    stopLatCol = i
                case "stop_lon":
                    stopLonCol = i
                default:
                    break
                }
            }
            
            guard let stopIdColumn = stopIdCol else {
                completed(.failure(.missingColumn(issue: "Missing stop_id column in stops.txt")))
                return
            }
            
            var stops = [GTFSStop]()
            
            for i in 1..<fileLines.count { // Don't want first (header) line
                let currentLine = fileLines[i]
                let range = NSRange(currentLine.startIndex..<currentLine.endIndex, in: currentLine)
                let splitLine = regex.matches(in: currentLine, options: [], range: range).map { (result) -> String in
                    return String(currentLine[Range(result.range(at: 1), in: currentLine)!])
                }
                guard splitLine.count == colTitles.count else {
                    print("This stop line didn't have the same number of columns as the header row:")
                    print(fileLines[i])
                    continue
                }
                
                let stopId = splitLine[stopIdColumn]
                let stopCode = stopCodeCol == nil ? nil : splitLine[stopCodeCol!]
                let stopName = stopNameCol == nil ? nil : splitLine[stopNameCol!]
                let stopLat = stopLatCol == nil ? nil : Double(splitLine[stopLatCol!])
                let stopLon = stopLonCol == nil ? nil : Double(splitLine[stopLonCol!])
                
                let stop = GTFSStop(stopId: stopId, stopCode: stopCode, stopName: stopName, stopLat: stopLat, stopLon: stopLon)
                stops.append(stop)
            }
            
            completed(.success(stops))
        }
    }
}
