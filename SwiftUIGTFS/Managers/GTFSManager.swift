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
    
    @Published var tripDictionary: [String: [GTFSTrip]] = [:] // key is routeId, value is all trips for that route
    @Published var shapeDictionary: [String: [GTFSShapePoint]] = [:] // key is shape Id, value is ShapePoints that make up that shape
    @Published var routeToShapeDictionary: [String: [String]] = [:] // key is routeId, value is all unique shapeIds for that route
    
    @Published var isFinishedLoading = false
    @Published var isFinishedLoadingRoutes = false
    @Published var isFinishedLoadingTrips = false
    @Published var isFinishedLoadingShapes = false
    @Published var isFinishedLoadingStops = false
    @Published var isFinishedProcessingRouteToShapeDictionary = false
    
    // This array of arrays used to 4x e.g. @Published var displayedTrams: [GTFSRoute] = []
    // I'd like to also replace the the 4x @Published var displayTrams = false etc with an array of @Published booleans
    @Published var displayedRoutesByType: [[GTFSRoute]] = Array(repeating: [], count: GTFSRouteType.allCases.count)
    @Published var displayedRoutes: [GTFSRoute] = [] // Combine, um, combines the array of arrays into this for display by the main View
    @Published var displayTrams = false
    @Published var displayMetro = false
    @Published var displayRail = false
    @Published var displayBuses = false
    
    @Published var overviewViewport: CGRect = CGRect.zero
    @Published var currentViewport: CGRect = CGRect.zero
    @Published var scale: CGFloat = 1
    let minScale: CGFloat = 0.1
    let maxScale: CGFloat = 10.0
    
    private var gtfsLoader : GTFSLoader = SimpleGTFSLoader()
    
    private var cancellables = Set<AnyCancellable>()
    
    static var createRouteToShapeDictionary: ([GTFSRoute], [String: [GTFSTrip]]) -> [String: [String]] = {
        (routes, tripDictionary) in
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
    
    init() {
        Publishers.Zip($overviewViewport, $scale)
            .map { (overview, scale) -> CGRect in
                return overview.applying(CGAffineTransform.init(scaleX: scale, y: scale))
        }
        .assign(to: \.currentViewport, on: self)
        .store(in: &cancellables)
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
        
        // This is not ideal. I wish I could replace these four variables with an array of Published<Bool>
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
            .receive(on: DispatchQueue.main)
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
        .receive(on: DispatchQueue.main)
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
        .receive(on: DispatchQueue.main)
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
            self.overviewViewport = viewport
            self.isFinishedLoadingShapes = true
        }
        .store(in: &cancellables)
        
        let loadStopsPublisher = gtfsLoader.loadStopsPublisher(from: stopsUrl)
        
        loadStopsPublisher
        .receive(on: DispatchQueue.main)
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
        
        Publishers.Zip(loadRoutesPublisher, loadTripsPublisher)
            .map({ (routes, tripsArg) -> ([GTFSRoute], [String: [GTFSTrip]]) in
                let (_, tripDictionary) = tripsArg
                return (routes, tripDictionary)
            })
            .map(GTFSManager.createRouteToShapeDictionary)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { (routeToShapeDictionary) in
                self.routeToShapeDictionary = routeToShapeDictionary
                self.isFinishedProcessingRouteToShapeDictionary = true
            })
            .store(in: &cancellables)
        
        Publishers.Zip4($isFinishedLoadingRoutes, $isFinishedLoadingStops, $isFinishedLoadingShapes, $isFinishedLoadingStops)
            .map({ (a, b, c, d) -> Bool in
                return a && b && c && d
            })
            .zip($isFinishedProcessingRouteToShapeDictionary)
            .map({ (a, b) -> Bool in
                return a && b
            })
            .assign(to: \.isFinishedLoading, on: self)
            .store(in: &cancellables)
    }
}
