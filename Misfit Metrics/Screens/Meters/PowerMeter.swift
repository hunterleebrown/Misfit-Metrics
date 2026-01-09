//
//  PowerMeter.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//

import SwiftUI

struct PowerMeter: View {
    let power: Double? // 0 to 999 watts, nil if not available
    
    private let startAngle: Angle = .degrees(90) // Start at 6 o'clock (90° in canvas coordinates)
    private let totalDegrees: Double = 350 // Total sweep
    private let maxPower: Double = 999
    private let tickInterval: Double = 50
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size * 0.4
            
            ZStack {
                if let power = power {
                    // Background circle
                    // Power pie wedge (filled from center)
                    PieWedge(
                        startAngle: startAngle,
                        endAngle: .degrees(startAngle.degrees + (powerRatio(for: power) * totalDegrees))
                    )
                    .fill(Color("fairyRed"))
                    .frame(width: radius * 2, height: radius * 2)
                    
                    // Tick marks
                    ForEach(0..<Int(maxPower / tickInterval) + 1, id: \.self) { index in
                        let watts = Double(index) * tickInterval
                        // Adjust angle to match the rotated circle (add 90° to align)
                        let angle = 90 + (watts / maxPower) * totalDegrees
                        
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
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text("3 sec")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func powerRatio(for power: Double) -> Double {
        min(max(power / maxPower, 0), 1)
    }
}

#Preview {
    VStack(spacing: 40) {
        PowerMeter(power: nil)
            .frame(width: 150, height: 150)
        
        PowerMeter(power: 0)
            .frame(width: 150, height: 150)
        
        PowerMeter(power: 250)
            .frame(width: 150, height: 150)
        
        PowerMeter(power: 500)
            .frame(width: 150, height: 150)
        
        PowerMeter(power: 750)
            .frame(width: 150, height: 150)
        
        PowerMeter(power: 999)
            .frame(width: 150, height: 150)
    }
    .padding()
}
