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

let mbtaGtfsPermalink = "https://cdn.mbta.com/MBTA_GTFS.zip"
let bartGtfsPermalink = "https://www.bart.gov/dev/schedules/google_transit.zip"
let ctaGtfsPermalink = "https://www.transitchicago.com/downloads/sch_data/google_transit.zip"
let ratpGtfsPermalink = "http://dataratp.download.opendatasoft.com/RATP_GTFS_FULL.zip"
let romeGtfsPermalink = "http://dati.muovi.roma.it/gtfs/rome_static_gtfs.zip"

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
    @Published var screen: CGSize = CGSize.zero
    @Published var scale: CGFloat = 1
    let minScale: CGFloat = 0.1
    let maxScale: CGFloat = 10.0
    
    @Published var selectedRoute: String? = nil
    
    private var gtfsLoader : GTFSReader = CSVDotSwiftReader()
    
    private var cancellables = Set<AnyCancellable>()
    
    var downloadDelegate: GTFSDownloadDelegate?
    @Published var amountDownloaded = 0.0
    
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
        Publishers.CombineLatest($overviewViewport, $scale)
            .map { (overview, scale) -> CGRect in
                let transform = CGAffineTransform.init(translationX: overview.midX, y: overview.midY).scaledBy(x: 1/scale, y: 1/scale).translatedBy(x: -overview.midX, y: -overview.midY)
                return overview.applying(transform)
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
    
    func loadRemoteMbtaZippedData() {
        guard let url = URL(string: mbtaGtfsPermalink) else { return }
        loadRemoteZippedData(from: url)
    }
    
    func loadRemoteBartZippedData() {
        guard let url = URL(string: bartGtfsPermalink) else { return }
        loadRemoteZippedData(from: url)
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
            /*var savedURL = documentsURL.appendingPathComponent(fileUrl.lastPathComponent)
            savedURL.deletePathExtension()
            savedURL.appendPathExtension(".zip")*/
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
        
        /*let downloadTask = URLSession.shared.downloadTask(with: url) { [weak self]
            urlOrNil, responseOrNil, errorOrNil in
            // check for and handle errors:
            // * errorOrNil should be nil
            // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
            guard errorOrNil == nil else { return }
            guard let response = responseOrNil as? HTTPURLResponse,
                (200..<299).contains(response.statusCode) else { return }
            
            guard let fileUrl = urlOrNil else { return }
            do {
                let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                /*var savedURL = documentsURL.appendingPathComponent(fileUrl.lastPathComponent)
                savedURL.deletePathExtension()
                savedURL.appendPathExtension(".zip")*/
                let savedURL = documentsURL.appendingPathComponent("gtfs.zip")
                if FileManager.default.fileExists(atPath: savedURL.path) {
                    try FileManager.default.removeItem(at: savedURL)
                }
                try FileManager.default.moveItem(at: fileUrl, to: savedURL)
                self?.loadZippedData(from: savedURL)
            } catch {
                print ("file error: \(error)")
            }
        }
        downloadTask.resume()*/
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
            
            /*let fileManager = FileManager.default
            let unzipDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            try Zip.unzipFile(filePath, destination: unzipDirectory, overwrite: true, password: nil, progress: { (progress) in
                // update progress
                print(progress)
            }) { [weak self] (finishedUrl) in
                finishedUrl.path
                let routesUrl = URL(fileURLWithPath: "routes.txt", relativeTo: finishedUrl)
                let tripsUrl = URL(fileURLWithPath: "trips.txt", relativeTo: finishedUrl)
                let shapesUrl = URL(fileURLWithPath: "shapes.txt", relativeTo: finishedUrl)
                let stopsUrl = URL(fileURLWithPath: "stops.txt", relativeTo: finishedUrl)
                self?.loadGTFSData(routesUrl: routesUrl, tripsUrl: tripsUrl, shapesUrl: shapesUrl, stopsUrl: stopsUrl)
            }*/
            
        }
        catch {
            print("Something went wrong")
            print(error)
        }
    }
    
    func loadMbtaData() {
        loadLocalData(routes: "mbtaRoutes", trips: "mbtaTrips", shapes: "mbtaShapes", stops: "mbtaStops")
    }
    
    func loadCtaData() {
        loadLocalData(routes: "ctaRoutes", trips: "ctaTrips", shapes: "ctaShapes", stops: "ctaStops")
    }
    
    func loadBartData() {
        loadLocalData(routes: "bartRoutes", trips: "bartTrips", shapes: "bartShapes", stops: "bartStops")
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
