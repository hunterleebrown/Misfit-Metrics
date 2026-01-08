//
//  HalfCircleSpeedometer.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//
import SwiftUI

struct HalfCircleSpeedometer: View {
    let speed: Double
    
    private let minSpeed: Double = 0
    private let maxSpeed: Double = 35
    private let startAngle: Angle = .degrees(270) // 9 o'clock (left side)
    private let endAngle: Angle = .degrees(90)    // 3 o'clock (right side)
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            // For a half circle, we want the full width to be the diameter
            let radius = width * 0.45
            // Position center at the bottom of the view
            let center = CGPoint(x: width / 2, y: height)
            
            ZStack {
                // Small tick marks for every integer
                ForEach(Array(0...Int(maxSpeed)), id: \.self) { speed in
                    let angle = angleForSpeed(Double(speed))
                    
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 1, height: 6)
                        .offset(y: -radius + 5)
                        .rotationEffect(angle)
                        .position(center)
                }
                
                // Major tick marks and labels for every 5 mph
                ForEach(Array(0..<Int(maxSpeed / 5) + 1), id: \.self) { index in
                    let speed = index * 5
                    let angle = angleForSpeed(Double(speed))
                    
                    // Tick marks
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 1.5, height: index % 2 == 0 ? 12 : 8)
                        .offset(y: -radius + 5)
                        .rotationEffect(angle)
                        .position(center)
                    
                    // Speed labels (every 10 mph)
                    if index % 2 == 0 {
                        Text("\(speed)")
                            .font(.system(size: 10, weight: .semibold))
                            .position(labelPosition(for: angle, radius: radius - 20, center: center))
                    }
                }
                
                // Current speed display
                VStack(spacing: 2) {
                    Text("\(Int(speed))")
                        .font(.system(size: 32, weight: .bold))
                    Text("MPH")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .position(x: center.x, y: center.y - radius * 0.3)
                
                // Needle
                Needle(speed: speed, minSpeed: minSpeed, maxSpeed: maxSpeed)
                    .fill(Color.fairyRed)
                    .frame(width: 3, height: radius)
                    .offset(y: -radius / 2)
                    .rotationEffect(angleForSpeed(speed))
                    .position(center)
                
                // Center cap
                Circle()
                    .fill(Color.fairyRed)
                    .frame(width: 12, height: 12)
                    .position(center)
            }
        }
    }
    
    private func angleForSpeed(_ speed: Double) -> Angle {
        // Linear scale from 270° (9 o'clock) to 90° (3 o'clock) = 180° sweep going clockwise
        // Clockwise means we're going from 270° -> 360° -> 0° -> 90°
        let totalDegrees = 180.0
        let speedRange = maxSpeed - minSpeed
        let speedPercent = (speed - minSpeed) / speedRange
        
        // Add degrees going clockwise (which is the positive direction in SwiftUI)
        let degrees = startAngle.degrees + (speedPercent * totalDegrees)
        
        // Normalize to 0-360 range
        let normalizedDegrees = degrees >= 360 ? degrees - 360 : degrees
        
        return .degrees(normalizedDegrees)
    }
    
    private func labelPosition(for angle: Angle, radius: Double, center: CGPoint) -> CGPoint {
        let radians = angle.radians
        let x = center.x + radius * cos(radians - .pi / 2)
        let y = center.y + radius * sin(radians - .pi / 2)
        return CGPoint(x: x, y: y)
    }
}
