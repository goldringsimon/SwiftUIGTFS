//
//  GTFSUnzipper.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/1/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

struct UnzippedGTFS {
    let routesUrl: URL
    let tripsUrl: URL
    let shapesURL: URL
    let stopsURL: URL
}

enum GTFSUnzipError: Error {
    case missingFile(file: String)
    case zipExtractionError
}

protocol GTFSUnzipper {
    func unzip(gtfsZip: URL) -> Future<UnzippedGTFS, GTFSUnzipError>
    func unzip(gtfsZip: URL, destination: URL) -> Future<UnzippedGTFS, GTFSUnzipError>
}
