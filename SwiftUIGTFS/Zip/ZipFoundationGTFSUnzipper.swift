//
//  ZipFoundationGTFSUnzipper.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/1/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine
import ZIPFoundation

class ZipFoundationGTFSUnzipper: GTFSUnzipper {
    func unzip(gtfsZip: URL) -> Future<UnzippedGTFS, GTFSUnzipError> {
        let fileManager = FileManager()
        do {
            let unzipDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destination = unzipDirectory.appendingPathComponent("gtfs")
            //let destination = unzipDirectory
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
            return unzip(gtfsZip: gtfsZip, destination: destination)
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
            return Future { promise in
                promise(.failure(GTFSUnzipError.zipExtractionError))
            }
        }
    }
    
    func unzip(gtfsZip: URL, destination: URL) -> Future<UnzippedGTFS, GTFSUnzipError> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let fileManager = FileManager()
                    print("isMainThread: \(Thread.isMainThread)")
                    try fileManager.unzipItem(at: gtfsZip, to: destination)
                    print("destination: \(destination)")
                    let routesUrl = destination.appendingPathComponent("routes.txt")
                    let tripsUrl = destination.appendingPathComponent("trips.txt")
                    let shapesUrl = destination.appendingPathComponent("shapes.txt")
                    let stopsUrl = destination.appendingPathComponent("stops.txt")
                    promise(.success(UnzippedGTFS(routesUrl: routesUrl, tripsUrl: tripsUrl, shapesURL: shapesUrl, stopsURL: stopsUrl)))
                } catch {
                    print("Extraction of ZIP archive failed with error:\(error)")
                    promise(.failure(GTFSUnzipError.zipExtractionError))
                }
            }
        }
    }
}
