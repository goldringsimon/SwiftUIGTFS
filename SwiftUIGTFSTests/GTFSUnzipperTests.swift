//
//  GTFSUnzipperTests.swift
//  SwiftUIGTFSTests
//
//  Created by Simon Goldring on 8/1/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import XCTest
import Combine
@testable import SwiftUIGTFS

class GTFSUnzipperTests: XCTestCase {
    var unzipper: GTFSUnzipper = ZipGTFSUnzipper()
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
        let expectation = XCTestExpectation(description: "Test routes publisher")
        
        self.measure {
            // Put the code you want to measure the time of here.
            unzipper.unzip(gtfsZip: Bundle.main.url(forResource: "mbta gtfs", withExtension: "zip")!)
                .subscribe(on: DispatchQueue.global(qos: .userInitiated))
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error)
                        break
                    }
                }) { (unzippedGTFS) in
                    print("isMainThread after subscribe: \(Thread.isMainThread)")
                    print(unzippedGTFS.routesUrl)
                    expectation.fulfill()
            }
            .store(in: &cancellables)
        }
        wait(for: [expectation], timeout: 100.0)
    }

}
