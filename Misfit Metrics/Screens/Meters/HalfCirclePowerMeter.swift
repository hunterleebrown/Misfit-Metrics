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
