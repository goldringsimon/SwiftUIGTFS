//
//  CSVLoader.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/22/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine
import CSV

class CSVLoader: GTFSLoader {
    
    func loadRoutesPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSRoute], GTFSError> {
        return Future<[GTFSRoute], GTFSError> { promise in
            return self.loadEntity(from: fileUrl) { (result) in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadTripsPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSTrip], GTFSError> {
        return Future<[GTFSTrip], GTFSError> { promise in
            return self.loadEntity(from: fileUrl) { (result) in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadShapesPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSShapePoint], GTFSError> {
        return Future<[GTFSShapePoint], GTFSError> { promise in
            return self.loadEntity(from: fileUrl) { (result) in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadStopsPublisher(from fileUrl: URL) -> AnyPublisher<[GTFSStop], GTFSError> {
        return Future<[GTFSStop], GTFSError> { promise in
            return self.loadEntity(from: fileUrl) { (result) in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadEntity<T: Decodable>(from fileUrl: URL, completed: @escaping (Result<[T], GTFSError>) -> Void) {
        DispatchQueue.global().async {
            guard let fileString = try? String(contentsOf: fileUrl) else {
                completed(.failure(.invalidRouteData(issue: "CSV loader couldn't open URL \(fileUrl)")))
                return
            }
            
            var records = [T]()
            do {
                let reader = try CSVReader(string: fileString, hasHeaderRow: true)
                let decoder = CSVRowDecoder()
                while reader.next() != nil {
                    
                    let row = try decoder.decode(T.self, from: reader)
                    records.append(row)
                }
            } catch {
                // Invalid row format
                completed(.failure(.invalidRouteData(issue: "CSV issue in CSVLoader: \(error)")))
            }
            completed(.success(records))
        }
    }
}
