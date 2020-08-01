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
            let routesUrl = Bundle.main.url(forResource: "mbtaRoutes", withExtension: ".txt")!
            let tripsUrl = Bundle.main.url(forResource: "mbtaTrips", withExtension: ".txt")!
            let shapesUrl = Bundle.main.url(forResource: "mbtaShapes", withExtension: ".txt")!
            let stopsUrl = Bundle.main.url(forResource: "mbtaStops", withExtension: ".txt")!
            promise(.success(UnzippedGTFS(routesUrl: routesUrl, tripsUrl: tripsUrl, shapesURL: shapesUrl, stopsURL: stopsUrl)))
        }
    }
}
