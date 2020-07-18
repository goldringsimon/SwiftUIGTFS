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
    @State private var selectedRoute = "Orange"
    
    func getTransformViewportToScreen(from viewport: CGRect, to screen: CGSize) -> CGAffineTransform {
        let returnValue = CGAffineTransform.init(translationX: screen.width / 2, y: screen.height / 2)
            .scaledBy(x: CGFloat(screen.width / viewport.width), y: -CGFloat(screen.width / viewport.width))
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -viewport.midX, y: -viewport.midY)
        return returnValue
    }
    
    @State private var isDisplayingRouteColors = false
    
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
                 
                 /*ForEach(self.gtfsManager.routes) { route in
                 GTFSShape(shapePoints: self.gtfsManager.getShapeId(for: route.routeId), viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                 .stroke(Color.red, style: StrokeStyle(lineWidth: 1))
                 }*/
                 
                 if self.selectedRoutes == RoutesPicker.trainRoutes {
                 ForEach(self.gtfsManager.trainRoutes) { route in
                 /*GTFSShape(shapePoints: self.gtfsManager.getShapeId(for: route.routeId), viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                 .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))*/
                 
                 ForEach(self.gtfsManager.getUniqueShapesIdsForRoute(for: route.routeId), id: \.self) { shapeId in
                 GTFSShape(shapePoints: self.gtfsManager.shapeDictionary[shapeId] ?? [], viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                 .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                 }
                 }
                 }*/
                
                ForEach(self.gtfsManager.displayedRoutes) { route in
                    ForEach(self.gtfsManager.getUniqueShapesIdsForRoute(for: route.routeId), id: \.self) { shapeId in
                        GTFSShape(shapePoints: self.gtfsManager.shapeDictionary[shapeId] ?? [], viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                            .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    }
                }
                
                /*ForEach(self.getDisplayedRoutes()) { route in
                 ForEach(self.gtfsManager.getUniqueShapesIdsForRoute(for: route.routeId), id: \.self) { shapeId in
                 GTFSShape(shapePoints: self.gtfsManager.shapeDictionary[shapeId] ?? [], viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                 .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                 }
                 }*/
            }
                //            .drawingGroup()
                .clipped()
                .edgesIgnoringSafeArea(.all)
            
            HStack {
                Spacer()
                VStack {
                    VStack(alignment: .leading){
                        Button(action: {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                self.isDisplayingRouteColors.toggle()
                            }
                        }, label: {
                            Text("Toggle route colours")
                        })
                        /*List{
                         ForEach(gtfsManager.trainRoutes) { route in
                         Button(action: {
                         self.selectedRoute = route.routeId
                         }, label: {
                         Text(route.routeLongName ?? "").tag(route.routeId)
                         })
                         }
                         }*/
                        HStack{
                            Text("Enable route colours:")
                            Spacer()
                            Picker("Route colours:", selection: $isDisplayingRouteColors) {
                                Text("Off").tag(false)
                                Text("On").tag(true)
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        Divider()
                        HStack{
                            Text("Display trams:")
                            Spacer()
                            Picker("Tram routes:", selection: $gtfsManager.displayTrams) {
                                Text("Off").tag(false)
                                Text("On").tag(true)
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        HStack{
                            Text("Display metro:")
                            Spacer()
                            Picker("Metro routes:", selection: $gtfsManager.displayMetro) {
                                Text("Off").tag(false)
                                Text("On").tag(true)
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        HStack{
                            Text("Display rail:")
                            Spacer()
                            Picker("Rail routes:", selection: $gtfsManager.displayRail) {
                                Text("Off").tag(false)
                                Text("On").tag(true)
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        HStack{
                            Text("Display buses:")
                            Spacer()
                            Picker("Bus routes:", selection: $gtfsManager.displayBuses) {
                                Text("Off").tag(false)
                                Text("On").tag(true)
                            }.pickerStyle(SegmentedPickerStyle())
                        }
                        Text("# displayed routes: \(self.gtfsManager.displayedRoutes.count)")
                    }
                    .padding()
                    .frame(width: 300)
                    .modifier(UICard())
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Selected route: \(selectedRoute)")
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
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        VStack {
                            HStack {
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
                            }
                            LoadingRow(description: "Loading routes...", isFinished: $gtfsManager.isFinishedLoadingRoutes)
                            LoadingRow(description: "Loading trips...", isFinished: $gtfsManager.isFinishedLoadingTrips)
                            LoadingRow(description: "Loading shapes...", isFinished: $gtfsManager.isFinishedLoadingShapes)
                            LoadingRow(description: "Loading stops...", isFinished: $gtfsManager.isFinishedLoadingStops)
                        }.font(Font.subheadline.lowercaseSmallCaps())
                            .padding()
                            .modifier(UICard())
                            .frame(width: 400)
                        Spacer()
                    }
                    .animation(.easeIn)
                    Spacer()
                }
            }
        }
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

struct UICard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(UIColor.secondarySystemBackground.withAlphaComponent(0.75)))
            .cornerRadius(8)
            .padding()
    }
}

struct GTFSShape: Shape {
    var shapePoints: [GTFSShapePoint]
    var viewport: CGRect
    var scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = shapePoints.first else { return path }
        path.move(to: CGPoint(x: first.ptLon, y: first.ptLat))
        for point in shapePoints {
            path.addLine(to: CGPoint(x: point.ptLon, y: point.ptLat))
        }
        
        let transformed = path.transformViewportToScreen(from: viewport, to: rect.size, scale: scale)
        return transformed.path(in: rect)
    }
}

struct GTFSShapes: Shape {
    var shapes: [String: [GTFSShapePoint]]
    var viewport: CGRect
    var scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (_, shapePoints) in shapes {
            guard let first = shapePoints.first else { break }
            path.move(to: CGPoint(x: first.ptLon, y: first.ptLat))
            for point in shapePoints {
                path.addLine(to: CGPoint(x: point.ptLon, y: point.ptLat))
            }
        }
        
        let transformed = path.transformViewportToScreen(from: viewport, to: rect.size, scale: scale)
        return transformed.path(in: rect)
    }
}
