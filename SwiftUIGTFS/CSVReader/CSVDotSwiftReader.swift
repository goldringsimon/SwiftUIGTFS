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

struct CSVDotSwiftReader: GtfsCSVReader {
    static func routesPublisher(from csvString: String) -> Future<[GTFSRoute], GTFSError> {
        loadEntityPublisher(from: csvString)
    }
    
    static func routesPublisher(from fileUrl: URL) -> Future<[GTFSRoute], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    static func tripsPublisher(from csvString: String) -> Future<[GTFSTrip], GTFSError> {
        loadEntityPublisher(from: csvString)
    }
    
    static func tripsPublisher(from fileUrl: URL) -> Future<[GTFSTrip], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    static func shapesPublisher(from csvString: String) -> Future<[GTFSShapePoint], GTFSError> {
        loadEntityPublisher(from: csvString)
    }
    
    static func shapesPublisher(from fileUrl: URL) -> Future<[GTFSShapePoint], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    static func stopsPublisher(from csvString: String) -> Future<[GTFSStop], GTFSError> {
        loadEntityPublisher(from: csvString)
    }
    
    static func stopsPublisher(from fileUrl: URL) -> Future<[GTFSStop], GTFSError> {
        loadEntityPublisher(from: fileUrl)
    }
    
    static private func loadEntityPublisher<T: Decodable>(from fileUrl: URL) -> Future<[T], GTFSError> {
        guard let fileString = try? String(contentsOf: fileUrl) else {
            return Future { (promise) in
                promise(.failure(.invalidFile(issue: "CSV loader couldn't open URL \(fileUrl)")))
            }
        }
            
        return loadEntityPublisher(from: fileString)
    }
    
    static private func loadEntityPublisher<T: Decodable>(from csvString: String) -> Future<[T], GTFSError> {
        return Future<[T], GTFSError> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                var records = [T]()
                do {
                    let reader = try CSVReader(string: csvString, hasHeaderRow: true)
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
