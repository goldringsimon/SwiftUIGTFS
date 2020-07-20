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
    //var scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = shapePoints.first else { return path }
        path.move(to: CGPoint(x: first.ptLon, y: first.ptLat))
        for point in shapePoints {
            path.addLine(to: CGPoint(x: point.ptLon, y: point.ptLat))
        }
        
        let transformed = path.transformViewportToScreen(from: viewport, to: rect.size)
        return transformed.path(in: rect)
    }
}

struct GTFSShapes: Shape {
    var shapes: [String: [GTFSShapePoint]]
    var viewport: CGRect
    //var scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for (_, shapePoints) in shapes {
            guard let first = shapePoints.first else { break }
            path.move(to: CGPoint(x: first.ptLon, y: first.ptLat))
            for point in shapePoints {
                path.addLine(to: CGPoint(x: point.ptLon, y: point.ptLat))
            }
        }
        
        let transformed = path.transformViewportToScreen(from: viewport, to: rect.size)
        return transformed.path(in: rect)
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

/*struct GTFSShape_Previews: PreviewProvider {
    static var previews: some View {
        GTFSShape()
    }
}*/
