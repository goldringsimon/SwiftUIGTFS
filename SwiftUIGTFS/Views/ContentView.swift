//
//  ContentView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var gtfsManager: GTFSManager
    @State private var scale: Double = 1500
    @State private var selectedRoute = "Orange"
    @State private var dragTranslation: CGAffineTransform = CGAffineTransform.identity
    
    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    GTFSShapesShape(shapes: self.gtfsManager.shapes)
                        .transform(CGAffineTransform.init(translationX: -self.gtfsManager.viewport.midX, y: -self.gtfsManager.viewport.midY))
                        .transform(CGAffineTransform(scaleX: CGFloat(self.scale), y: CGFloat(self.scale)))
                        .transform(CGAffineTransform.init(translationX: geometry.size.width / 2, y: geometry.size.height / 2))
//                    .transform(dragTranslation)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    
                    GTFSShape(shapePoints: self.gtfsManager.shapes["010070"] ?? [])
                        .transform(CGAffineTransform.init(translationX: -self.gtfsManager.viewport.midX, y: -self.gtfsManager.viewport.midY))
                        .transform(CGAffineTransform(scaleX: CGFloat(self.scale), y: CGFloat(self.scale)))
                        .transform(CGAffineTransform.init(translationX: geometry.size.width / 2, y: geometry.size.height / 2))
//                    .transform(dragTranslation)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
                
                
                /*.gesture(DragGesture()
            .onChanged({ value in
                self.dragTranslation = self.dragTranslation.translatedBy(x: value.translation.width, y: value.translation.height)
            })
            )*/
            .drawingGroup()
            .background(Color(.secondarySystemBackground))
            .clipped()
            
            /*GTFSShape(shapePoints: gtfsManager.shapes["010070"] ?? [])
            .transform(CGAffineTransform.init(translationX: -42.329848, y: 71.083876))
            .transform(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
            .transform(CGAffineTransform.init(translationX: 200, y: 200))
            .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
            .background(Color(.secondarySystemBackground))
                .frame(height: 500)*/
            
            //GTFSRouteShape(gtfsManager: gtfsManager, selectedRoute: $selectedRoute)
            
            
            Text("Route count: \(gtfsManager.routes.count)")
            /*Picker("Route", selection: $selectedRoute) {
                ForEach(gtfsManager.routes, id:\.routeId) { route in
                    Text(route.routeLongName).tag(route.routeId)
                }
            }*/
            Text("Trip count: \(gtfsManager.trips.count)")
            Text("Shape count: \(gtfsManager.shapes.count)")
            Text("Scale: \(scale)")
            Text("Initial translation: x: \(gtfsManager.viewport.midX) y: \(gtfsManager.viewport.midY) ")
            Slider(value: $scale, in: 100...5000)
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
