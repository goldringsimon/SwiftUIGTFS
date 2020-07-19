//
//  GTFSManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI
import Combine

enum GTFSError: Error {
    case invalidRouteData(issue: String)
    case invalidTripData(issue: String)
    case invalidShapeData(issue: String)
    case invalidStopData(issue: String)
}

enum GTFSRouteType: Int, CaseIterable {
    case trams = 0
    case metro = 1
    case rail = 2
    case buses = 3
    
    
}

class GTFSManager: ObservableObject {
    @Published var routes: [GTFSRoute] = []
    @Published var trips: [GTFSTrip] = []
    @Published var shapes: [GTFSShapePoint] = []
    @Published var stops: [GTFSStop] = []
    
    @Published var tripDictionary: [String: [GTFSTrip]] = [:] // key is route Id
    @Published var shapeDictionary: [String: [GTFSShapePoint]] = [:] // key is shape Id
    @Published var viewport: CGRect = CGRect.zero
    @Published var routeToShapeDictionary: [String: [String]] = [:] // key is routeId, value is all unique shapeIds for that route
    
    @Published var isFinishedLoading = false
    @Published var isFinishedLoadingRoutes = false
    @Published var isFinishedLoadingTrips = false
    @Published var isFinishedLoadingShapes = false
    @Published var isFinishedLoadingStops = false
    
    @Published var displayedRoutes: [GTFSRoute] = []
    
    //@Published var displayedTrams: [GTFSRoute] = []
    //@Published var displayedMetro: [GTFSRoute] = []
    //@Published var displayedRail: [GTFSRoute] = []
    //@Published var displayedBuses: [GTFSRoute] = []
    @Published var displayTrams = false
    @Published var displayMetro = false
    @Published var displayRail = false
    @Published var displayBuses = false
    
    var displayRouteType: [Published<Bool>] = []
    @Published var displayedRoutesByType: [[GTFSRoute]] = []
    
    private var gtfsLoader : GTFSLoader = SimpleGTFSLoader()
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        for routeType in GTFSRouteType.allCases {
            displayedRoutesByType.append([])
        }
    }
    
    func getShapeId(for routeId: String) -> [GTFSShapePoint] {
        guard let firstTrip = tripDictionary[routeId]?.first else { return [] }
        guard let shapeId = firstTrip.shapeId else { return [] }
        return shapeDictionary[shapeId] ?? []
    }
    
    func getAllTrips(for routeId: String) -> [GTFSTrip] {
        return tripDictionary[routeId] ?? []
    }
    
    func getAllShapes(for tripId: String) -> [GTFSShapePoint] {
        return shapeDictionary[tripId] ?? []
    }
    
    func getAllShapesForRoute(for routeId: String) -> [GTFSShapePoint] {
        var returnValue = [GTFSShapePoint]()
        for trip in getAllTrips(for: routeId) {
            guard let shapeId = trip.shapeId else { break }
            returnValue += getAllShapes(for: shapeId)
        }
        return returnValue
    }
    
    func getUniqueShapesIdsForRoute(for routeId: String) -> [String] {
        /*var shapeIds = Set<String>()
        for trip in getAllTrips(for: routeId) {
            guard let shapeId = trip.shapeId else { continue }
            shapeIds.insert(shapeId)
        }
        return Array(shapeIds)*/
        return routeToShapeDictionary[routeId] ?? []
    }
    
    func loadMbtaData() {
        loadLocalData(routes: "mbtaRoutes", trips: "mbtaTrips", shapes: "mbtaShapes", stops: "mbtaStops")
    }
    
    func loadCtaData() {
        loadLocalData(routes: "ctaRoutes", trips: "ctaTrips", shapes: "ctaShapes", stops: "ctaStops")
    }
    
    private func loadLocalData(routes: String, trips: String, shapes: String, stops: String) {
        guard let routesUrl = Bundle.main.url(forResource: routes, withExtension: "txt"),
            let tripsUrl = Bundle.main.url(forResource: trips, withExtension: "txt"),
            let shapesUrl = Bundle.main.url(forResource: shapes, withExtension: "txt"),
            let stopsUrl = Bundle.main.url(forResource: stops, withExtension: "txt") else {
                print("couldn't create an Url for local data")
                return
        }
        loadGTFSData(routesUrl: routesUrl, tripsUrl: tripsUrl, shapesUrl: shapesUrl, stopsUrl: stopsUrl)
    }
    
    private func loadGTFSData(routesUrl: URL, tripsUrl: URL, shapesUrl: URL, stopsUrl: URL) {
        let loadRoutesPublisher = gtfsLoader.loadRoutesPublisher(from: routesUrl)
        
        for (i, publisher) in [$displayTrams, $displayMetro, $displayRail, $displayBuses].enumerated() {
            publisher
            .map({ (display) -> [GTFSRoute] in
                    if display {
                        return self.routes.filter { Int($0.routeType) == i }
                    }
                    return []
                })
            .receive(on: DispatchQueue.main)
            .assign(to: \.displayedRoutesByType[i], on: self)
            .store(in: &cancellables)
        }
            
        $displayedRoutesByType
            .map { (routes) -> [GTFSRoute] in
                return routes.flatMap({ $0 })
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.displayedRoutes, on: self)
        .store(in: &cancellables)
        
        loadRoutesPublisher
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { routes in
            self.routes = routes
            self.isFinishedLoadingRoutes = true
        }
        .store(in: &cancellables)
        
        let loadTripsPublisher = gtfsLoader.loadTripsPublisher(from: tripsUrl)
            .map { (trips) -> ([GTFSTrip], [String: [GTFSTrip]]) in
                let dictionary = Dictionary(grouping: trips, by: { $0.routeId })
                return (trips, dictionary)
            }
            
        loadTripsPublisher
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { (trips, tripDictionary) in
            self.trips = trips
            self.tripDictionary = tripDictionary
            self.isFinishedLoadingTrips = true
        }
        .store(in: &cancellables)
        
        let loadShapesPublisher = gtfsLoader.loadShapesPublisher(from: shapesUrl)
            .map { (shapes, viewport) -> ([GTFSShapePoint], [String: [GTFSShapePoint]], CGRect) in
                let dictionary = Dictionary(grouping: shapes, by: { $0.shapeId })
                return (shapes, dictionary, viewport)
        }
            
        loadShapesPublisher
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { (shapes, shapeDictionary, viewport) in
            self.shapes = shapes
            self.shapeDictionary = shapeDictionary
            self.viewport = viewport
            self.isFinishedLoadingShapes = true
        }
        .store(in: &cancellables)
        
        let loadStopsPublisher = gtfsLoader.loadStopsPublisher(from: stopsUrl)
        
        loadStopsPublisher
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { stops in
            self.stops = stops
            self.isFinishedLoadingStops = true
        }
        .store(in: &cancellables)
        
        Publishers.Zip4(loadRoutesPublisher, loadTripsPublisher, loadShapesPublisher, loadStopsPublisher) // TODO only zip necessary publishers for this processing
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { (routes, tripsArg, shapesArg, stops) in
            let (trips, tripDictionary) = tripsArg
            let (shapes, shapeDictionary, viewport) = shapesArg
            
            //Processing work here for now // TODO this is odd to reference properties and methods of self not the closure arguments
            for route in routes {
                var shapeIds = Set<String>()
                for trip in self.getAllTrips(for: route.routeId) {
                    guard let shapeId = trip.shapeId else { continue }
                    shapeIds.insert(shapeId)
                }
                self.routeToShapeDictionary[route.routeId] = Array(shapeIds)
            }
            
            self.isFinishedLoading = true
        }
        .store(in: &cancellables)
    }
}
