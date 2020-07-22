//
//  GTFSLoader.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/21/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

enum GTFSError: Error {
    case invalidFile(issue: String)
    case invalidRowFormat(issue: String)
    case missingCSVHeader(issue: String)
    case invalidRegEx(issue: String)
    case missingColumn(issue: String)
}

protocol GTFSLoader {
    func routesPublisher(from fileUrl: URL) -> Future<[GTFSRoute], GTFSError>
    func tripsPublisher(from fileUrl: URL) -> Future<[GTFSTrip], GTFSError>
    func shapesPublisher(from fileUrl: URL) -> Future<[GTFSShapePoint], GTFSError>
    func stopsPublisher(from fileUrl: URL) -> Future<[GTFSStop], GTFSError>
}
