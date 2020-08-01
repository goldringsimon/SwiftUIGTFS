//
//  OpenMobilityAPI.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/23/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Foundation
import Combine

protocol OpenMobilityAPIProtocol {
    func getFeeds(for location: String?) -> AnyPublisher<[OpenMobilityAPI.Feed], OpenMobilityAPI.OpenMobilityAPIError>
    func getLocations() -> AnyPublisher<[OpenMobilityAPI.Location], OpenMobilityAPI.OpenMobilityAPIError>
    func getLatestFeedVersion(feedId: String) -> AnyPublisher<URL, OpenMobilityAPI.OpenMobilityAPIError>
}

class OpenMobilityAPI: OpenMobilityAPIProtocol {
    enum Endpoint: String {
        case getLocations
        case getFeeds
        case getLatestFeedVersion
    }
    
    enum OpenMobilityAPIError: Error {
        case invalidURL
        case invalidResponse
        case parseError
        case decodingError(error: Error)
        case unknownError(error: Error)
    }
    
    static private let apiKey = "54f523ad-4cb1-4143-8168-cfae024ac0ec"
    
    private func makeUrl(endpoint: Endpoint, queryItems: [URLQueryItem] = []) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.transitfeeds.com"
        urlComponents.path = "/v1/\(endpoint)"
        urlComponents.queryItems = [URLQueryItem(name: "key", value: OpenMobilityAPI.apiKey)]
        urlComponents.queryItems?.append(contentsOf: queryItems)
        return urlComponents.url
    }
    
    func getFeeds(for location: String? = nil) -> AnyPublisher<[Feed], OpenMobilityAPI.OpenMobilityAPIError> {
        var queryItems = [URLQueryItem(name: "type", value: "gtfs")]
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
            
        guard let url = makeUrl(endpoint: .getFeeds, queryItems: queryItems) else {
            return Fail(error: .invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let response = response as? HTTPURLResponse,
                    response.statusCode == 200 else {
                        throw OpenMobilityAPIError.invalidResponse
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
                    return OpenMobilityAPIError.decodingError(error: error)
                case let error as OpenMobilityAPIError:
                    return error
                default:
                    return .unknownError(error: error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getLocations() -> AnyPublisher<[Location], OpenMobilityAPI.OpenMobilityAPIError> {
        guard let url = makeUrl(endpoint: .getLocations) else {
            return Fail(error: .invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
        .tryMap { data, response in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200 else {
                    throw OpenMobilityAPIError.invalidResponse
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
                return .decodingError(error: error)
            case let error as OpenMobilityAPIError:
                return error
            default:
                return .unknownError(error: error)
            }
        })
        .eraseToAnyPublisher()
    }
    
    func getLatestFeedVersion(feedId: String) -> AnyPublisher<URL, OpenMobilityAPI.OpenMobilityAPIError> {
        guard let url = makeUrl(endpoint: .getLatestFeedVersion, queryItems: [URLQueryItem(name: "feed", value: feedId)]) else {
            return Fail(error: .invalidURL)
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
                case let error as OpenMobilityAPIError:
                    return error
                default:
                    return .unknownError(error: error)
                }
            })
            .eraseToAnyPublisher()
    }
}
