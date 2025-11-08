// WatchApp.swift
// Complete Watch app example demonstrating GPS tracking

import SwiftUI
import PetTrackerFeature

// MARK: - Watch App Entry Point

@main
struct PetTrackerWatchApp: App {
    @State private var locationProvider = WatchLocationProvider()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(locationProvider)
        }
    }
}

// MARK: - Main Watch View

struct WatchContentView: View {
    @Environment(WatchLocationProvider.self) private var provider
    @State private var error: UserFacingError?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Tracking button
                trackingButton

                // Status information (when tracking)
                if provider.isTracking {
                    statusView
                }
            }
            .padding()
            .navigationTitle("PetTracker")
            .navigationBarTitleDisplayMode(.inline)
            .errorAlert(error: $error) {
                await provider.startTracking()
            }
            .task(id: provider.lastError?.localizedDescription) {
                if let internalError = provider.lastError {
                    error = UserFacingError.from(internalError)
                }
            }
        }
    }

    // MARK: - View Components

    /// Start/Stop tracking button
    @ViewBuilder
    private var trackingButton: some View {
        if provider.isTracking {
            Button {
                Task { await provider.stopTracking() }
            } label: {
                Label("Stop Tracking", systemImage: "stop.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        } else {
            Button {
                Task { await provider.startTracking() }
            } label: {
                Label("Start Tracking", systemImage: "location.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    /// Status information view
    @ViewBuilder
    private var statusView: some View {
        VStack(spacing: 12) {
            // Battery indicator
            batteryIndicator

            Divider()

            // Stats grid
            HStack(spacing: 16) {
                // Fixes sent
                VStack(spacing: 4) {
                    Text("\(provider.fixesSent)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Fixes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Accuracy (if available)
                if let location = provider.latestLocation {
                    VStack(spacing: 4) {
                        Text("±\(Int(location.horizontalAccuracyMeters))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Meters")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Connection status
            connectionIndicator
        }
        .padding()
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(12)
    }

    /// Battery level indicator
    @ViewBuilder
    private var batteryIndicator: some View {
        HStack {
            Image(systemName: batteryIcon)
                .font(.title2)
                .foregroundStyle(batteryColor)

            Text("\(Int(provider.batteryLevel * 100))%")
                .font(.headline)

            Spacer()

            // Battery warning text
            if provider.batteryLevel <= 0.10 {
                Text("Critical")
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else if provider.batteryLevel <= 0.20 {
                Text("Low")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }

    /// Connection status indicator
    @ViewBuilder
    private var connectionIndicator: some View {
        HStack {
            Circle()
                .fill(provider.isPhoneReachable ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(provider.isPhoneReachable ? "iPhone Connected" : "iPhone Offline")
                .font(.caption)

            Spacer()
        }
    }

    // MARK: - Computed Properties

    /// Battery icon based on level
    private var batteryIcon: String {
        let level = Int(provider.batteryLevel * 100)
        switch level {
        case 0..<10: return "battery.0"
        case 10..<25: return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default: return "battery.100"
        }
    }

    /// Battery color based on level
    private var batteryColor: Color {
        if provider.batteryLevel <= 0.10 {
            return .red
        } else if provider.batteryLevel <= 0.20 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Advanced Watch View (Alternative)

/// Alternative Watch view with more details
struct DetailedWatchView: View {
    @Environment(WatchLocationProvider.self) private var provider
    @State private var error: UserFacingError?

    var body: some View {
        TabView {
            // Main tracking tab
            trackingTab

            // Details tab
            if provider.isTracking {
                detailsTab
            }

            // Performance tab
            if provider.isTracking {
                performanceTab
            }
        }
        .errorAlert(error: $error) {
            await provider.startTracking()
        }
        .task(id: provider.lastError?.localizedDescription) {
            if let internalError = provider.lastError {
                error = UserFacingError.from(internalError)
            }
        }
    }

    // MARK: - Tabs

    @ViewBuilder
    private var trackingTab: some View {
        VStack(spacing: 12) {
            Text("PetTracker")
                .font(.headline)

            if provider.isTracking {
                Button("Stop") {
                    Task { await provider.stopTracking() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button("Start") {
                    Task { await provider.startTracking() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            if provider.isTracking {
                Text("\(provider.fixesSent) fixes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var detailsTab: some View {
        VStack(spacing: 8) {
            Text("Details")
                .font(.headline)

            if let location = provider.latestLocation {
                VStack(alignment: .leading, spacing: 4) {
                    detailRow(label: "Lat", value: String(format: "%.4f", location.coordinate.latitude))
                    detailRow(label: "Lon", value: String(format: "%.4f", location.coordinate.longitude))
                    detailRow(label: "Accuracy", value: "±\(Int(location.horizontalAccuracyMeters))m")
                    detailRow(label: "Sequence", value: "#\(location.sequence)")

                    if location.hasValidSpeed {
                        detailRow(label: "Speed", value: String(format: "%.1f m/s", location.speedMetersPerSecond))
                    }
                }
                .font(.caption2)
            }
        }
    }

    @ViewBuilder
    private var performanceTab: some View {
        VStack(spacing: 8) {
            Text("Performance")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                detailRow(label: "Battery", value: "\(Int(provider.batteryLevel * 100))%")
                detailRow(label: "Fixes Sent", value: "\(provider.fixesSent)")
                detailRow(label: "Connection", value: provider.isPhoneReachable ? "Online" : "Offline")
            }
            .font(.caption2)
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Workout Stats View (Optional)

/// Optional view showing workout-style stats
struct WorkoutStatsView: View {
    @Environment(WatchLocationProvider.self) private var provider
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            // Elapsed time
            Text(formatTime(elapsedTime))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.yellow)

            // Stats grid
            HStack(spacing: 16) {
                statView(value: "\(provider.fixesSent)", label: "Fixes")
                statView(value: "\(Int(provider.batteryLevel * 100))%", label: "Battery")
            }

            // Stop button
            Button("Stop Tracking") {
                Task { await provider.stopTracking() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    @ViewBuilder
    private func statView(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Compact Watch View (For smaller screens)

/// Compact view optimized for smaller Watch screens
struct CompactWatchView: View {
    @Environment(WatchLocationProvider.self) private var provider

    var body: some View {
        VStack(spacing: 8) {
            // Battery arc
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: provider.batteryLevel)
                    .stroke(batteryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(provider.batteryLevel * 100))%")
                    .font(.headline)
            }

            // Start/Stop button
            if provider.isTracking {
                Button {
                    Task { await provider.stopTracking() }
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Task { await provider.startTracking() }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }

            // Fixes count
            if provider.isTracking {
                Text("\(provider.fixesSent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var batteryColor: Color {
        if provider.batteryLevel <= 0.10 {
            return .red
        } else if provider.batteryLevel <= 0.20 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Main Watch View") {
    WatchContentView()
        .environment(WatchLocationProvider())
}

#Preview("Detailed Watch View") {
    DetailedWatchView()
        .environment(WatchLocationProvider())
}

#Preview("Compact Watch View") {
    CompactWatchView()
        .environment(WatchLocationProvider())
}
#endif
