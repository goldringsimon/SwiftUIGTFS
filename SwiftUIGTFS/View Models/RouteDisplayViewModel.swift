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
    var displayTrams: Bool {
        get { gtfsManager.displayTrams }
        set { gtfsManager.displayTrams = newValue }
    }
    var displayMetro: Bool {
        get { gtfsManager.displayMetro }
        set { gtfsManager.displayMetro = newValue }
    }
    var displayRail: Bool {
        get { gtfsManager.displayRail }
        set { gtfsManager.displayRail = newValue }
    }
    var displayBuses: Bool {
        get { gtfsManager.displayBuses }
        set { gtfsManager.displayBuses = newValue }
    }
    var displayedRoutesCount: Int {
        get { gtfsManager.displayedRoutes.count }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private var gtfsManager: GTFSManager
    
    init(gtfsManager: GTFSManager) {
        self.gtfsManager = gtfsManager
    }
}
