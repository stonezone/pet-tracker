import SwiftUI
import PetTrackerFeature

/// Main content view for PetTracker Watch app
///
/// Displays:
/// - Tracking status
/// - Battery level
/// - GPS accuracy
/// - Number of fixes sent
/// - Start/Stop tracking button
struct WatchContentView: View {

    @Environment(WatchLocationProvider.self) private var locationProvider

    var body: some View {
        VStack(spacing: 12) {

            // Status Indicator
            Circle()
                .fill(locationProvider.isTracking ? Color.green : Color.gray)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )

            // Tracking Status
            Text(locationProvider.isTracking ? "Tracking" : "Stopped")
                .font(.headline)

            if locationProvider.isTracking {

                // Battery Level
                HStack {
                    Image(systemName: batteryIcon(for: Int(locationProvider.batteryLevel * 100)))
                        .foregroundStyle(batteryColor(for: Int(locationProvider.batteryLevel * 100)))
                    Text("\(Int(locationProvider.batteryLevel * 100))%")
                        .font(.caption)
                }

                // GPS Accuracy
                if let location = locationProvider.latestLocation {
                    HStack {
                        Image(systemName: "scope")
                            .foregroundStyle(.green)
                        Text("±\(Int(location.horizontalAccuracyMeters))m")
                            .font(.caption)
                    }
                }

                // Fixes Sent
                HStack {
                    Image(systemName: "arrow.up.circle")
                        .foregroundStyle(.blue)
                    Text("\(locationProvider.fixesSent) sent")
                        .font(.caption)
                }

                // Phone Reachability
                HStack {
                    Circle()
                        .fill(locationProvider.isPhoneReachable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(locationProvider.isPhoneReachable ? "Connected" : "Queued")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Start/Stop Button
            Button {
                Task {
                    if locationProvider.isTracking {
                        await locationProvider.stopTracking()
                    } else {
                        await locationProvider.startTracking()
                    }
                }
            } label: {
                Label(
                    locationProvider.isTracking ? "Stop" : "Start",
                    systemImage: locationProvider.isTracking ? "stop.circle.fill" : "play.circle.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(locationProvider.isTracking ? .red : .green)
        }
        .padding()
    }

    // MARK: - Helper Methods

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
    WatchContentView()
        .environment(WatchLocationProvider())
}
