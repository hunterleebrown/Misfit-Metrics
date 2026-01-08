//
//  PieWedge.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/8/26.
//

import SwiftUI

/// A pie wedge shape that fills from the center to an arc
struct PieWedge: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
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
        PieWedge(startAngle: .degrees(90), endAngle: .degrees(180))
            .fill(.red)
            .frame(width: 150, height: 150)
        
        PieWedge(startAngle: .degrees(90), endAngle: .degrees(270))
            .fill(.blue)
            .frame(width: 150, height: 150)
        
        PieWedge(startAngle: .degrees(90), endAngle: .degrees(440))
            .fill(.green)
            .frame(width: 150, height: 150)
    }
    .padding()
}
