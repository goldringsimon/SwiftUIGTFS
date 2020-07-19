//
//  GTFSShape.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/19/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

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

/*struct GTFSShape_Previews: PreviewProvider {
    static var previews: some View {
        GTFSShape()
    }
}*/
