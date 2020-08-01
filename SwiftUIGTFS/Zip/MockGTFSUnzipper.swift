//
//  MockGTFSUnzipper.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/1/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

class MockGTFSUnzipper: GTFSUnzipper {
    
    func unzip(url: URL) -> Future<UnzippedGTFS, GTFSUnzipError> {
        Future { promise in
            guard let routesUrl = Bundle.main.url(forResource: "mbtaRoutes", withExtension: ".txt") else {
                promise(.failure(GTFSUnzipError.missingFile(file: "routes.txt")))
                return
            }
            guard let tripsUrl = Bundle.main.url(forResource: "mbtaTrips", withExtension: ".txt") else {
                promise(.failure(GTFSUnzipError.missingFile(file: "trips.txt")))
                return
            }
            guard let shapesUrl = Bundle.main.url(forResource: "mbtaShapes", withExtension: ".txt") else {
                promise(.failure(GTFSUnzipError.missingFile(file: "shapes.txt")))
                return
            }
            guard let stopsUrl = Bundle.main.url(forResource: "mbtaStops", withExtension: ".txt") else {
                promise(.failure(GTFSUnzipError.missingFile(file: "stops.txt")))
                return
            }
            promise(.success(UnzippedGTFS(routesUrl: routesUrl, tripsUrl: tripsUrl, shapesURL: shapesUrl, stopsURL: stopsUrl)))
        }
    }
}
