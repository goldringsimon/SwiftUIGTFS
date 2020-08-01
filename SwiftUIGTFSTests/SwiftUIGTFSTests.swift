//
//  SwiftUIGTFSTests.swift
//  SwiftUIGTFSTests
//
//  Created by Simon Goldring on 7/30/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import XCTest
import Combine
@testable import SwiftUIGTFS

class SwiftUIGTFSTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

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
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testCSVReaderRoutesPublisher() throws {
        let testRoutesData = """
route_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color
1,YL-S,Antioch to SFIA/Millbrae,,1,http://www.bart.gov/schedules/bylineresults?route=1,FFFF33
2,YL-N,Millbrae/SFIA to Antioch,,1,http://www.bart.gov/schedules/bylineresults?route=2,FFFF33
"""
        let expectation = XCTestExpectation(description: "Test routes publisher")
        measure {
            let csvReader = CSVDotSwiftReader()
            csvReader.routesPublisher(from: testRoutesData).sink(receiveCompletion: { completion in
                switch completion {
                    
                case .finished:
                    break
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }) { routes in
                XCTAssertEqual(routes.count, 2)
                XCTAssertEqual(routes[0].routeId, "1")
                XCTAssertEqual(routes[0].routeShortName, "YL-S")
                XCTAssertEqual(routes[0].routeLongName, "Antioch to SFIA/Millbrae")
                XCTAssertEqual(routes[1].routeId, "2")
                XCTAssertEqual(routes[1].routeShortName, "YL-N")
                XCTAssertEqual(routes[1].routeLongName, "Millbrae/SFIA to Antioch")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
