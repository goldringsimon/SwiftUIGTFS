//
//  ContentViewModel.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/3/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import Combine
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var displayedRoutes: [GTFSRoute] = []
    @Published var selectedRoute: String?
    
    var currentViewport: CGRect { get { gtfsManager.currentViewport } }
    
    private var cancellables = Set<AnyCancellable>()
    private var gtfsManager: GTFSManager
    
    init(gtfsManager: GTFSManager) {
        self.gtfsManager = gtfsManager
        
        gtfsManager.$displayedRoutes
            .assign(to: \.displayedRoutes, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$selectedRoute
            .assign(to: \.selectedRoute, on: self)
            .store(in: &cancellables)
    }
    
    func getUniqueShapesIdsForRoute(for routeId: String) -> [String] {
        return gtfsManager.routeToShapeDictionary[routeId] ?? []
    }
    
    func getShape(shapeId: String) -> [GTFSShapePoint] {
        gtfsManager.shapeDictionary[shapeId] ?? []
    }
    
    func selectRoute(routeId: String?) {
        gtfsManager.selectedRoute = routeId
        //self.gtfsManager.overviewViewport = GTFSShapePoint.getOverviewViewport(for: self.gtfsManager.shapeDictionary[shapeId] ?? [])
    }
}
