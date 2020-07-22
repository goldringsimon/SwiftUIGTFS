//
//  GTFSLoader.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/21/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

protocol GTFSLoader {
    func loadRoutesPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSRoute], GTFSError>
    func loadTripsPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSTrip], GTFSError>
    func loadShapesPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSShapePoint], GTFSError> // TODO move viewport code to manager
    func loadStopsPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSStop], GTFSError>
}
