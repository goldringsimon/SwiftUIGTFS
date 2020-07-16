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
    @Published var stops: [GTFSStop] = []
    
    @Published var tripDictionary: [String: [GTFSTrip]] = [:] // key is route Id
    @Published var shapeDictionary: [String: [GTFSShapePoint]] = [:] // key is shape Id
    
    @Published var viewport: CGRect = CGRect.zero
    
    @Published var isFinishedLoading = false
    
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
        loadLocalData(stops: "mbtaStops", routes: "mbtaRoutes", trips: "mbtaTrips", shapes: "mbtaShapes")
    }
    
    private func loadCtaData() {
        loadLocalData(stops: "ctaStops", routes: "ctaRoutes", trips: "ctaTrips", shapes: "ctaShapes")
    }
    
    private func loadLocalData(stops: String, routes: String, trips: String, shapes: String) {
        guard let routesUrl = Bundle.main.url(forResource: routes, withExtension: "txt"),
            let tripsUrl = Bundle.main.url(forResource: trips, withExtension: "txt"),
            let shapesUrl = Bundle.main.url(forResource: shapes, withExtension: "txt"),
            let stopsUrl = Bundle.main.url(forResource: stops, withExtension: "txt") else {
                print("couldn't create an Url for local data")
                return
        }
        
        let tripsPublisher = gtfsLoader.loadTripsPublisher(from: tripsUrl)
            .map { (trips) -> ([GTFSTrip], [String: [GTFSTrip]]) in
                let dictionary = Dictionary(grouping: trips, by: { $0.routeId })
                return (trips, dictionary)
        }
        
        Publishers.Zip4(gtfsLoader.loadRoutesPublisher(from: routesUrl),
                        gtfsLoader.loadShapesPublisher(from: shapesUrl),
                        tripsPublisher,
                        gtfsLoader.loadStopsPublisher(from: stopsUrl))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }) { (routes, shapesArg, tripsArg, stops) in
                self.routes = routes
                let (shapes, viewport) = shapesArg
                let (trips, tripDictionary) = tripsArg
                self.shapeDictionary = shapes
                self.viewport = viewport
                self.trips = trips
                self.tripDictionary = tripDictionary
                self.stops = stops
                self.isFinishedLoading = true
        }
        .store(in: &cancellables)
    }
}
