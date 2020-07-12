//
//  GTFSRouteManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation

struct GTFSRoute {
    let routeId: String
    let serviceId: String
    let tripId: String
    let tripHeadsign: String
    let directionId: Int // 6
    let shapeId: String // 8
}

class GTFSRouteManager: ObservableObject {
    @Published var routes: [GTFSRoute] = []
    
    init() {
        guard let path = Bundle.main.path(forResource: "mbtaRoutes", ofType: "txt") else {
            return
        }
        loadRoutes(from: path)
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
                let serviceId = splitLine[1]
                let tripId = splitLine[2]
                let tripHeadsign = splitLine[3]
                let directionId = Int(splitLine[5]) ?? 0
                let shapeId = splitLine[7]
                
//                tempTrips.append(GTFSTrip(routeId: routeId, serviceId: serviceId, tripId: tripId, tripHeadsign: tripHeadsign, directionId: directionId, shapeId: shapeId))
            }
            
            DispatchQueue.main.async { [weak self] in
//                self?.trips = tempTrips
            }
        }
    }
}
