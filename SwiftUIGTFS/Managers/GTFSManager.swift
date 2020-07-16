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
    
    @Published var isFinishedLoading = false
    @Published var isFinishedLoadingRoutes = false
    @Published var isFinishedLoadingTrips = false
    @Published var isFinishedLoadingShapes = false
    @Published var isFinishedLoadingStops = false
    
    private var gtfsLoader : GTFSLoader = SimpleGTFSLoader()
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMbtaData()
    }
    
    func getShapeId(for routeId: String) -> [GTFSShapePoint] {
        guard let firstTrip = tripDictionary[routeId]?.first else { return [] }
        guard let shapeId = firstTrip.shapeId else { return [] }
        return shapeDictionary[shapeId] ?? []
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
        
        gtfsLoader.loadRoutesPublisher(from: routesUrl)
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
        }
        .store(in: &cancellables)
        
        gtfsLoader.loadTripsPublisher(from: tripsUrl)
            .map { (trips) -> ([GTFSTrip], [String: [GTFSTrip]]) in
                let dictionary = Dictionary(grouping: trips, by: { $0.routeId })
                return (trips, dictionary)
        }
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
        }
        .store(in: &cancellables)
        
        gtfsLoader.loadShapesPublisher(from: shapesUrl)
            .map { (shapes, viewport) -> ([GTFSShapePoint], [String: [GTFSShapePoint]], CGRect) in
                let dictionary = Dictionary(grouping: shapes, by: { $0.shapeId })
                return (shapes, dictionary, viewport)
        }
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
        }
        .store(in: &cancellables)
        
        gtfsLoader.loadStopsPublisher(from: stopsUrl)
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
        }
        .store(in: &cancellables)
    }
}
