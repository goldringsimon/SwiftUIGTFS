//
//  RouteDisplayView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/2/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

struct RouteDisplayView: View {
    @ObservedObject var viewModel: RouteDisplayViewModel
    @Binding var isDisplayingRouteColors: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $isDisplayingRouteColors.animation()) {
                Text("Display route colours:")
            }
            Divider()
            Toggle(isOn: $viewModel.displayTrams) {
                Text("Display trams:")
            }
            Toggle(isOn: $viewModel.displayMetro) {
                Text("Display metro:")
            }
            Toggle(isOn: $viewModel.displayRail) {
                Text("Display rail:")
            }
            Toggle(isOn: $viewModel.displayBuses) {
                Text("Display buses:")
            }
            Text("# displayed routes: \(viewModel.displayedRoutesCount)")
        }
        .padding()
        .frame(width: 300)
        .modifier(UICard())
    }
}
