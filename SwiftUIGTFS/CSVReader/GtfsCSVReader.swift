//
//  GTFSLoader.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/21/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

protocol GtfsCSVReader {
    func routesPublisher(from fileUrl: URL) -> Future<[GTFSRoute], GTFSError>
    func tripsPublisher(from fileUrl: URL) -> Future<[GTFSTrip], GTFSError>
    func shapesPublisher(from fileUrl: URL) -> Future<[GTFSShapePoint], GTFSError>
    func stopsPublisher(from fileUrl: URL) -> Future<[GTFSStop], GTFSError>
}

extension GtfsCSVReader {
    func gtfsPublisher(from routesUrl: URL, tripsUrl: URL, shapesUrl: URL, stopsUrl: URL) -> AnyPublisher<GTFSRawData, GTFSError> {
        Publishers.Zip4(
            routesPublisher(from: routesUrl),
            tripsPublisher(from: tripsUrl),
            shapesPublisher(from: shapesUrl),
            stopsPublisher(from: stopsUrl))
        .map({ GTFSRawData(routes: $0, trips: $1, shapes: $2, stops: $3) })
        .eraseToAnyPublisher()
    }
    
    func gtfsPublisher(from rootUrl: URL) -> AnyPublisher<GTFSRawData, GTFSError> {
        gtfsPublisher(from: rootUrl.appendingPathComponent("routes.txt"),
                      tripsUrl: rootUrl.appendingPathComponent("trips.txt"),
                      shapesUrl: rootUrl.appendingPathComponent("shapes.txt"),
                      stopsUrl: rootUrl.appendingPathComponent("stops.txt"))
    }
    
    func gtfsPublisher(from unzippedGtfs: UnzippedGTFS) -> AnyPublisher<GTFSRawData, GTFSError> {
        gtfsPublisher(from: unzippedGtfs.routesUrl, tripsUrl: unzippedGtfs.tripsUrl, shapesUrl: unzippedGtfs.shapesURL, stopsUrl: unzippedGtfs.stopsURL)
    }
}
