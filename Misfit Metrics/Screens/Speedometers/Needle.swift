//
//  Needle.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//
import SwiftUI

struct Needle: Shape {
    let speed: Double
    let minSpeed: Double
    let maxSpeed: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Create a needle shape (triangle pointing up)
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}
