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
        let unzipper: GTFSUnzipper = ZipGTFSUnzipper()
        let csvReader: GtfsCSVReader = CSVDotSwiftReader()
        //let localZipUrl = Bundle.main.url(forResource: "mbta gtfs", withExtension: "zip")!
        
        let signpostMetric = XCTOSSignpostMetric(subsystem: "com.gtfs.processor", category: "qos-measuring", name: "GTFSProcessor")
        
        measure {
            let expectation = XCTestExpectation(description: "testGTFSUnzipperProcessorIntegration")
            
            openMobility.getLatestFeedVersion(feedId: "")
                .mapError { _ in GTFSUnzipError.missingFile(file: "") }
                .flatMap { unzipper.unzip(gtfsZip: $0) }
                .mapError { _ in GTFSError.invalidFile(issue: "") }
                .flatMap({ csvReader.gtfsPublisher(from: $0) })
                .mapError { _ in GTFSError.invalidFile(issue: "") }
                .flatMap({ GTFSProcessor.processGTFSData(rawData: $0) })
                .sink(receiveCompletion: { (completion) in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error)
                        break
                    }
                }) { (gtfsData) in
                    //print(gtfsData.tripDictionary.first ?? "Couldn't find tripDictionary :(")
                    expectation.fulfill()
            }
            .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
}
