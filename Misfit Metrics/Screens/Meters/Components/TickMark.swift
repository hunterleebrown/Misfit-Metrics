//
//  TickMark.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/8/26.
//

import SwiftUI

/// A tick mark view that draws a radial line at a specified angle
struct TickMark: View {
    let angle: Double
    let radius: Double
    let center: CGPoint
    let isLarge: Bool
    
    var body: some View {
        let radians = angle * .pi / 180
        let length: CGFloat = isLarge ? 12 : 6
        let width: CGFloat = isLarge ? 2 : 1
        
        // Position tick marks on the outer edge of the circle
        let outerRadius = radius
        let innerRadius = radius - length
        
        let startX = center.x + cos(radians) * outerRadius
        let startY = center.y + sin(radians) * outerRadius
        let endX = center.x + cos(radians) * innerRadius
        let endY = center.y + sin(radians) * innerRadius
        
        Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(Color.primary, lineWidth: width)
    }
}

#Preview {
    GeometryReader { geometry in
        let size = min(geometry.size.width, geometry.size.height)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = size * 0.4
        
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.3), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
            
            // Show tick marks at various angles
            ForEach(0..<12, id: \.self) { index in
                let angle = 90.0 + (Double(index) * 30.0)
                TickMark(
                    angle: angle,
                    radius: radius,
                    center: center,
                    isLarge: index % 3 == 0
                )
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .frame(width: 200, height: 200)
    .padding()
}
