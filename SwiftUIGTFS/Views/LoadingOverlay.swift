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
            /*ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    //LoadButton(action: { self.gtfsManager.loadMbtaData() }, label: "Load MBTA data from bundle")
                    /*LoadButton(action: { self.gtfsManager.loadCtaData() }, label: "Load CTA data from bundle")
                    LoadButton(action: { self.gtfsManager.loadBartData() }, label: "Load BART data from bundle")
                    LoadButton(action: { self.gtfsManager.loadLocalBartZippedData() }, label: "Load local BART zipped data")
                    LoadButton(action: { self.gtfsManager.loadRemoteMbtaZippedData() }, label: "Load remote MBTA zipped data")
                    LoadButton(action: { self.gtfsManager.loadRemoteBartZippedData() }, label: "Load remote Bart zipped data")*/
                        LoadButton(action: { self.gtfsManager.loadMbtaData() }, label: "Load MBTA data from bundle")
                        ForEach(gtfsManager.feeds) { feed in
                            LoadButton(action: { self.gtfsManager.loadOpenMobilityFeed(feedId: feed.id) }, label: feed.t)
                        }
                }
            }*/
            NavigationView {
                LocationSubList(gtfsManager: gtfsManager, locations: gtfsManager.locations.filter({ $0.pid == 0 }))
                .navigationBarTitle("", displayMode: .inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            
            NavigationView {
                List {
                    ForEach(gtfsManager.feeds) { feed in
                        Text(feed.t)
                    }
                }
                .navigationBarTitle("Transit Systems", displayMode: .inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            
            VStack {
                HStack {
                    Spacer()
                    VStack {
                        Text("GTFS Viewer")
                            .font(.largeTitle)
                        Text("Created by Simon Goldring")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                Divider()
                Spacer()
                HStack {
                    Text("Downloading: ")
                    .font(Font.subheadline.lowercaseSmallCaps())
                    Spacer()
                    ProgressBar(amount: gtfsManager.amountDownloaded)
                        .frame(height: 15)
                        .padding([.leading, .trailing])
                }
                LoadingRow(description: "Loading routes...", isFinished: gtfsManager.isFinishedLoadingRoutes)
                LoadingRow(description: "Loading trips...", isFinished: gtfsManager.isFinishedLoadingTrips)
                LoadingRow(description: "Loading shapes...", isFinished: gtfsManager.isFinishedLoadingShapes)
                LoadingRow(description: "Loading stops...", isFinished: gtfsManager.isFinishedLoadingStops)
            }//.frame(width: 250)
            .padding()
        }
        //.font(Font.subheadline.lowercaseSmallCaps())
        .frame(minWidth: 768, maxHeight: 600)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding([.top, .bottom], 150)
        .padding([.leading, .trailing], 150)
        .shadow(radius: Constants.cornerRadius)
        .animation(.easeInOut)
    }
}

struct LocationSubList: View {
    var gtfsManager: GTFSManager
    var locations: [OpenMobilityAPI.Location]
    var location: OpenMobilityAPI.Location?
    
    var body: some View {
        List {
            ForEach(locations) { item in
                NavigationLink(destination: LocationSubList(gtfsManager: self.gtfsManager, locations: self.gtfsManager.locations.filter({ $0.pid == item.id }), location: item)) {
                    Text(item.n)
                }
            }
            .navigationBarTitle(getTitle(), displayMode: .inline)
        }
    }
    
    func getTitle() -> Text {
        Text((location?.n ?? "Regions"))
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
        .frame(width: 300)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke())
        .padding(1)
        .padding([.trailing], 12)
    }
}

struct LoadingRow: View {
    var description: String
    var isFinished: Bool
    
    var body: some View {
        HStack {
            Text(description)
            Spacer()
            Image(systemName: "checkmark.circle")
                .opacity(isFinished ? 1 : 0)
                .padding([.leading, .trailing])
        }.font(Font.subheadline.lowercaseSmallCaps())
    }
}

/*struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        LoadingOverlay()
    }
}*/
