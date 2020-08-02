//
//  GTFSInfoViewModel.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/2/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI
import Combine

class GTFSInfoViewModel: ObservableObject {
    @Published var selectedRoute: String = ""
    @Published var routeCount: Int = 0
    @Published var tripCount: Int = 0
    @Published var shapePointCount: Int = 0
    @Published var shapeCount: Int = 0
    @Published var stopCount: Int = 0
    @Published var scale: CGFloat = 0
    @Published var minScale: CGFloat = 0
    @Published var maxScale: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(gtfsManager: GTFSManager) {
        gtfsManager.$selectedRoute
            .replaceNil(with: "")
            .assign(to: \.selectedRoute, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$routes
            .map { $0.count }
            .assign(to: \.routeCount, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$trips
            .map({ $0.count })
            .assign(to: \.tripCount, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$shapes
            .map({ $0.count })
            .assign(to: \.shapePointCount, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$stops
            .map({ $0.count })
            .assign(to: \.stopCount, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$scale
            .assign(to: \.scale, on: self)
            .store(in: &cancellables)
        
        minScale = gtfsManager.minScale
        maxScale = gtfsManager.maxScale
    }
}
