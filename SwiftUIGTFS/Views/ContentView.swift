//
//  ContentView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

extension Shape {
    func transformViewportToScreen(from viewport: CGRect, to screen: CGSize) -> TransformedShape<Self> {
        // This is the reverse order to previous implementation
        let transform = CGAffineTransform.init(translationX: screen.width / 2, y: screen.height / 2)
        .scaledBy(x: CGFloat(screen.width / viewport.width), y: CGFloat(screen.width / viewport.width))
        .translatedBy(x: -viewport.midX, y: -viewport.midY)
        
        return self.transform(transform)
    }
}

struct ContentView: View {
    @ObservedObject var gtfsManager: GTFSManager
    @State private var scale: Double = 1
    private let minScale = 0.1
    private let maxScale = 10.0
    @State private var selectedRoute = "Orange"
    @State private var dragTranslation: CGAffineTransform = CGAffineTransform.identity
    
    func getViewportToScreenTransformation(from viewport: CGRect, to screen: CGSize) -> CGAffineTransform {
        // This is the reverse order to previous implementation
        let transform = CGAffineTransform.init(translationX: screen.width / 2, y: screen.height / 2)
        .scaledBy(x: CGFloat(screen.width / viewport.width), y: CGFloat(screen.width / viewport.width))
        .translatedBy(x: -viewport.midX, y: -viewport.midY)
        
        return transform
    }
    
    var body: some View {
        ZStack {
            ZStack {
                GeometryReader { geometry in
                    GTFSShapesShape(shapes: self.gtfsManager.shapes)
//                        .transformViewportToScreen(from: self.gtfsManager.viewport, to: geometry.size)
                        .transform(self.getViewportToScreenTransformation(from: self.gtfsManager.viewport, to: geometry.size))
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    
                    GTFSShape(shapePoints: self.gtfsManager.shapes["010070"] ?? [])
                        .transformViewportToScreen(from: self.gtfsManager.viewport, to: geometry.size)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
                
            .drawingGroup()
            .clipped()
            .edgesIgnoringSafeArea(.all)
            
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    VStack{
                        Picker("Route", selection: $selectedRoute) {
                            /*ForEach(gtfsManager.routes, id:\.routeId) { route in
                             Text(route.routeLongName).tag(route.routeId)
                             }*/
                            Text("Red").tag("Red")
                            Text("Orange").tag("Orange")
                        }.pickerStyle(SegmentedPickerStyle())
                        Text("Route count: \(gtfsManager.routes.count)")
                        Text("Trip count: \(gtfsManager.trips.count)")
                        Text("Shape count: \(gtfsManager.shapes.count)")
                        Text("Scale: \(scale)")
                        Slider(value: $scale, in: minScale...maxScale)
                    }
                    .padding()
                    .frame(width: 400)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding()
                }
            }
        }
    }
}

struct GTFSRouteShape: Shape {
    var gtfsManager: GTFSManager
    @Binding var selectedRoute: String
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for trip in gtfsManager.trips {
            if trip.routeId == self.selectedRoute {
                if let shape = gtfsManager.shapes[trip.shapeId] {
                    path.addPath(nextPath(from: shape))
                }
            }
        }
        
        return path
    }
    
    func nextPath(from shapePoints: [GTFSShapePoint]) -> Path {
        var path = Path()
        guard let first = shapePoints.first else { return path }
        path.move(to: CGPoint(x: first.ptLon, y: first.ptLat))
        for point in shapePoints {
            path.addLine(to: CGPoint(x: point.ptLon, y: point.ptLat))
        }
        
        return path
    }
}

struct GTFSShape: Shape {
    var shapePoints : [GTFSShapePoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = shapePoints.first else { return path }
        path.move(to: CGPoint(x: first.ptLon, y: first.ptLat))
        for point in shapePoints {
            path.addLine(to: CGPoint(x: point.ptLon, y: point.ptLat))
        }
        
        return path
    }
}

struct GTFSShapesShape: Shape {
    var shapes : [String: [GTFSShapePoint]]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (id, shapePoints) in shapes {
            guard let first = shapePoints.first else { break }
            path.move(to: CGPoint(x: first.ptLon, y: first.ptLat))
            for point in shapePoints {
                path.addLine(to: CGPoint(x: point.ptLon, y: point.ptLat))
            }
        }
        
        return path
    }
}

/*
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/
