//
//  Dashboard.swift
//  Misfit Metrics
//
//  Created by Hunter Lee Brown on 1/7/26.
//
import SwiftUI
import PhotosUI
import SwiftData

struct Dashboard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ViewModel()
    @State private var showingSettings = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                
                VStack {
                    
                    // Duration Timer with Settings Button
                    HStack(alignment: .center, spacing: 16) {
                        NavigationLink {
                            MisfitAdventures()
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.title)
                                .foregroundStyle(Color("fairyRed"))
                        }
                        .buttonStyle(.plain)
                        
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
                }
                .background {
                    Group {
                        switch viewModel.backgroundLook {
                        case .plain:
                            EmptyView()
                        case .bike:
                            Image(systemName: "bicycle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(0.15)
                                .blur(radius: 2)
                        case .rainbow:
                            RainbowCircles()
                                .opacity(0.5)
                        case .earth:
                            Image("globe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(0.3)
                                .blur(radius: 2)
                        case .userPhoto:
                            if let photo = viewModel.userBackgroundPhoto {
                                GeometryReader { geometry in
                                    Image(uiImage: photo)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                        .opacity(0.3)
                                        .blur(radius: 2)
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    }
                }
                
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
                
                Spacer()
                
                // Map
                Group {
                    if viewModel.mapViewToggle {
                        MapView(isPresented: $viewModel.mapViewToggle)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        Button("Map") {
                            viewModel.mapViewToggle = true
                        }
                        .foregroundStyle(Color("fairyRed"))
                    }
                }
                
                Spacer()
                
                Group {
                    ControlPanel(viewModel: viewModel)
                        .padding()
                        .frame(height: 50)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(dashboardViewModel: viewModel)
            }
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
            .onAppear {
                viewModel.modelContext = modelContext
            }
        }
    }
}

extension Dashboard {
    struct ControlPanel: View {
        @Bindable var viewModel: Dashboard.ViewModel

        var body: some View {
            HStack(spacing: 20) {
                Button(action: { viewModel.toggle() }) {
                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(Color("fairyRed"))
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.stopWorkout() }) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundStyle(Color("fairyRed"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title)
                        .foregroundStyle(Color("fairyRed"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Button(action: {
                    viewModel.isSimulationMode.toggle()
                    viewModel.startSimulation()
                }) {
                    Image(systemName: "questionmark.circle.dashed")
                        .font(.title)
                        .foregroundStyle(Color("fairyRed"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}

extension Dashboard {

    enum MeterLayout {
        case A
        case B
        case C
    }

    enum BackgroundLook: String, Codable {
        case earth
        case bike
        case rainbow
        case plain
        case userPhoto
    }

    @Observable
    final class ViewModel {

        var layout: MeterLayout = .A
        var backgroundLook: BackgroundLook = .bike {
            didSet {
                UserDefaults.standard.set(backgroundLook.rawValue, forKey: "backgroundLook")
            }
        }
        
        // User photo for background
        var userBackgroundPhoto: UIImage? = nil {
            didSet {
                savePhotoToUserDefaults()
            }
        }
        var photoPickerItem: PhotosPickerItem? = nil {
            didSet {
                Task {
                    await loadPhoto()
                }
            }
        }

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
        
        // SwiftData
        var modelContext: ModelContext?
        private var currentAdventure: MisfitAdventure?
        private var recordTask: Task<Void, Never>?

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
            // Load saved background look from UserDefaults
            if let rawValue = UserDefaults.standard.string(forKey: "backgroundLook"),
               let savedLook = BackgroundLook(rawValue: rawValue) {
                self.backgroundLook = savedLook
            }
            
            // Start monitoring heart rate immediately
            startHeartRateMonitoring()
            // Start monitoring power immediately
            startPowerMonitoring()
            
            // Load saved photo from UserDefaults
            loadPhotoFromUserDefaults()
            
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
            
            // Re-enable auto-lock when reset
            UIApplication.shared.isIdleTimerDisabled = false
            
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
            
            // Delete the current adventure if it exists (user cancelled)
            if let adventure = currentAdventure, let modelContext = modelContext {
                modelContext.delete(adventure)
                try? modelContext.save()
                currentAdventure = nil
            }
            
            // Stop recording
            recordTask?.cancel()
            recordTask = nil
        }
        
        func stopWorkout() {
            // Stop the workout and finalize the adventure
            stop()
            
            // Re-enable auto-lock when stopped
            UIApplication.shared.isIdleTimerDisabled = false
            
            motionManager.stopTracking()
            
            // Finalize the adventure with summary data
            if let adventure = currentAdventure, let modelContext = modelContext {
                adventure.endTime = Date()
                adventure.totalDistance = motionManager.distanceInMiles
                
                // Calculate average heart rate from records (if we had heart rate data)
                let heartRates = adventure.records.compactMap { _ in heartRate > 0 ? Int(heartRate) : nil }
                if !heartRates.isEmpty {
                    adventure.averageHeartRate = heartRates.reduce(0, +) / heartRates.count
                }
                
                // Calculate average power from records (if we had power data)
                let powers = adventure.records.compactMap { _ in power }
                if !powers.isEmpty {
                    adventure.averagePower = powers.reduce(0, +) / Double(powers.count)
                }
                
                // Save the final state
                try? modelContext.save()
                
                // Clear current adventure
                currentAdventure = nil
            }
            
            // Stop recording
            recordTask?.cancel()
            recordTask = nil
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
        func startSimulation() {
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
            
            // Prevent device from auto-locking during workout
            UIApplication.shared.isIdleTimerDisabled = true
            
            // Start motion tracking
            motionManager.startTracking()
            
            if startTime == nil {
                // First time starting - create new adventure
                startTime = Date()
                elapsedTime = 0
                pausedTime = 0
                
                // Create new MisfitAdventure
                if let modelContext = modelContext {
                    let adventure = MisfitAdventure(startTime: Date())
                    modelContext.insert(adventure)
                    currentAdventure = adventure
                    
                    // Start recording data every second
                    startRecording()
                }
            } else {
                // Resuming from pause
                startTime = Date().addingTimeInterval(-pausedTime)
                
                // Resume recording if we have an adventure
                if currentAdventure != nil {
                    startRecording()
                }
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
            
            // Re-enable auto-lock when paused
            UIApplication.shared.isIdleTimerDisabled = false
            
            motionManager.stopTracking()
            speedTask?.cancel()
            speedTask = nil
            simulationTask?.cancel()
            simulationTask = nil
            timerTask?.cancel()
            timerTask = nil
            
            // Stop recording
            recordTask?.cancel()
            recordTask = nil
        }
        
        // Start recording data every second
        private func startRecording() {
            recordTask?.cancel() // Cancel any existing task
            
            recordTask = Task { @MainActor in
                while !Task.isCancelled && isRunning {
                    // Create a new record with current data
                    if let adventure = currentAdventure, let modelContext = modelContext {
                        let record = MisfitRecord(
                            timestamp: Date(),
                            speed: speed
                        )
                        
                        modelContext.insert(record)
                        adventure.records.append(record)
                        
                        // Save context periodically
                        try? modelContext.save()
                    }
                    
                    try? await Task.sleep(for: .seconds(1))
                }
            }
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
        
        // Load photo from PhotosPicker
        @MainActor
        private func loadPhoto() async {
            guard let photoPickerItem else { return }
            
            do {
                if let data = try await photoPickerItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    self.userBackgroundPhoto = uiImage
                    self.backgroundLook = .userPhoto
                }
            } catch {
                print("Error loading photo: \(error.localizedDescription)")
            }
        }
        
        // Save photo to UserDefaults
        private func savePhotoToUserDefaults() {
            guard let photo = userBackgroundPhoto else {
                // If photo is nil, remove it from UserDefaults
                UserDefaults.standard.removeObject(forKey: "userBackgroundPhoto")
                return
            }
            
            // Compress image to reduce storage size (0.8 quality is good balance)
            if let imageData = photo.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(imageData, forKey: "userBackgroundPhoto")
            }
        }
        
        // Load photo from UserDefaults
        private func loadPhotoFromUserDefaults() {
            guard let imageData = UserDefaults.standard.data(forKey: "userBackgroundPhoto"),
                  let image = UIImage(data: imageData) else {
                return
            }
            
            self.userBackgroundPhoto = image
            // Don't automatically set backgroundLook here - let user choose when to display it
        }
    }
}
