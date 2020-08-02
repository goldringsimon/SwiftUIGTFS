//
//  GTFSInfoView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/2/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

struct GTFSInfoView: View {
    @ObservedObject var viewModel: GTFSInfoViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Selected route: \(viewModel.selectedRoute)")
            Text("Route count: \(viewModel.routeCount)")
            Text("Trip count: \(viewModel.tripCount)")
            Text("Shape point count: \(viewModel.shapePointCount)")
            Text("Shape count: \(viewModel.shapeCount)")
            Text("Stop count: \(viewModel.stopCount)")
            Text("Scale: \(viewModel.scale)")
            Slider(value: $viewModel.scale, in: viewModel.minScale...viewModel.maxScale)
        }
        .padding()
        .frame(width: 300)
        .modifier(UICard())
    }
}
