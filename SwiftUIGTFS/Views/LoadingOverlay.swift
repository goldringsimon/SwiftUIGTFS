//
//  LoadingOverlay.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/19/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

struct LoadingOverlay: View {
    @ObservedObject var gtfsManager: GTFSManager
    
    var body: some View {
        HStack {
            VStack {
                Button(action: {
                    self.gtfsManager.loadMbtaData()
                }) {
                    Text("Load MBTA data")
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke())
                Button(action: {
                    self.gtfsManager.loadCtaData()
                }) {
                    Text("Load CTA data")
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke())
                Button(action: {
                    self.gtfsManager.loadBartData()
                }) {
                    Text("Load BART data")
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke())
                Button(action: {
                    self.gtfsManager.loadLocalBartZippedData()
                }) {
                    Text("Load local BART zipped data")
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke())
                Button(action: {
                    self.gtfsManager.loadRemoteBartZippedData()
                }) {
                    Text("Load remote BART zipped data")
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke())
            }
            VStack {
                LoadingRow(description: "Loading routes...", isFinished: $gtfsManager.isFinishedLoadingRoutes)
                LoadingRow(description: "Loading trips...", isFinished: $gtfsManager.isFinishedLoadingTrips)
                LoadingRow(description: "Loading shapes...", isFinished: $gtfsManager.isFinishedLoadingShapes)
                LoadingRow(description: "Loading stops...", isFinished: $gtfsManager.isFinishedLoadingStops)
            }
        }
        .font(Font.subheadline.lowercaseSmallCaps())
        .modifier(UICard())
        .frame(width: 600)
        .animation(.easeInOut)
    }
}

struct LoadingRow: View {
    var description: String
    @Binding var isFinished: Bool
    
    var body: some View {
        HStack {
            Text(description)
            Spacer()
            Image(systemName: "checkmark.circle")
                .opacity(isFinished ? 1 : 0)
        }
    }
}

/*struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        LoadingOverlay()
    }
}*/
