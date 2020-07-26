//
//  LoadingOverlay.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/19/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

struct LoadingOverlay: View {
    @EnvironmentObject var gtfsManager: GTFSManager
    
    var body: some View {
        HStack {
            
            LocationsPane()

            FeedsPane()
            
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
                if (gtfsManager.selectedFeed != nil) {
                    VStack {
                        Text(gtfsManager.selectedFeed?.t ?? "")//.animation(nil)
                        .padding([.bottom])
                        LoadButton(action: {
                            
                            }, label: "Load")
                            .padding([.bottom])
                        LoadButton(action: {
                            self.gtfsManager.favourites.append(self.gtfsManager.selectedFeed!)
                        }, label: "Add To Favourites")
                        .padding([.bottom])
                    }.transition(.move(edge: .trailing))
                    
                    VStack {
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
                    }.transition(.move(edge: .bottom))
                }
            }//.frame(width: 250)
            .padding()
        }
        .frame(minWidth: 768, maxHeight: 600)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding([.top, .bottom], 150)
        .padding([.leading, .trailing], 150)
        //.shadow(radius: Constants.cornerRadius)
        //.animation(.easeInOut)
    }
}

struct LocationsPane: View {
    @EnvironmentObject var gtfsManager: GTFSManager
    
    var body: some View {
        NavigationView {
            LocationSubList(locations: gtfsManager.locations.filter({ $0.pid == 0 }), hierarchy: 0)
            .navigationBarTitle("", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FeedsPane: View {
    @EnvironmentObject var gtfsManager: GTFSManager
    
    var body: some View {
        List(selection: $gtfsManager.selectedFeed.animation()) {
            if (gtfsManager.showFavourites) {
                HStack {
                    Spacer()
                    Text("Favourites")
                        .font(.subheadline)
                    Spacer()
                }
                ForEach (gtfsManager.favourites) { feed in
                    Text(feed.t).tag(feed)
                }
            } else {
                ForEach(gtfsManager.feedsForLocation) { feed in
                    Text(feed.t).tag(feed)
                }
            }
        }.environment(\.editMode, .constant(.active))
    }
}

struct LocationSubList: View {
    @EnvironmentObject var gtfsManager: GTFSManager
    var locations: [OpenMobilityAPI.Location]
    var location: OpenMobilityAPI.Location?
    var hierarchy: Int
    
    var body: some View {
        List {
            ForEach(locations) { rowLocation in
                NavigationLink(
                    destination: LocationSubList(
                        locations: self.gtfsManager.locations.filter({ $0.pid == rowLocation.id }),
                        location: rowLocation,
                        hierarchy: self.hierarchy + 1),
                    tag: rowLocation,
                    selection: self.$gtfsManager.selectedLocation[self.hierarchy]
                ) {
                    Text(rowLocation.n)
                }
            }
        }
        .navigationBarTitle(getTitle(), displayMode: .inline)
    }
    
    func getTitle() -> Text {
        if let location = location {
            return Text(location.n)
        }
        return Text("Regions")
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
            HStack {
                Spacer()
                Text(label)
                Spacer()
            }
        }
        .padding()
        //.frame(width: 300)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Constants.cornerRadius).stroke())
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
