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
    
    @Published var trainRoutes: [GTFSRoute] = []
    
    private var gtfsLoader : GTFSLoader = SimpleGTFSLoader()
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCtaData()
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
        let returnValue = routeToShapeDictionary[routeId] ?? []
        print(returnValue)
        return returnValue
    }
    
    private func loadMbtaData() {
        loadLocalData(routes: "mbtaRoutes", trips: "mbtaTrips", shapes: "mbtaShapes", stops: "mbtaStops")
    }
    
    private func loadCtaData() {
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
        $routes
            .receive(on: RunLoop.main)
            .sink { routes in
                self.isFinishedLoadingRoutes = !routes.isEmpty
        }
        .store(in: &cancellables)
        
        $tripDictionary
            .receive(on: RunLoop.main)
            .sink { dict in
                self.isFinishedLoadingTrips = !dict.isEmpty
        }
        .store(in: &cancellables)
        
        $shapes
            .receive(on: RunLoop.main)
            .sink { shapes in
                self.isFinishedLoadingShapes = !shapes.isEmpty
        }
        .store(in: &cancellables)
        
        $stops
            .receive(on: RunLoop.main)
            .sink { stops in
                self.isFinishedLoadingStops = !stops.isEmpty
        }
        .store(in: &cancellables)
        
        Publishers.CombineLatest4($isFinishedLoadingRoutes, $isFinishedLoadingTrips, $isFinishedLoadingShapes, $isFinishedLoadingStops)
            .sink { (isFinishedLoadingRoutes, isFinishedLoadingTrips, isFinishedLoadingShapes, isFinishedLoadingStops) in
                self.isFinishedLoading = isFinishedLoadingRoutes && isFinishedLoadingTrips && isFinishedLoadingShapes && isFinishedLoadingStops
        }
        .store(in: &cancellables)
        
        $routes.map { (routes) -> [GTFSRoute] in
            return routes.filter({
                Int($0.routeType) ?? 4 < 3
            })
        }
        .receive(on: RunLoop.main)
        .assign(to: \.trainRoutes, on: self)
        .store(in: &cancellables)
        
        var loadRoutesPublisher = gtfsLoader.loadRoutesPublisher(from: routesUrl)
        /*.receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { routes in
            self.routes = routes
        }*/
        //.store(in: &cancellables)
        
        var loadTripsPublisher = gtfsLoader.loadTripsPublisher(from: tripsUrl)
            .map { (trips) -> ([GTFSTrip], [String: [GTFSTrip]]) in
                let dictionary = Dictionary(grouping: trips, by: { $0.routeId })
                return (trips, dictionary)
        }
        /*.receive(on: RunLoop.main)
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
        }*/
        //.store(in: &cancellables)
        
        var loadShapesPublisher = gtfsLoader.loadShapesPublisher(from: shapesUrl)
            .map { (shapes, viewport) -> ([GTFSShapePoint], [String: [GTFSShapePoint]], CGRect) in
                let dictionary = Dictionary(grouping: shapes, by: { $0.shapeId })
                return (shapes, dictionary, viewport)
        }
        /*.receive(on: RunLoop.main)
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
        }*/
        //.store(in: &cancellables)
        
        var loadStopsPublisher = gtfsLoader.loadStopsPublisher(from: stopsUrl)
        /*.receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { stops in
            self.stops = stops
        }*/
        //.store(in: &cancellables)
        
        Publishers.Zip4(loadRoutesPublisher, loadTripsPublisher, loadShapesPublisher, loadStopsPublisher)
            .receive(on: RunLoop.main)
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { (routes, tripsArg, shapesArg, stops) in
            self.routes = routes
            
            let (trips, tripDictionary) = tripsArg
            self.trips = trips
            self.tripDictionary = tripDictionary
            
            let (shapes, shapeDictionary, viewport) = shapesArg
            self.shapes = shapes
            self.shapeDictionary = shapeDictionary
            self.viewport = viewport
            
            //Processing work here for now
            for route in routes {
                var shapeIds = Set<String>()
                for trip in self.getAllTrips(for: route.routeId) {
                    guard let shapeId = trip.shapeId else { continue }
                    shapeIds.insert(shapeId)
                }
                self.routeToShapeDictionary[route.routeId] = Array(shapeIds)
            }
            print(self.routeToShapeDictionary)
            
            self.stops = stops
        }
        .store(in: &cancellables)
    }
}
