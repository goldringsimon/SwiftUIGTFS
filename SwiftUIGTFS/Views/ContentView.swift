//
//  ContentView.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

let exampleStops = [("Jackson & Austin Terminal","Jackson & Austin Terminal, Northeastbound, Bus Terminal",41.87632184,-87.77410482),
                    ("5900 W Jackson","5900 W Jackson, Eastbound, Southside of the Street",41.87706679,-87.77131794),
                    ("Jackson & Menard","Jackson & Menard, Eastbound, Southside of the Street",41.87695725,-87.76975039),
                    ("5700 W Jackson","5700 W Jackson, Eastbound, Southside of the Street",41.87702418,-87.76745055),
                    ("Jackson & Lotus","Jackson & Lotus, Eastbound, Southeast Corner",41.876513,-87.761446)]

struct ContentView: View {
    @ObservedObject var shapeManager: GTFSShapeManager
    @ObservedObject var tripManager: GTFSTripManager
    @State private var scale: Double = 1500
    
    var body: some View {
        VStack {
            GTFSShapesShape(shapes: shapeManager.shapes)
                .transform(CGAffineTransform.init(translationX: -42.329848, y: 71.083876))
                .transform(CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
                .transform(CGAffineTransform.init(translationX: 200, y: 200))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                .background(Color(.secondarySystemBackground))
            
            Text("Trip count: \(tripManager.trips.count)")
            Text("Shape count: \(shapeManager.shapes.count)")
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

struct Stations: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 41.87706679, y: -87.77131794))
        for stop in exampleStops {
            path.addLine(to: CGPoint(x: stop.2, y: stop.3) )
        }
        
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 200, y: 100))
        path.addLine(to: CGPoint(x: 100, y: 300))
        path.addLine(to: CGPoint(x: 300, y: 300))
        path.addLine(to: CGPoint(x: 200, y: 100))
        //path.addLine(to: CGPoint(x: 100, y: 300))
        //.stroke(Color.blue, lineWidth: 10)
//        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        
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
