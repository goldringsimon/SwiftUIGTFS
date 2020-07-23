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
            VStack(alignment: .leading, spacing: 0) {
                LoadButton(action: { self.gtfsManager.loadMbtaData() }, label: "Load MBTA data from bundle")
                LoadButton(action: { self.gtfsManager.loadCtaData() }, label: "Load CTA data from bundle")
                LoadButton(action: { self.gtfsManager.loadBartData() }, label: "Load BART data from bundle")
                LoadButton(action: { self.gtfsManager.loadLocalBartZippedData() }, label: "Load local BART zipped data")
                LoadButton(action: { self.gtfsManager.loadRemoteMbtaZippedData() }, label: "Load remote MBTA zipped data")
                LoadButton(action: { self.gtfsManager.loadRemoteBartZippedData() }, label: "Load remote Bart zipped data")
            }
            VStack {
                HStack {
                    Text("Downloading: ")
                    Spacer()
                    ProgressBar(amount: gtfsManager.amountDownloaded)
                        .frame(height: 15)
                        .padding([.trailing])
                }
                LoadingRow(description: "Loading routes...", isFinished: $gtfsManager.isFinishedLoadingRoutes)
                LoadingRow(description: "Loading trips...", isFinished: $gtfsManager.isFinishedLoadingTrips)
                LoadingRow(description: "Loading shapes...", isFinished: $gtfsManager.isFinishedLoadingShapes)
                LoadingRow(description: "Loading stops...", isFinished: $gtfsManager.isFinishedLoadingStops)
            }
        }
        .font(Font.subheadline.lowercaseSmallCaps())
        .modifier(UICard())
        .frame(width: 700)
        .animation(.easeInOut)
    }
}

struct ProgressBar: View {
    var amount: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .foregroundColor(Color(.tertiarySystemBackground))
                
                Rectangle()
                    .frame(width: geometry.size.width * CGFloat(self.amount), height: geometry.size.height)
                    .foregroundColor(Color(.systemFill))
            }
        }
    }
}

struct LoadButton: View {
    var action: () -> Void
    var label: String
    
    var body: some View {
        Button(action: action) {
            Text(label)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke())
        .padding(1)
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
