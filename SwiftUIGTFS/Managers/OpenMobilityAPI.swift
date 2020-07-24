//
//  OpenMobilityAPI.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/23/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

class OpenMobilityAPI {
    
    struct GetFeedsResponse: Decodable {
        let status: String?
        let ts: Int
        let msg: String?
        let results: GetFeedsResponseResults
    }
    
    struct GetFeedsResponseResults: Decodable {
        let input: String?
        let total: Int?
        let limit: Int?
        let page: Int?
        let numPages: Int?
        let feeds: [Feed]?
    }
    
    struct Feed: Decodable, Identifiable {
        let id: String
        let ty: String
        let t: String
        let l: Location
    }
    
    struct Location: Decodable, Identifiable {
        let id: Int
        let pid: Int
        let t: String
        let n: String
        let lat: Double
        let lng: Double
    }
    
    struct GetLocationsResponse: Decodable {
        let status: String?
        let ts: Int?
        let msg: String?
        let results: GetLocationsResponseResults?
    }
    
    struct GetLocationsResponseResults: Decodable {
        let input: String?
        let locations: [Location]?
    }
    
    enum Endpoint: String {
        case getLocations
        case getFeeds
        case getLatestFeedVersion
    }
    
    private func makeUrl(endpoint: Endpoint, queryItems: URLQueryItem...) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.transitfeeds.com"
        urlComponents.path = "/v1/\(endpoint)"
        urlComponents.queryItems = [URLQueryItem(name: "key", value: "54f523ad-4cb1-4143-8168-cfae024ac0ec")]
        urlComponents.queryItems?.append(contentsOf: queryItems)
        return urlComponents.url
    }
    
    func getFeeds(for location: String? = nil) -> AnyPublisher<[Feed], GTFSError> {
        var url: URL?
        if let location = location {
            url = makeUrl(endpoint: .getFeeds, queryItems: URLQueryItem(name: "location", value: location))
        } else {
            url = makeUrl(endpoint: .getFeeds)
        }
            
        guard let finalUrl = url else {
            return Fail(error: GTFSError.openMobilityApiError(issue: "Couldn't make URL in getFeeds"))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: finalUrl)
            .tryMap { data, response in
                guard let response = response as? HTTPURLResponse,
                    response.statusCode == 200 else {
                        throw GTFSError.openMobilityApiError(issue: "Invalid response from OpenMobilityAPI")
                }
                return data
            }
            .decode(type: GetFeedsResponse.self, decoder: JSONDecoder())
            .tryMap({ feedsResponse -> [Feed] in
                guard let locations = feedsResponse.results.feeds else {
                    throw GTFSError.openMobilityApiError(issue: "Couldn't parse GetFeedsLocations")
                }
                return locations
            })
            .mapError({ error in
                switch error {
                case is Swift.DecodingError:
                    return .openMobilityApiError(issue: "Decoding error: \(error)")
                case let error as GTFSError:
                    return error
                default:
                    return GTFSError.openMobilityApiError(issue: "Unknown error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getLocations() -> AnyPublisher<[Location], GTFSError> {
        guard let url = makeUrl(endpoint: .getLocations) else {
            return Fail(error: GTFSError.openMobilityApiError(issue: "Couldn't make URL in getFeeds"))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
        .tryMap { data, response in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    throw GTFSError.openMobilityApiError(issue: "Invalid response from OpenMobilityAPI")
            }
            return data
        }
        .decode(type: GetLocationsResponse.self, decoder: JSONDecoder())
        .tryMap({ locationsResponse -> [Location] in
            guard let locations = locationsResponse.results?.locations else {
                throw GTFSError.openMobilityApiError(issue: "Couldn't parse GetLocations")
            }
            return locations
        })
        .mapError({ error in
            switch error {
            case is Swift.DecodingError:
                return .openMobilityApiError(issue: "Decoding error: \(error)")
            case let error as GTFSError:
                return error
            default:
                return GTFSError.openMobilityApiError(issue: "Unknown error: \(error)")
            }
        })
        .eraseToAnyPublisher()
    }
    
    func getLatestFeedVersion(feedId: String) -> AnyPublisher<URL, GTFSError> {
        guard let url = makeUrl(endpoint: .getLatestFeedVersion, queryItems: URLQueryItem(name: "feed", value: feedId)) else {
            return Fail(error: GTFSError.invalidFile(issue: "test"))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw GTFSError.openMobilityApiError(issue: "Invalid response from OpenMobilityAPI: \(response)")
                }
                
                guard let newUrl: URL = httpResponse.url else {
                    throw GTFSError.openMobilityApiError(issue: "Couldn't make URL for OpenMobilityAPI")
                }
                return newUrl
            }
            .mapError({ error in
                switch error {
                case let error as GTFSError:
                    return error
                default:
                    return GTFSError.openMobilityApiError(issue: "Unknown error: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
