//
//  UICardPosition.swift
//  SwiftUIGTFS
//
//  Created by Simon Goldring on 8/2/20.
//  Copyright © 2020 Simon Goldring. All rights reserved.
//

import SwiftUI

struct UICardPosition<Content: View>: View {
    enum Corner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    let corner: Corner
    let content: Content
    
    init(corner: Corner, @ViewBuilder content: () -> Content) {
        self.corner = corner
        self.content = content()
    }
    
    var body: some View {
        return VStack {
            if corner == .topLeft {
                HStack {
                    content
                    Spacer()
                }
                Spacer()
            }
            
            if corner == .topRight {
                HStack {
                    Spacer()
                    content
                }
                Spacer()
            }
            
            if corner == .bottomLeft {
                Spacer()
                HStack {
                    content
                    Spacer()
                }
            }
            
            if corner == .bottomRight {
                Spacer()
                HStack {
                    Spacer()
                    content
                }
            }
        }
    }
}
