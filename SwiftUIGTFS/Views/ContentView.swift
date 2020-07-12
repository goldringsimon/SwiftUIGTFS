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
    
    var body: some View {
        VStack {
            GTFSShapesShape(shapes: gtfsManager.shapes)
                .transform(CGAffineTransform.init(translationX: -42.329848, y: 71.083876))
                .transform(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
                .transform(CGAffineTransform.init(translationX: 200, y: 200))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                .background(Color(.secondarySystemBackground))
            
            Text("Route count: \(gtfsManager.routes.count)")
            Text("Trip count: \(gtfsManager.trips.count)")
            Text("Shape count: \(gtfsManager.shapes.count)")
            Text("Scale: \(scale)")
            Slider(value: $scale, in: 100...5000)
        }
    }
}

struct GTFSShape: Shape {
    var shapePoints : [GTFSShapePoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = shapePoints.first else { return path }
        
        path.move(to: CGPoint(x: first.ptLat, y: first.ptLon))
        for point in shapePoints {
            path.addLine(to: CGPoint(x: point.ptLat, y: point.ptLon))
        }
        
        return path
    }
}

struct GTFSShapesShape: Shape {
    var shapes : [Int: [GTFSShapePoint]]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (id, shapePoints) in shapes {
            guard let first = shapePoints.first else { break }
            path.move(to: CGPoint(x: first.ptLat, y: first.ptLon))
            for point in shapePoints {
                path.addLine(to: CGPoint(x: point.ptLat, y: point.ptLon))
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
