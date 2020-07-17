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
    
    @State private var selectedRoutes = RoutesPicker.trainRoutes
    @State private var isDisplayingRouteColors = false
    
    enum RoutesPicker {
        case trainRoutes
        case allShapes
    }
    
    private func getDisplayColor(for route: GTFSRoute) -> Color {
        if isDisplayingRouteColors {
            return Color(UIColor(gtfsHex: route.routeColor ?? "") ?? .systemFill)
        } else {
            return Color(UIColor.systemFill)
        }
    }
    
    var body: some View {
        ZStack {
            
            ZStack {
                GeometryReader { geometry in
                    if self.selectedRoutes == RoutesPicker.allShapes {
                        GTFSShapes(shapes: self.gtfsManager.shapeDictionary, viewport: self.gtfsManager.viewport, scale: self.scale)
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                        .animation(.easeInOut(duration: 5.0))
                        .transition(.opacity)
                    }
                    
                    /*ForEach(self.gtfsManager.routes) { route in
                        GTFSShape(shapePoints: self.gtfsManager.getShapeId(for: route.routeId), viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 1))
                    }*/
                    
                    if self.selectedRoutes == RoutesPicker.trainRoutes {
                        ForEach(self.gtfsManager.trainRoutes) { route in
                            GTFSShape(shapePoints: self.gtfsManager.getShapeId(for: route.routeId), viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                                .stroke(self.getDisplayColor(for: route), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        
                            
                            /*GTFSShape(shapePoints: self.gtfsManager.getAllShapesForRoute(for: route.routeId), viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))*/
                        }
                    }
                    
                    /*GTFSShape(shapePoints: self.gtfsManager.shapeDictionary["9890009"] ?? [], viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))*/
                    
                    /*if (self.isDisplayingRouteColors) {
                        GTFSShape(shapePoints: self.gtfsManager.getShapeId(for: self.selectedRoute), viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        
                            .transition(.slide)
                    }*/
                
                    /*ForEach(self.gtfsManager.stops) { stop in
//                        Text(stop.stopName)
                            Circle()
                                .foregroundColor(.green)
                                .frame(width: 5, height: 5)
                                .position(CGPoint(x: stop.stopLon!, y: stop.stopLat!).applying(self.getTransformViewportToScreen(from: self.gtfsManager.viewport, to: geometry.size)))
                    }*/
                }
            }
//            .drawingGroup()
            .clipped()
            .edgesIgnoringSafeArea(.all)
            
            HStack {
                Spacer()
                VStack {
                    VStack{
                        Button(action: {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                self.isDisplayingRouteColors.toggle()
                            }
                        }, label: {
                            Text("Toggle route colours")
                        })
                        Picker("Routes:", selection: $selectedRoutes) {
                            Text("Train Routes").tag(RoutesPicker.trainRoutes)
                            Text("All Shapes").tag(RoutesPicker.allShapes)
                            }.pickerStyle(SegmentedPickerStyle())
                        List{
                            ForEach(gtfsManager.trainRoutes) { route in
                                Button(action: {
                                    self.selectedRoute = route.routeId
                                }, label: {
                                    Text(route.routeLongName ?? "").tag(route.routeId)
                                })
                            }
                        }
                    }
                    .padding()
                    .frame(width: 300, height: 400)
                    .modifier(UICard())
                    Spacer()
                    VStack(alignment: .leading) {
                        /*VStack(alignment: .leading) {
                            Text("Finished loading routes: \(String(gtfsManager.isFinishedLoadingRoutes))")
                            Text("Finished loading trips: \(String(gtfsManager.isFinishedLoadingTrips))")
                            Text("Finished loading shapes: \(String(gtfsManager.isFinishedLoadingShapes))")
                            Text("Finished loading stops: \(String(gtfsManager.isFinishedLoadingStops))")
                            Text("Finished loading: \(String(gtfsManager.isFinishedLoading))")
                        }.font(Font.subheadline.lowercaseSmallCaps())*/
                        
                        Text("Selected route: \(selectedRoute)")
                        Text("Route count: \(gtfsManager.routes.count)")
                        Text("Trip count: \(gtfsManager.trips.count)")
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
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Finished loading routes: \(String(gtfsManager.isFinishedLoadingRoutes))")
                            Text("Finished loading trips: \(String(gtfsManager.isFinishedLoadingTrips))")
                            Text("Finished loading shapes: \(String(gtfsManager.isFinishedLoadingShapes))")
                            Text("Finished loading stops: \(String(gtfsManager.isFinishedLoadingStops))")
                            Text("Finished loading: \(String(gtfsManager.isFinishedLoading))")
                        }.font(Font.subheadline.lowercaseSmallCaps())
                            .padding()
                            .modifier(UICard())
                        Spacer()
                    }
                    Spacer()
                }.background(Color(UIColor.black.withAlphaComponent(0.8)))
                    .edgesIgnoringSafeArea(.all)
            }
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

struct GTFSStopShape: Shape {
    var stops: [GTFSStop]
    var viewport: CGRect
    var scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        /*for stop in stops {
            path.move(to: CGPoint(x: stop.stopLon, y: stop.stopLat))
            path.addEllipse(in: rect)
        }*/
        guard let first = stops.first,
            let firstStopLon = first.stopLon,
            let firstStopLat = first.stopLat else { return path }
        path.move(to: CGPoint(x: firstStopLon, y: firstStopLat))
        for stop in stops {
            guard let lon = stop.stopLon,
                let lat = stop.stopLat else { break }
            path.addLine(to: CGPoint(x: lon, y: lat))
        }
        
        let transformed = path.transformViewportToScreen(from: viewport, to: rect.size, scale: scale)
        return transformed.path(in: rect)
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
