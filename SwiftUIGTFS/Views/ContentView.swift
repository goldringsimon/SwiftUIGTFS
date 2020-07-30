//
//  ContentView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gtfsManager: GTFSManager
    
    @State private var isDisplayingRouteColors = false
    
    /*func getTransformViewportToScreen(from viewport: CGRect, to screen: CGSize) -> CGAffineTransform {
        let returnValue = CGAffineTransform.init(translationX: screen.width / 2, y: screen.height / 2)
            .scaledBy(x: CGFloat(screen.width / viewport.width), y: -CGFloat(screen.width / viewport.width))
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -viewport.midX, y: -viewport.midY)
        return returnValue
    }*/
    
    private func getDisplayColor(for route: GTFSRoute) -> Color {
        if isDisplayingRouteColors {
            return Color(UIColor(gtfsHex: route.routeColor ?? "") ?? UIColor.systemGray)
        } else {
            return Color(UIColor.systemGray)
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                /*GTFSShapes(shapes: self.gtfsManager.shapeDictionary, viewport: self.gtfsManager.viewport, scale: self.scale)
                 .stroke(Color(.systemFill), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                 .animation(.easeInOut(duration: 5.0))
                 .transition(.opacity)
                 }*/
                
                ForEach(GTFSRouteType.allCases, id:\.rawValue) { routeType in
                    Group {
                        if (self.gtfsManager.displayRoute[routeType.rawValue]) {
                        
                            ForEach( self.gtfsManager.displayedRoutesByType[routeType.rawValue] ) { routes in
                                
                                Text("")
                                
                            }
                        }
                        
                    }
                }
                
                ForEach(self.gtfsManager.displayedRoutes) { route in
                    ForEach(self.gtfsManager.getUniqueShapesIdsForRoute(for: route.routeId), id: \.self) { shapeId in
                        GTFSShape(shapePoints: self.gtfsManager.shapeDictionary[shapeId] ?? [], viewport: self.gtfsManager.currentViewport)
                            .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .onTapGesture {
                                withAnimation {
                                    self.gtfsManager.selectedRoute = route.routeId
                                    //self.gtfsManager.overviewViewport = GTFSShapePoint.getOverviewViewport(for: self.gtfsManager.shapeDictionary[shapeId] ?? [])
                                }
                        }
                    }
                }
                
                if self.gtfsManager.selectedRoute != nil {
                    ForEach(self.gtfsManager.getUniqueShapesIdsForRoute(for: self.gtfsManager.selectedRoute!), id: \.self) { shapeId in
                        GTFSShape(shapePoints: self.gtfsManager.shapeDictionary[shapeId] ?? [], viewport: self.gtfsManager.currentViewport)
                            .stroke(Color(.systemPink), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .onTapGesture {
                                withAnimation {
                                    self.gtfsManager.selectedRoute = nil
                                }
                        }
                    }
                }
            }
            .drawingGroup()
            .clipped()
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button("Load New System", action: {
                        
                    })
                    .padding()
                    .modifier(UICard())
                    Spacer()
                }
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .leading){
                        Toggle(isOn: $isDisplayingRouteColors.animation()) {
                            Text("Display route colours:")
                        }
                        Divider()
                        Toggle(isOn: $gtfsManager.displayTrams) {
                            Text("Display trams:")
                        }
                        Toggle(isOn: $gtfsManager.displayMetro) {
                            Text("Display metro:")
                        }
                        Toggle(isOn: $gtfsManager.displayRail) {
                            Text("Display rail:")
                        }
                        Toggle(isOn: $gtfsManager.displayBuses) {
                            Text("Display buses:")
                        }
                        Text("# displayed routes: \(self.gtfsManager.displayedRoutes.count)")
                    }
                    .padding()
                    .frame(width: 300)
                    .modifier(UICard())
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Selected route: \(gtfsManager.selectedRoute ?? "")")
                        Text("Route count: \(gtfsManager.routes.count)")
                        Text("Trip count: \(gtfsManager.trips.count)")
                        Text("Shape point count: \(gtfsManager.shapes.count)")
                        Text("Shape count: \(gtfsManager.shapeDictionary.count)")
                        Text("Stop count: \(gtfsManager.stops.count)")
                        Text("Scale: \(gtfsManager.scale)")
                        Slider(value: $gtfsManager.scale, in: gtfsManager.minScale...gtfsManager.maxScale)
                    }
                    .padding()
                    .frame(width: 300)
                    .modifier(UICard())
                }
            }
            
            if !gtfsManager.isFinishedLoading {
                Color(UIColor.black.withAlphaComponent(0.85))
                    .edgesIgnoringSafeArea(.all)
                LoadingOverlay()
            }
        }
    }
}
