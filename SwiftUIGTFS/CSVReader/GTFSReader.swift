//
//  GTFSLoader.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/21/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

protocol GTFSReader {
    func routesPublisher(from fileUrl: URL) -> Future<[GTFSRoute], GTFSError>
    func tripsPublisher(from fileUrl: URL) -> Future<[GTFSTrip], GTFSError>
    func shapesPublisher(from fileUrl: URL) -> Future<[GTFSShapePoint], GTFSError>
    func stopsPublisher(from fileUrl: URL) -> Future<[GTFSStop], GTFSError>
}
