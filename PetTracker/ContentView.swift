import SwiftUI
import PetTrackerFeature
import OSLog

/// Main content view for PetTracker iOS app
///
/// Displays:
/// - Pet location on map
/// - Distance from owner to pet
/// - Battery level
/// - GPS accuracy
/// - Connection status with error handling
struct ContentView: View {

    @Environment(PetLocationManager.self) private var locationManager

    /// Current user-facing error to display
    @State private var currentError: UserFacingError?

    init() {
        Logger.ui.debug("ContentView initializing")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                // Connection Status with retry capability
                ConnectionStatusView(
                    isActivated: locationManager.isSessionActivated,
                    isReachable: locationManager.isWatchReachable,
                    statusMessage: locationManager.connectionStatus
                ) {
                    await retryConnection()
                }
                .padding(.horizontal)

                if let location = locationManager.latestPetLocation {

                    // Location Information
                    VStack(alignment: .leading, spacing: 12) {

                        // Distance
                        if let distance = locationManager.distanceFromOwner {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.blue)
                                Text("Distance: \(Int(distance))m")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }

                        // Battery
                        if let battery = locationManager.petBatteryLevel {
                            HStack {
                                Image(systemName: batteryIcon(for: battery))
                                    .foregroundStyle(batteryColor(for: battery))
                                Text("Battery: \(battery)%")
                                    .font(.title3)
                            }
                        }

                        // GPS Accuracy
                        if let accuracy = locationManager.accuracyMeters {
                            HStack {
                                Image(systemName: "scope")
                                    .foregroundStyle(.green)
                                Text("Accuracy: ±\(Int(accuracy))m")
                                    .font(.title3)
                            }
                        }

                        // Coordinates
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coordinates:")
                                .font(.headline)
                            Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Lon: \(location.coordinate.longitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Last Update Time
                        if let age = locationManager.timeSinceLastUpdate {
                            Text("Updated \(Int(age))s ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Location History
                    VStack(alignment: .leading) {
                        Text("Location History")
                            .font(.headline)
                        Text("\(locationManager.locationHistory.count) fixes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()

                } else {

                    // No Location Data
                    VStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)

                        Text("Waiting for pet location...")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text("Make sure the Apple Watch is paired and tracking is started.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("PetTracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        locationManager.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .task {
                Logger.ui.debug("ContentView starting location tracking task")
                await locationManager.startTracking()
                Logger.ui.debug("ContentView location tracking task completed")
            }
            .task(id: locationManager.lastError?.localizedDescription) {
                // Map internal errors to user-facing errors when they change
                if let error = locationManager.lastError {
                    Logger.ui.warning("Error detected: \(error.localizedDescription)")
                    currentError = UserFacingError.from(error)
                }
            }
            .errorAlert(error: $currentError) {
                // Retry action
                await retryConnection()
            }
        }
    }

    // MARK: - Helper Methods

    /// Retries connection by restarting tracking
    private func retryConnection() async {
        Logger.ui.info("Retrying connection...")
        currentError = nil // Clear current error
        await locationManager.startTracking()
    }

    private func batteryIcon(for level: Int) -> String {
        switch level {
        case 0...20: return "battery.0"
        case 21...40: return "battery.25"
        case 41...60: return "battery.50"
        case 61...80: return "battery.75"
        default: return "battery.100"
        }
    }

    private func batteryColor(for level: Int) -> Color {
        switch level {
        case 0...20: return .red
        case 21...40: return .orange
        default: return .green
        }
    }
}

#Preview {
    ContentView()
        .environment(PetLocationManager())
}
