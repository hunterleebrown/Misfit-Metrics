//
//  RainbowCircles.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/9/26.
//

import SwiftUI

struct RainbowCircles: View {

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach((0..<20).reversed(), id: \.self) { index in
                    let progress = Double(index) / 19.0
                    // Create full rainbow spectrum: Red -> Orange -> Yellow -> Green -> Blue -> Purple
                    let color = Color(
                        hue: progress, // 0.0 (red) through 1.0 (back to red) covers full spectrum
                        saturation: 0.8,
                        brightness: 0.9
                    )

                    // Calculate size based on the geometry and index
                    // Start with the largest circle fitting the bounds, then shrink
                    let maxDimension = min(geometry.size.width, geometry.size.height)
                    let size = maxDimension * (Double(index + 1) / 20.0)

                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .opacity(0.3)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .blur(radius: 2)
        }
    }
}
