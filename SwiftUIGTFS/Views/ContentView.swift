//
//  ContentView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

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
    
    var body: some View {
        ZStack {
            ZStack {
                GeometryReader { geometry in
                    GTFSShapes(shapes: self.gtfsManager.shapes, viewport: self.gtfsManager.viewport, scale: self.scale)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    
                    GTFSShape(shapePoints: self.gtfsManager.shapes["9890009"] ?? [], viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    
                    GTFSShape(shapePoints: self.gtfsManager.getShapeId(for: self.selectedRoute), viewport: self.gtfsManager.viewport, scale: self.scale) // 010070
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                
                    /*ForEach(self.gtfsManager.stops) { stop in
//                        Text(stop.stopName)
                        Circle()
                        .foregroundColor(.green)
                        .frame(width: 5, height: 5)
                            .position(CGPoint(x: stop.stopLon, y: stop.stopLat).applying(self.getTransformViewportToScreen(from: self.gtfsManager.viewport, to: geometry.size)))
                    }*/
                }
            }
//            .drawingGroup()
            .clipped()
            .edgesIgnoringSafeArea(.all)
            
            VStack{
                HStack {
                    Spacer()
                    VStack{
                        List{
                            ForEach(gtfsManager.routes) { route in
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
                }
                Spacer()
                HStack{
                    Spacer()
                    VStack{
                        /*Picker("Route", selection: $selectedRoute) {
                            /*ForEach(gtfsManager.routes, id:\.routeId) { route in
                             Text(route.routeLongName).tag(route.routeId)
                             }*/
                            Text("Red").tag("Red")
                            Text("Orange").tag("Orange")
                        }.pickerStyle(SegmentedPickerStyle())*/
                        Text("Selected route: \(selectedRoute)")
                        Text("Route count: \(gtfsManager.routes.count)")
                        Text("Trip count: \(gtfsManager.trips.count)")
                        Text("Shape count: \(gtfsManager.shapes.count)")
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
        guard let first = stops.first else { return path }
        path.move(to: CGPoint(x: first.stopLon, y: first.stopLat))
        for stop in stops {
            path.addLine(to: CGPoint(x: stop.stopLon, y: stop.stopLon))
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
        
        for (id, shapePoints) in shapes {
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
