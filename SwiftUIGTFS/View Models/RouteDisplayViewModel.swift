//
//  RouteDisplayViewModel.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/2/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI
import Combine

class RouteDisplayViewModel: ObservableObject {
    @Published var displayTrams: Bool = false
    @Published var displayMetro: Bool = false
    @Published var displayRail: Bool = false
    @Published var displayBuses: Bool = false
    @Published var displayedRoutesCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(gtfsManager: GTFSManager) {
        gtfsManager.$displayTrams
            .assign(to: \.displayTrams, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$displayMetro
            .assign(to: \.displayMetro, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$displayRail
            .assign(to: \.displayRail, on: self)
            .store(in: &cancellables)
        
        gtfsManager.$displayBuses
            .assign(to: \.displayBuses, on: self)
            .store(in: &cancellables)
        
        // This is a place holder to check the toggle value is getting back to the view model.
        // Need to get this back to the model without causing a race condition
        $displayTrams
            .sink { (value) in
                print("displayTrams became \(value) in RouteDisplayViewModel")
            }
            .store(in: &cancellables)
        
        gtfsManager.$displayedRoutes
            .map { $0.count }
            .assign(to: \.displayedRoutesCount, on: self)
            .store(in: &cancellables)
    }
}
