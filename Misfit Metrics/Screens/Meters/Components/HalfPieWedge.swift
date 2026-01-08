//
//  HalfPieWedge.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/8/26.
//

import SwiftUI

/// A half pie wedge shape with the center at the bottom
struct HalfPieWedge: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Center at the bottom middle of the rect
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        // Radius should be half the width (since it's a half circle)
        let radius = rect.width / 2
        
        // Start at center
        path.move(to: center)
        
        // Add arc from startAngle to endAngle
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Close path back to center
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        HalfPieWedge(startAngle: .degrees(180), endAngle: .degrees(225))
            .fill(.red)
            .frame(width: 300, height: 150)
        
        HalfPieWedge(startAngle: .degrees(180), endAngle: .degrees(270))
            .fill(.blue)
            .frame(width: 300, height: 150)
        
        HalfPieWedge(startAngle: .degrees(180), endAngle: .degrees(360))
            .fill(.green)
            .frame(width: 300, height: 150)
    }
    .padding()
}
