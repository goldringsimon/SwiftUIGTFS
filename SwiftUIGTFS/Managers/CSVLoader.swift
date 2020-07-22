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
    func routesPublisher(from fileUrl: URL) -> Future<[GTFSRoute], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    func tripsPublisher(from fileUrl: URL) -> Future<[GTFSTrip], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    func shapesPublisher(from fileUrl: URL) -> Future<[GTFSShapePoint], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    func stopsPublisher(from fileUrl: URL) -> Future<[GTFSStop], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    private func loadEntityPublisher<T: Decodable>(from fileUrl: URL) -> Future<[T], GTFSError> {
        return Future<[T], GTFSError> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let fileString = try? String(contentsOf: fileUrl) else {
                    promise(.failure(.invalidFile(issue: "CSV loader couldn't open URL \(fileUrl)")))
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
                    promise(.failure(.invalidRowFormat(issue: "CSVLoader found invalid row format: \(error)")))
                }
                
                promise(.success(records))
            }
        }
    }
}
