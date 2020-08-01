//
//  GTFSProcessorTests.swift
//  SwiftUIGTFSTests
//
//  Created by Simon Goldring on 7/31/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import XCTest
import Combine
@testable import SwiftUIGTFS

class GTFSProcessorTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    var routes = [GTFSRoute]()
    var trips = [GTFSTrip]()
    var shapes = [GTFSShapePoint]()
    var stops = [GTFSStop]()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let reader: GTFSReader = CSVDotSwiftReader()
        guard let routeUrl = Bundle.main.url(forResource: "mbtaRoutes", withExtension: ".txt") else { return }
        reader.routesPublisher(from: routeUrl)
            .assertNoFailure()
            .sink(receiveValue: { self.routes = $0 })
        .store(in: &cancellables)
        
        guard let tripsUrl = Bundle.main.url(forResource: "mbtaTrips", withExtension: ".txt") else { return }
        reader.tripsPublisher(from: tripsUrl)
            .assertNoFailure()
            .sink(receiveValue: { self.trips = $0 })
        .store(in: &cancellables)
        
        guard let shapesUrl = Bundle.main.url(forResource: "mbtaShapes", withExtension: ".txt") else { return }
        reader.shapesPublisher(from: shapesUrl)
            .assertNoFailure()
            .sink(receiveValue: { self.shapes = $0 })
        .store(in: &cancellables)
        
        guard let stopsUrl = Bundle.main.url(forResource: "mbtaStops", withExtension: ".txt") else { return }
        reader.stopsPublisher(from: stopsUrl)
            .assertNoFailure()
            .sink(receiveValue: { self.stops = $0 })
        .store(in: &cancellables)
        
        while routes.isEmpty || trips.isEmpty || shapes.isEmpty || stops.isEmpty {
            
        }
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            let rawData = GTFSRawData(routes: routes, trips: trips, shapes: shapes, stops: stops)
            
            GTFSProcessor.processGTFSData(rawData: rawData) { (result) in
                switch result {
                    
                case .success(let gtfsData):
                    //print(gtfsData)
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testGTFSUnzipperProcessorIntegration() throws {
        let openMobility: OpenMobilityAPIProtocol = MockOpenMobilityAPI()
        let unzipper: GTFSUnzipper = MockGTFSUnzipper()
        //let localZipUrl = Bundle.main.url(forResource: "mbta gtfs", withExtension: "zip")!
        
        
        openMobility.getLatestFeedVersion(feedId: "")
            .assertNoFailure()
            .mapError { _ in GTFSUnzipError.missingFile(file: "") }
            .flatMap { (url) in
                unzipper.unzip(gtfsZip: url)
            }
            .map({ (unzippedGTFS) -> GTFSRawData in
                
                GTFSRawData(routes: [], trips: [], shapes: [], stops: [])
            })
            .assertNoFailure()
            .mapError { _ in GTFSError.invalidFile(issue: "") }
            .flatMap({ GTFSProcessor.processGTFSData(rawData: $0) })
            .sink(receiveCompletion: { (completion) in
                switch completion {
                    
                case .finished:
                    <#code#>
                case .failure(_):
                    <#code#>
                }
            }) { (gtfsData) in
                print(gtfsData.routeToShapeDictionary.first ?? "Couldn't find routeToShapeDictionary :(")
        }
        .store(in: &cancellables)
    }
}
