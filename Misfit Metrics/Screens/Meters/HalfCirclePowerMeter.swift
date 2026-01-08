//
//  HalfCirclePowerMeter.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import SwiftUI

struct HalfCirclePowerMeter: View {
    let power: Double? // 0 to 999 watts, nil if not available
    
    private let minPower: Double = 0
    private let maxPower: Double = 999
    private let startAngle: Angle = .degrees(180) // Bottom (6 o'clock)
    private let totalDegrees: Double = 180 // Half circle sweep
    private let tickInterval: Double = 50
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = width * 0.45
            let center = CGPoint(x: width / 2, y: height)
            
            ZStack {
                if let power = power {
                    // Power pie wedge (filled from center)
                    HalfPieWedge(
                        startAngle: startAngle,
                        endAngle: .degrees(startAngle.degrees + (powerRatio(for: power) * totalDegrees))
                    )
                    .fill(Color("fairyRed"))
                    
                    // Tick marks
                    ForEach(0..<Int(maxPower / tickInterval) + 1, id: \.self) { index in
                        let watts = Double(index) * tickInterval
                        let angle = startAngle.degrees + (watts / maxPower) * totalDegrees
                        
                        TickMark(
                            angle: angle,
                            radius: radius,
                            center: center,
                            isLarge: true
                        )
                    }
                    
                    // Center power value
                    VStack(spacing: 2) {
                        Text("\(Int(power))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("watts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("3 sec")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: center.x, y: center.y - radius * 0.5)
                } else {
                    // Not available state
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.slash.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Not Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: center.x, y: center.y - radius * 0.5)
                }
            }
        }
    }
    
    private func powerRatio(for power: Double) -> Double {
        min(max(power / maxPower, 0), 1)
    }
    
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
    
    struct TickMark: View {
        let angle: Double
        let radius: Double
        let center: CGPoint
        let isLarge: Bool
        
        var body: some View {
            let radians = angle * .pi / 180
            let length: CGFloat = isLarge ? 12 : 6
            let width: CGFloat = isLarge ? 2 : 1
            
            // Position tick marks on the outer edge of the half circle
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
}

#Preview {
    VStack(spacing: 40) {
        HalfCirclePowerMeter(power: nil)
            .frame(width: 300, height: 150)
        
        HalfCirclePowerMeter(power: 0)
            .frame(width: 300, height: 150)
        
        HalfCirclePowerMeter(power: 250)
            .frame(width: 300, height: 150)
        
        HalfCirclePowerMeter(power: 500)
            .frame(width: 300, height: 150)
        
        HalfCirclePowerMeter(power: 750)
            .frame(width: 300, height: 150)
        
        HalfCirclePowerMeter(power: 999)
            .frame(width: 300, height: 150)
    }
    .padding()
}
