//
//  ContentView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
    
    public convenience init?(gtfsHex: String) {
        self.init(hex: "#" + gtfsHex + "FF")
    }
}

extension Shape {
    func transformViewportToScreen(from viewport: CGRect, to screen: CGSize, scale: CGFloat = 1) -> TransformedShape<Self> {
        // This is the reverse order to previous implementation
        let transform = CGAffineTransform.init(translationX: screen.width / 2, y: screen.height / 2)
            .scaledBy(x: CGFloat(screen.width / viewport.width), y: -CGFloat(screen.width / viewport.width)) // The negative sign for the y-coordinate is slight voodoo to fix SwiftUI's coordinate system starting in the lower left corner, not the top right
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -viewport.midX, y: -viewport.midY)
        return self.transform(transform)
    }
}

struct ContentView: View {
    @ObservedObject var gtfsManager: GTFSManager
    @State private var scale: CGFloat = 1
    private let minScale: CGFloat = 0.1
    private let maxScale: CGFloat = 10.0
    @State private var selectedRoute: String? = nil
    @State private var isDisplayingRouteColors = false
    
    @State private var animationAmount: CGFloat = 1
    
    func getTransformViewportToScreen(from viewport: CGRect, to screen: CGSize) -> CGAffineTransform {
        let returnValue = CGAffineTransform.init(translationX: screen.width / 2, y: screen.height / 2)
            .scaledBy(x: CGFloat(screen.width / viewport.width), y: -CGFloat(screen.width / viewport.width))
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -viewport.midX, y: -viewport.midY)
        return returnValue
    }
    
    private func getDisplayColor(for route: GTFSRoute) -> Color {
        if isDisplayingRouteColors {
            return Color(UIColor(gtfsHex: route.routeColor ?? "") ?? UIColor.systemFill)
        } else {
            return Color(UIColor.systemFill)
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                /*if self.selectedRoutes == RoutesPicker.allShapes {
                 GTFSShapes(shapes: self.gtfsManager.shapeDictionary, viewport: self.gtfsManager.viewport, scale: self.scale)
                 .stroke(Color(.systemFill), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                 .animation(.easeInOut(duration: 5.0))
                 .transition(.opacity)
                 }
                 }*/
                
                ForEach(self.gtfsManager.displayedRoutes) { route in
                    ForEach(self.gtfsManager.getUniqueShapesIdsForRoute(for: route.routeId), id: \.self) { shapeId in
                        GTFSShape(shapePoints: self.gtfsManager.shapeDictionary[shapeId] ?? [], viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                            .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .onTapGesture {
                                self.selectedRoute = route.routeId
                        }
                    }
                }
                
                if self.selectedRoute != nil {
                    ForEach(self.gtfsManager.getUniqueShapesIdsForRoute(for: self.selectedRoute!), id: \.self) { shapeId in
                        GTFSShape(shapePoints: self.gtfsManager.shapeDictionary[shapeId] ?? [], viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                            .stroke(Color(.systemPink), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .onTapGesture {
                                self.selectedRoute = nil
                        }
                    }
                }
            }
            //.drawingGroup()
            .clipped()
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .leading){
                        /*List{
                         ForEach(gtfsManager.trainRoutes) { route in
                         Button(action: {
                         self.selectedRoute = route.routeId
                         }, label: {
                         Text(route.routeLongName ?? "").tag(route.routeId)
                         })
                         }
                         }*/
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
                HStack {
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Selected route: \(selectedRoute ?? "")")
                        Text("Route count: \(gtfsManager.routes.count)")
                        Text("Trip count: \(gtfsManager.trips.count)")
                        Text("Shape point count: \(gtfsManager.shapes.count)")
                        Text("Shape count: \(gtfsManager.shapeDictionary.count)")
                        Text("Stop count: \(gtfsManager.stops.count)")
                        Text("Scale: \(scale)")
                        Slider(value: $scale, in: minScale...maxScale)
                    }
                    .padding()
                    .frame(width: 300)
                    .modifier(UICard())
                }
            }
            
            if !gtfsManager.isFinishedLoading {
                Color(UIColor.black.withAlphaComponent(0.85))
                    .edgesIgnoringSafeArea(.all)
                LoadingOverlay(gtfsManager: gtfsManager)
            }
        }
    }
}

/*struct UIOverlay: View {
    @ObservedObject var gtfsManager: GTFSManager
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(alignment: .leading){
                    /*List{
                     ForEach(gtfsManager.trainRoutes) { route in
                     Button(action: {
                     self.selectedRoute = route.routeId
                     }, label: {
                     Text(route.routeLongName ?? "").tag(route.routeId)
                     })
                     }
                     }*/
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
            HStack {
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Selected route: \(selectedRoute ?? "")")
                    Text("Route count: \(gtfsManager.routes.count)")
                    Text("Trip count: \(gtfsManager.trips.count)")
                    Text("Shape point count: \(gtfsManager.shapes.count)")
                    Text("Shape count: \(gtfsManager.shapeDictionary.count)")
                    Text("Stop count: \(gtfsManager.stops.count)")
                    Text("Scale: \(scale)")
                    Slider(value: $scale, in: minScale...maxScale)
                }
                .padding()
                .frame(width: 300)
                .modifier(UICard())
            }
        }
    }
}*/
