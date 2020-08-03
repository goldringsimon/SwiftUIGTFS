//
//  GTFSManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI
import Combine
import Zip

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
    
    // This array of arrays used to be 4x e.g. @Published var displayedTrams: [GTFSRoute] = []
    // I'd like to also replace the the 4x @Published var displayTrams = false etc with an array of @Published booleans
    @Published var displayedRoutesByType: [[GTFSRoute]] = Array(repeating: [], count: GTFSRouteType.allCases.count)
    @Published var displayedRoutes: [GTFSRoute] = [] // Combine, um, combines the array of arrays into this for display by the main View
    @Published var displayRoute: [Bool] = Array(repeating: false, count: GTFSRouteType.allCases.count)
    @Published var displayTrams = false
    @Published var displayMetro = false
    @Published var displayRail = false
    @Published var displayBuses = false
    
    @Published var overviewViewport: CGRect = CGRect.zero
    @Published var currentViewport: CGRect = CGRect.zero
    @Published var screen: CGSize = CGSize.zero
    @Published var scale: CGFloat = 1
    let minScale: CGFloat = 0.1
    let maxScale: CGFloat = 10.0
    
    @Published var selectedRoute: String? = nil
    
    private var gtfsLoader: GtfsCSVReader = CSVDotSwiftReader()
    
    private var cancellables = Set<AnyCancellable>()
    
    var downloadDelegate: GTFSDownloadDelegate?
    @Published var amountDownloaded = 0.0
    
    private var openMobility = OpenMobilityAPI()
    @Published var locations = [OpenMobilityAPI.Location]()
    var locationCancellable: AnyCancellable?
    @Published var feedsForLocation = [OpenMobilityAPI.Feed]()
    @Published var showFavourites = true
    @Published var selectedLocation = [OpenMobilityAPI.Location?](repeating: nil, count: 5)
    @Published var selectedFeed: OpenMobilityAPI.Feed?
    @Published var favourites = [OpenMobilityAPI.Feed]()
    
    var infoViewModel: GTFSInfoViewModel!
    var routeDisplayViewModel: RouteDisplayViewModel!
    
    private static var createRouteToShapeDictionary: ([GTFSRoute], [String: [GTFSTrip]]) -> [String: [String]] = {
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
        infoViewModel = GTFSInfoViewModel(gtfsManager: self)
        routeDisplayViewModel = RouteDisplayViewModel(gtfsManager: self)
        
        Publishers.CombineLatest($overviewViewport, $scale)
            .map { (overview, scale) -> CGRect in
                let transform = CGAffineTransform.init(translationX: overview.midX, y: overview.midY).scaledBy(x: 1/scale, y: 1/scale).translatedBy(x: -overview.midX, y: -overview.midY)
                return overview.applying(transform)
        }
        .assign(to: \.currentViewport, on: self)
        .store(in: &cancellables)
        
        $selectedLocation
        .removeDuplicates()
            .map({ (selectedLocations) -> [OpenMobilityAPI.Location] in
                selectedLocations.compactMap { $0 }
            })
            .sink { (selectedLocations) in
                self.openedLocationSubList(location: selectedLocations.last)
            }
        .store(in: &cancellables)
        
        openMobility.getLocations()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                    break
                }
            }) { locations in
                self.locations = locations
        }
        .store(in: &cancellables)
    }
    
    func openedLocationSubList(location: OpenMobilityAPI.Location?) {
        if let location = location {
            showFavourites = false
            locationCancellable = openMobility.getFeeds(for: String(location.id))
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { (completion) in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error)
                        break
                    }
                }) { feeds in
                    self.feedsForLocation = feeds
                }
        } else {
            showFavourites = true
        }
    }
    
    func closedLocationSubList(location: OpenMobilityAPI.Location?) {
        if let location = location, location.pid == 0 {
            showFavourites = true
        }
    }
    
    func loadOpenMobilityFeed(feedId: String) {
        openMobility.getLatestFeedVersion(feedId: feedId)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                break
            }
        }, receiveValue: { url in
            self.loadRemoteZippedData(from: url)
        })
        .store(in: &cancellables)
    }
    
    func getUniqueShapesIdsForRoute(for routeId: String) -> [String] {
        return routeToShapeDictionary[routeId] ?? []
    }
    
    func downloadDelegate(amountDownloaded: Double) {
        DispatchQueue.main.async {
            self.amountDownloaded = amountDownloaded
        }
    }
    
    func downloadDelegate(didFinishDownloadingTo location: URL) {
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let savedURL = documentsURL.appendingPathComponent("gtfs.zip")
            if FileManager.default.fileExists(atPath: savedURL.path) {
                try FileManager.default.removeItem(at: savedURL)
            }
            try FileManager.default.moveItem(at: location, to: savedURL)
            loadZippedData(from: savedURL)
        } catch {
            print ("file error: \(error)")
        }
    }
    
    func loadRemoteZippedData(from url: URL) {
        downloadDelegate = GTFSDownloadDelegate(gtfsManager: self)
        let configuration = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        let session = URLSession(configuration: configuration, delegate: downloadDelegate, delegateQueue: operationQueue)
        let downloadTask = session.downloadTask(with: url)
        downloadTask.resume()
    }
    
    func loadLocalBartZippedData() {
        let filePath = Bundle.main.url(forResource: "bart", withExtension: "zip")!
        loadZippedData(from: filePath)
    }
    
    func loadZippedData(from url: URL) {
        do {
            let unzipDirectory = try Zip.quickUnzipFile(url)
            
            let routesUrl = URL(fileURLWithPath: "routes.txt", relativeTo: unzipDirectory)
            let tripsUrl = URL(fileURLWithPath: "trips.txt", relativeTo: unzipDirectory)
            let shapesUrl = URL(fileURLWithPath: "shapes.txt", relativeTo: unzipDirectory)
            let stopsUrl = URL(fileURLWithPath: "stops.txt", relativeTo: unzipDirectory)
            loadGTFSData(routesUrl: routesUrl, tripsUrl: tripsUrl, shapesUrl: shapesUrl, stopsUrl: stopsUrl)
        }
        catch {
            print("Something went wrong")
            print(error)
        }
    }
    
    private func loadGTFSData(routesUrl: URL, tripsUrl: URL, shapesUrl: URL, stopsUrl: URL) {
        let loadRoutesPublisher = gtfsLoader.routesPublisher(from: routesUrl)
        
        // This is not ideal. I wish I could replace these four variables with an array of Published<Bool>
        for (i, publisher) in [$displayTrams, $displayMetro, $displayRail, $displayBuses].enumerated() {
            publisher
            .map({ (display) -> [GTFSRoute] in
                    if display {
                        return self.routes.filter { $0.routeType == i }
                    }
                    return []
                })
            .receive(on: DispatchQueue.main)
            .assign(to: \.displayedRoutesByType[i], on: self)
            .store(in: &cancellables)
        }
            
        $displayedRoutesByType
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
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
                print(error)
            }
        }) { routes in
            self.routes = routes
            self.isFinishedLoadingRoutes = true
        }
        .store(in: &cancellables)
        
        let loadTripsPublisher = gtfsLoader.tripsPublisher(from: tripsUrl)
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
                print(error)
            }
        }) { (trips, tripDictionary) in
            self.trips = trips
            self.tripDictionary = tripDictionary
            self.isFinishedLoadingTrips = true
        }
        .store(in: &cancellables)
        
        let loadShapesPublisher = gtfsLoader.shapesPublisher(from: shapesUrl)
            .map { (shapes) -> ([GTFSShapePoint], [String: [GTFSShapePoint]], CGRect) in
                let dictionary = Dictionary(grouping: shapes, by: { $0.shapeId })
                let viewport = GTFSShapePoint.getOverviewViewport(for: shapes)
                return (shapes, dictionary, viewport)
        }
            
        loadShapesPublisher
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error)
            }
        }) { (shapes, shapeDictionary, viewport) in
            self.shapes = shapes
            self.shapeDictionary = shapeDictionary
            self.overviewViewport = viewport
            self.isFinishedLoadingShapes = true
        }
        .store(in: &cancellables)
        
        let loadStopsPublisher = gtfsLoader.stopsPublisher(from: stopsUrl)
        
        loadStopsPublisher
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error)
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
            .receive(on: DispatchQueue.main)
            .assign(to: \.isFinishedLoading, on: self)
            .store(in: &cancellables)
    }
}
