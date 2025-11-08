// BasicUsage.swift
// Complete iOS app example demonstrating PetTracker integration

import SwiftUI
import PetTrackerFeature

// MARK: - App Entry Point

@main
struct PetTrackerBasicApp: App {
    // Create @State for PetLocationManager (persists for app lifetime)
    @State private var locationManager = PetLocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)  // Inject into SwiftUI environment
                .task {
                    // Start tracking when app launches
                    await locationManager.startTracking()
                }
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    // Access PetLocationManager from environment
    @Environment(PetLocationManager.self) private var manager

    // Local state for error handling
    @State private var error: UserFacingError?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Connection status banner
                    connectionStatusSection

                    // Pet location section (if available)
                    if let location = manager.latestPetLocation {
                        petLocationSection(location)
                    } else {
                        waitingForLocationView
                    }

                    // Navigation to history view
                    if !manager.locationHistory.isEmpty {
                        NavigationLink {
                            LocationHistoryView()
                        } label: {
                            Label("View Trail (\(manager.locationHistory.count) fixes)", systemImage: "map")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("PetTracker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Clear History") {
                            manager.clearHistory()
                        }
                        Button("Stop Tracking") {
                            manager.stopTracking()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .errorAlert(error: $error) {
                // Retry action when user taps "Retry" in error alert
                await manager.startTracking()
            }
            .task(id: manager.lastError?.localizedDescription) {
                // Map internal errors to user-facing errors
                if let internalError = manager.lastError {
                    error = UserFacingError.from(internalError)
                }
            }
        }
    }

    // MARK: - View Components

    /// Connection status banner
    @ViewBuilder
    private var connectionStatusSection: some View {
        ConnectionStatusView(
            isActivated: manager.isSessionActivated,
            isReachable: manager.isWatchReachable,
            statusMessage: manager.connectionStatus
        ) {
            // Retry action when user taps retry button
            await manager.startTracking()
        }
    }

    /// Pet location information card
    @ViewBuilder
    private func petLocationSection(_ location: LocationFix) -> some View {
        VStack(spacing: 16) {
            // Distance to pet
            if let distance = manager.distanceFromOwner {
                VStack(spacing: 4) {
                    Text("\(Int(distance))m")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)

                    Text("Distance to Pet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Metrics grid
            HStack(spacing: 32) {
                // Battery
                VStack(spacing: 4) {
                    Image(systemName: batteryIcon(for: location.batteryPercentage))
                        .font(.title2)
                        .foregroundStyle(location.batteryPercentage < 20 ? .red : .green)

                    Text("\(location.batteryPercentage)%")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("Battery")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Accuracy
                VStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    Text("±\(Int(location.horizontalAccuracyMeters))m")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("Accuracy")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Time since update
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    Text("\(Int(location.age))s")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("Last Update")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Coordinates
            VStack(spacing: 4) {
                Text("Coordinates")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .fontDesign(.monospaced)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    /// Waiting for location placeholder
    @ViewBuilder
    private var waitingForLocationView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Waiting for pet location...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Make sure PetTracker is running on Apple Watch")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // MARK: - Helpers

    /// Returns appropriate battery icon for level
    private func batteryIcon(for level: Int) -> String {
        switch level {
        case 0..<10: return "battery.0"
        case 10..<25: return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default: return "battery.100"
        }
    }
}

// MARK: - Location History View

struct LocationHistoryView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        List {
            ForEach(manager.locationHistory.reversed()) { fix in
                LocationHistoryRow(fix: fix)
            }
        }
        .navigationTitle("Location Trail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    manager.clearHistory()
                }
            }
        }
    }
}

// MARK: - Location History Row

struct LocationHistoryRow: View {
    let fix: LocationFix

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sequence number and timestamp
            HStack {
                Text("Fix #\(fix.sequence)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)

                Spacer()

                Text(timeAgo(fix.age))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Coordinates
            Text("\(String(format: "%.6f", fix.coordinate.latitude)), \(String(format: "%.6f", fix.coordinate.longitude))")
                .font(.caption)
                .fontDesign(.monospaced)

            // Metrics
            HStack(spacing: 16) {
                // Accuracy
                Label {
                    Text("±\(Int(fix.horizontalAccuracyMeters))m")
                        .font(.caption2)
                } icon: {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                // Battery
                Label {
                    Text("\(fix.batteryPercentage)%")
                        .font(.caption2)
                } icon: {
                    Image(systemName: "battery.100")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                // Speed (if valid)
                if fix.hasValidSpeed {
                    Label {
                        Text("\(String(format: "%.1f", fix.speedMetersPerSecond))m/s")
                            .font(.caption2)
                    } icon: {
                        Image(systemName: "gauge")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Formats time interval as human-readable string
    private func timeAgo(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60

        if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "\(Int(seconds))s ago"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Main View") {
    ContentView()
        .environment(PetLocationManager())
}

#Preview("History View") {
    NavigationStack {
        LocationHistoryView()
            .environment(PetLocationManager())
    }
}
#endif
