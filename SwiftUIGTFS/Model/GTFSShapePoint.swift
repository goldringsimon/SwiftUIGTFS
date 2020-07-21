//
//  ShapeManager.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 7/12/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import CoreGraphics

struct GTFSShapePoint: Identifiable {
    var id: String { return shapeId}
    let shapeId: String
    let ptLat: Double
    let ptLon: Double
    let ptSequence: Int
    let distTraveled: Float?
    
    static func getOverviewViewport(for shapePoints: [GTFSShapePoint]) -> CGRect {
        
        let points = shapePoints.map { CGPoint(x: $0.ptLon, y: $0.ptLat) }
        guard let firstPoint = points.first else { return .zero }
        let minX = points.reduce(firstPoint.x, { CGFloat.minimum($0, $1.x) })
        let minY = points.reduce(firstPoint.y, { CGFloat.minimum($0, $1.y) })
        let maxX = points.reduce(firstPoint.x, { CGFloat.maximum($0, $1.x) })
        let maxY = points.reduce(firstPoint.y, { CGFloat.maximum($0, $1.y) })
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        /*var minLon = first.ptLon
        var maxLon = first.ptLon
        var minLat = first.ptLat
        var maxLat = first.ptLat
        for point in shapePoints {
            if point.ptLon < minLon { minLon = point.ptLon }
            if point.ptLon > maxLon { maxLon = point.ptLon }
            if point.ptLat < minLat { minLat = point.ptLat }
            if point.ptLat > maxLat { maxLat = point.ptLat }
        }
        return CGRect(x: minLon, y: minLat, width: maxLon-minLon, height: maxLat-minLat)*/
    }
}
