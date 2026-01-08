//
//  Dashboard.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//
import SwiftUI

struct Dashboard: View {
    @State private var viewModel = ViewModel()
    @State private var showingSettings = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some View {
        VStack(spacing: 10) {

            
            // Duration Timer with Settings Button
            HStack(alignment: .center, spacing: 16) {
                Spacer()
                
                Text(viewModel.formattedElapsedTime)
                    .font(.system(size: 45, weight: .medium, design: .monospaced))

                Spacer()
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.title)
                        .foregroundStyle(Color("fairyRed"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            // Top meter (half circle)
            Group {
                switch viewModel.layout {
                case .A:
                    HalfCircleSpeedometer(speed: viewModel.speed)
                case .B:
                    HalfCirclePowerMeter(power: viewModel.power)
                case .C:
                    HalfCircleHeartRateMeter(heartRate: viewModel.heartRate)
                }
            }
            .frame(width: 300, height: 150)
            .padding(.horizontal)
            .transition(.opacity.combined(with: .scale))

            // Bottom meters (two circles)
            HStack(spacing: 20) {
                Group {
                    switch viewModel.layout {
                    case .A:
                        PowerMeter(power: viewModel.power)
                    case .B:
                        HeartRateMeter(heartRate: viewModel.heartRate)
                    case .C:
                        Speedometer(speed: viewModel.speed)
                    }
                }
                .frame(width: 150, height: 150)
                .transition(.opacity.combined(with: .scale))

                Button {
                    viewModel.rotateMeters()
                } label: {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(Color("fairyRed"))
                        .fixedSize()
                        .padding(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("fairyRed"), lineWidth: 1)
                        }
                }

                Group {
                    switch viewModel.layout {
                    case .A:
                        HeartRateMeter(heartRate: viewModel.heartRate)
                    case .B:
                        Speedometer(speed: viewModel.speed)
                    case .C:
                        PowerMeter(power: viewModel.power)
                    }
                }
                .frame(width: 150, height: 150)
                .transition(.opacity.combined(with: .scale))

            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
            .padding(.horizontal)


            VStack(alignment: .center) {
                Text("\(Int(viewModel.cadence))")
                    .font(.system(size: 32, weight: .bold))
                Text("RPM")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)


            Divider()
                .frame(height: 2)

            Group {
                HStack(spacing:15) {

                    VStack(alignment: .center) {
                        Text(viewModel.distanceValue)
                            .font(.system(size: 32, weight: .bold))

                        HStack(spacing: 2) {
                            Text("distance")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)

                            Text(viewModel.distanceUnit)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 100)

                    VStack(alignment: .center) {
                        Text(String(format: "%.0f", viewModel.motionManager.gainedElevationInFeet))
                            .font(.system(size: 32, weight: .bold))
                        Text("gained elevation")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100)


                    VStack(alignment: .center) {
                        Text(String(format: "%.0f", viewModel.motionManager.currentElevationInFeet))
                            .font(.system(size: 32, weight: .bold))
                        Text("curr elevation")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100)


                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)

            // Map
            Group {
                if viewModel.mapViewToggle {
                    MapView()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Button("Map") {
                        viewModel.mapViewToggle = true
                    }
                }
            }

            Spacer()
        }
        .overlay(alignment: .bottom) {
            ControlPanel(
                isRunning: viewModel.isRunning,
                onStartPause: {
                    viewModel.toggle()
                },
                onReset: {
                    viewModel.reset()
                }
            )
            .padding()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                heartRateMonitor: viewModel.heartRateMonitor,
                powerMonitor: viewModel.powerMonitor
            )
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}

struct ControlPanel: View {
    let isRunning: Bool
    let onStartPause: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onStartPause) {
                HStack {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                }
                .font(.title)
                .foregroundStyle(Color("fairyRed"))
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Button(action: onReset) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                }
                .font(.title)
                .foregroundStyle(Color("fairyRed"))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

extension Dashboard {

    enum MeterLayout {
        case A
        case B
        case C
    }

    @Observable
    final class ViewModel {

        var layout: MeterLayout = .A
        
        let motionManager = MotionManager()
        let heartRateMonitor = HeartRateMonitor()
        let powerMonitor = PowerMonitor()

        var cadence: Double = 0.0
        var speed: Double = 0.0
        var power: Double? = nil
        var heartRate: Double = 0.0
        var isRunning: Bool = false
        var elapsedTime: TimeInterval = 0

        var mapViewToggle: Bool = false

        // Computed property to check if heart rate monitor is connected
        var isHeartRateConnected: Bool {
            heartRateMonitor.isConnected
        }
        
        // Computed properties for smart distance display
        var distanceValue: String {
            let miles = motionManager.distanceInMiles
            if miles < 0.25 {
                // Show in feet
                let feet = miles * 5280 // 1 mile = 5280 feet
                return String(format: "%.0f", feet)
            } else {
                // Show in miles
                return String(format: "%.1f", miles)
            }
        }
        
        var distanceUnit: String {
            motionManager.distanceInMiles < 0.25 ? "feet" : "miles"
        }
        
        // Simulation mode for testing UI (e.g., in Simulator)
        var isSimulationMode: Bool = false
        
        private var speedTask: Task<Void, Never>?
        private var timerTask: Task<Void, Never>?
        private var heartRateTask: Task<Void, Never>?
        private var powerTask: Task<Void, Never>?
        private var simulationTask: Task<Void, Never>?
        private var startTime: Date?
        private var pausedTime: TimeInterval = 0
        
        init() {
            // Start monitoring heart rate immediately
            startHeartRateMonitoring()
            // Start monitoring power immediately
            startPowerMonitoring()
            
            // Enable simulation mode on Simulator
            #if targetEnvironment(simulator)
            isSimulationMode = true
            #endif
        }
        
        var formattedElapsedTime: String {
            let hours = Int(elapsedTime) / 3600
            let minutes = Int(elapsedTime) / 60 % 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        
        func toggle() {
            if isRunning {
                pause()
            } else {
                start()
            }
        }
        
        func reset() {
            stop()
            motionManager.stopTracking()
            motionManager.resetTracking()
            speed = 0.0
            // Don't reset heart rate or power - keep showing live data from monitors
            elapsedTime = 0
            pausedTime = 0
            startTime = nil
            if !powerMonitor.isConnected {
                power = nil
            }
            if !heartRateMonitor.isConnected {
                heartRate = 0.0
            }
        }

        func rotateMeters() {
            withAnimation(.easeInOut(duration: 1.0)) {
                switch layout {
                case .A:
                    layout = .B
                case .B:
                    layout = .C
                case .C:
                    layout = .A
                }
            }
        }
        
        // Continuous heart rate monitoring (independent of workout state)
        private func startHeartRateMonitoring() {
            heartRateTask = Task { @MainActor in
                while !Task.isCancelled {
                    // Use Bluetooth heart rate monitor
                    if heartRateMonitor.isConnected && heartRateMonitor.heartRate > 0 {
                        heartRate = heartRateMonitor.heartRate
                    } else if !isSimulationMode && heartRate > 0 && !heartRateMonitor.isConnected {
                        // Only reset if not in simulation mode and monitor not connected
                        heartRate = 0.0
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        
        // Continuous power monitoring (independent of workout state)
        private func startPowerMonitoring() {
            powerTask = Task { @MainActor in
                while !Task.isCancelled {
                    // Always update power from monitor if available and connected
                    if powerMonitor.isConnected {
                        // Check if cadence should timeout and reset to 0
                        powerMonitor.checkCadenceTimeout()
                        
                        // Use 3-second average power
                        power = powerMonitor.threeSecondPower
                        cadence = powerMonitor.cadence
                    } else if !isSimulationMode {
                        // Only set to nil when not connected AND not in simulation mode
                        power = nil
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        
        // Continuous speed monitoring
        private func startSpeedMonitoring() {
            speedTask = Task { @MainActor in
                while !Task.isCancelled && isRunning {
                    // Use real speed from motion manager
                    speed = motionManager.speed >= 0 ? motionManager.speed : 0.0
                    
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        
        // Simulation mode for testing UI (generates fake data)
        private func startSimulation() {
            guard isSimulationMode else { return }
            
            simulationTask = Task { @MainActor in
                // Linear speed array
                let speedArray: [Double] = [10, 12, 14, 15, 18, 20]
                var currentIndex = 0
                var goingForward = true
                
                while !Task.isCancelled && isRunning {
                    // Set speed from array
                    speed = speedArray[currentIndex]
                    
                    // Move to next index
                    if goingForward {
                        if currentIndex < speedArray.count - 1 {
                            currentIndex += 1
                        } else {
                            goingForward = false
                            currentIndex -= 1
                        }
                    } else {
                        if currentIndex > 0 {
                            currentIndex -= 1
                        } else {
                            goingForward = true
                            currentIndex += 1
                        }
                    }
                    
                    // Generate simulated power if not connected to real power meter
                    if !powerMonitor.isConnected {
                        // Power roughly correlates with speed
                        let basePower = speed * 12 // Rough approximation
                        let powerVariation = Double.random(in: -20...20)
                        power = max(0, min(999, basePower + powerVariation))
                    }
                    
                    // Generate simulated heart rate if not connected
                    if !heartRateMonitor.isConnected && heartRate == 0 {
                        heartRate = 100 // Start at resting
                    }
                    
                    if !heartRateMonitor.isConnected && heartRate > 0 {
                        // Heart rate gradually increases with speed
                        let targetHR = 100 + (speed * 3) // Rough correlation
                        if heartRate < targetHR {
                            heartRate = min(targetHR, heartRate + Double.random(in: 0.5...1.5))
                        } else {
                            heartRate = max(targetHR, heartRate - Double.random(in: 0.5...1.5))
                        }
                        heartRate = max(60, min(200, heartRate))
                    }
                    
                    try? await Task.sleep(for: .seconds(0.5))
                }
            }
        }

        private func start() {
            isRunning = true
            
            // Start motion tracking
            motionManager.startTracking()
            
            if startTime == nil {
                // First time starting
                startTime = Date()
                elapsedTime = 0
                pausedTime = 0
            } else {
                // Resuming from pause
                startTime = Date().addingTimeInterval(-pausedTime)
            }
            
            // Timer task to update elapsed time
            timerTask = Task { @MainActor in
                while !Task.isCancelled && isRunning {
                    if let startTime = startTime {
                        elapsedTime = Date().timeIntervalSince(startTime)
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
            

            // Start simulation if enabled, otherwise start real speed monitoring
            if isSimulationMode {
                startSimulation()
            } else {
                startSpeedMonitoring()
            }
        }
        
        private func pause() {
            isRunning = false
            pausedTime = elapsedTime
            motionManager.stopTracking()
            speedTask?.cancel()
            speedTask = nil
            simulationTask?.cancel()
            simulationTask = nil
            timerTask?.cancel()
            timerTask = nil
        }
        
        private func stop() {
            isRunning = false
            motionManager.stopTracking()
            speedTask?.cancel()
            speedTask = nil
            simulationTask?.cancel()
            simulationTask = nil
            timerTask?.cancel()
            timerTask = nil
        }
        
        deinit {
            speedTask?.cancel()
            simulationTask?.cancel()
            timerTask?.cancel()
            heartRateTask?.cancel()
            powerTask?.cancel()
        }
    }
}
