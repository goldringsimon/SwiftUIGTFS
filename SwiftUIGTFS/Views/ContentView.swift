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
    @ObservedObject var viewModel: ContentViewModel
    
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
                
                /*ForEach(GTFSRouteType.allCases, id:\.rawValue) { routeType in
                    Group {
                        if (self.gtfsManager.displayRoute[routeType.rawValue]) {
                            ForEach( self.gtfsManager.displayedRoutesByType[routeType.rawValue] ) { routes in
                                Text("")
                            }
                        }
                    }
                }*/
                
                ForEach(self.viewModel.displayedRoutes) { route in
                    ForEach(self.viewModel.getUniqueShapesIdsForRoute(for: route.routeId), id: \.self) { shapeId in
                        GTFSShape(shapePoints: self.viewModel.getShape(shapeId: shapeId), viewport: self.viewModel.currentViewport)
                            .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .onTapGesture {
                                withAnimation {
                                    self.viewModel.selectRoute(routeId: route.routeId)
                                }
                        }
                    }
                }
                
                if self.viewModel.selectedRoute != nil {
                    ForEach(self.viewModel.getUniqueShapesIdsForRoute(for: self.viewModel.selectedRoute!), id: \.self) { shapeId in
                        GTFSShape(shapePoints: self.viewModel.getShape(shapeId: shapeId), viewport: self.viewModel.currentViewport)
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
            
            UICardPosition(corner: .topLeft) {
                Button("Load New System", action: {
                    
                })
                .padding()
                .modifier(UICard())
                Spacer()
            }
            
            UICardPosition(corner: .topRight) {
                RouteDisplayView(viewModel: gtfsManager.routeDisplayViewModel, isDisplayingRouteColors: $isDisplayingRouteColors)
            }
            
            UICardPosition(corner: .bottomRight) {
                GTFSInfoView(viewModel: gtfsManager.infoViewModel)
            }
            
            if !gtfsManager.isFinishedLoading {
                Color(UIColor.black.withAlphaComponent(0.85))
                    .edgesIgnoringSafeArea(.all)
                LoadingOverlay()
            }
        }
    }
}
