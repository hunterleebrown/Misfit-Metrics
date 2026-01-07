//
//  Speedometer.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//
import SwiftUI

struct Speedometer: View {
    let speed: Double
    
    private let minSpeed: Double = 0
    private let maxSpeed: Double = 35
    private let startAngle: Angle = .degrees(180)
    private let endAngle: Angle = .degrees(135)
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size * 0.5

            ZStack {
                // Speed markers and labels
                // Small tick marks for every integer
                ForEach(Array(0...Int(maxSpeed)), id: \.self) { speed in
                    let angle = angleForSpeed(Double(speed))
                    
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 1.5, height: 8)
                        .offset(y: -radius + 10)
                        .rotationEffect(angle)
                }
                
                // Major tick marks and labels for every 5 mph
                ForEach(Array(0..<Int(maxSpeed / 5) + 1), id: \.self) { index in
                    let speed = index * 5
                    let angle = angleForSpeed(Double(speed))
                    
                    // Tick marks
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 2, height: index % 2 == 0 ? 15 : 10)
                        .offset(y: -radius + 10)
                        .rotationEffect(angle)
                    
                    // Speed labels (every 10 mph)
                    if index % 2 == 0 {
                        Text("\(speed)")
                            .font(.system(size: 14, weight: .semibold))
                            .position(labelPosition(for: angle, radius: radius - 35, center: center))
                    }
                }
                
                // Current speed display
                VStack {
                    Text("\(Int(speed))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .animation(.easeInOut(duration: 0.5), value: speed)
                    Text("MPH")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .offset(y: radius * 0.4)
                
                // Needle
                Needle(speed: speed, minSpeed: minSpeed, maxSpeed: maxSpeed)
                    .fill(Color.fairyRed)
                    .frame(width: 4, height: radius)
                    .offset(y: -radius / 2)
                    .rotationEffect(angleForSpeed(speed))
                    .animation(.easeInOut(duration: 0.5), value: speed)
                
                // Center cap
                Circle()
                    .fill(Color.fairyRed)
                    .frame(width: 20, height: 20)
            }
            .frame(width: size, height: size)
            .position(center)
        }
    }
    
    private func angleForSpeed(_ speed: Double) -> Angle {
        // Progressive scale: 0-25 mph gets 270° (more space), 25-35 mph gets 45° (very compressed)
        let breakpoint = 25.0
        let firstSegmentDegrees = 270.0  // 0-25 mph (10.8° per mph)
        let secondSegmentDegrees = 45.0  // 25-35 mph (4.5° per mph)
        
        let degrees: Double
        if speed <= breakpoint {
            // First segment: 0-25 mph maps to 180° to 450° (wraps to 90°)
            let speedPercent = speed / breakpoint
            degrees = startAngle.degrees + (speedPercent * firstSegmentDegrees)
        } else {
            // Second segment: 25-35 mph maps to 90° to 135°
            let speedInSegment = speed - breakpoint
            let segmentRange = maxSpeed - breakpoint
            let speedPercent = speedInSegment / segmentRange
            degrees = startAngle.degrees + firstSegmentDegrees + (speedPercent * secondSegmentDegrees)
        }
        
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
