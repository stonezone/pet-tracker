// ErrorHandling.swift
// Example demonstrating comprehensive error handling with retry logic

import SwiftUI
import PetTrackerFeature

// MARK: - App with Error Handling

@main
struct PetTrackerErrorHandlingApp: App {
    @State private var locationManager = PetLocationManager()

    var body: some Scene {
        WindowGroup {
            ErrorHandlingDemoView()
                .environment(locationManager)
                .task {
                    await locationManager.startTracking()
                }
        }
    }
}

// MARK: - Main View with Error Handling

struct ErrorHandlingDemoView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var error: UserFacingError?
    @State private var retryCount: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Connection status with retry
                ConnectionStatusView(
                    isActivated: manager.isSessionActivated,
                    isReachable: manager.isWatchReachable,
                    statusMessage: manager.connectionStatus
                ) {
                    await retryWithBackoff()
                }

                // Error status card
                if let currentError = error {
                    errorStatusCard(currentError)
                }

                // Content
                if let location = manager.latestPetLocation {
                    locationCard(location)
                } else if error == nil {
                    loadingView
                }

                Spacer()

                // Manual retry button
                if error != nil {
                    retryButton
                }
            }
            .padding()
            .navigationTitle("Error Handling Demo")
            .errorAlert(error: $error) {
                // Retry action from alert
                await retryWithBackoff()
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

    /// Error status card showing error details
    @ViewBuilder
    private func errorStatusCard(_ error: UserFacingError) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Error title with severity indicator
            HStack {
                severityIndicator(error.severity)

                Text(error.errorDescription ?? "Error")
                    .font(.headline)

                Spacer()

                if retryCount > 0 {
                    Text("Retry #\(retryCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Failure reason
            if let reason = error.failureReason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Recovery suggestion
            if let suggestion = error.recoverySuggestion {
                Label {
                    Text(suggestion)
                        .font(.caption)
                } icon: {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                }
            }

            // Error metadata
            HStack {
                Label {
                    Text(error.isRetryable ? "Retryable" : "Requires Action")
                        .font(.caption2)
                } icon: {
                    Image(systemName: error.isRetryable ? "arrow.clockwise" : "exclamationmark.triangle")
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text("Severity: \(severityName(error.severity))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(errorBackgroundColor(error.severity))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    /// Severity indicator circle
    @ViewBuilder
    private func severityIndicator(_ severity: UserFacingError.Severity) -> some View {
        Circle()
            .fill(severityColor(severity))
            .frame(width: 12, height: 12)
    }

    /// Location information card
    @ViewBuilder
    private func locationCard(_ location: LocationFix) -> some View {
        VStack(spacing: 16) {
            // Distance
            if let distance = manager.distanceFromOwner {
                Text("\(Int(distance))m away")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            // Metrics
            HStack(spacing: 24) {
                metricView(
                    icon: "battery.100",
                    value: "\(location.batteryPercentage)%",
                    label: "Battery",
                    color: location.batteryPercentage < 20 ? .red : .green
                )

                metricView(
                    icon: "location.fill",
                    value: "±\(Int(location.horizontalAccuracyMeters))m",
                    label: "Accuracy",
                    color: .blue
                )

                metricView(
                    icon: "clock.fill",
                    value: "\(Int(location.age))s",
                    label: "Age",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    /// Metric view with icon, value, and label
    @ViewBuilder
    private func metricView(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// Loading view
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Connecting to Watch...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }

    /// Manual retry button
    @ViewBuilder
    private var retryButton: some View {
        Button {
            Task {
                await retryWithBackoff()
            }
        } label: {
            Label("Retry Connection", systemImage: "arrow.clockwise")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Helpers

    /// Retry with exponential backoff
    private func retryWithBackoff() async {
        retryCount += 1

        // Calculate backoff delay (exponential with max 30 seconds)
        let delay = min(pow(2.0, Double(retryCount - 1)), 30.0)

        Logger.connectivity.info("Retry attempt #\(self.retryCount) after \(delay)s backoff")

        // Wait before retry
        try? await Task.sleep(for: .seconds(delay))

        // Clear error before retry
        error = nil

        // Attempt to start tracking
        await manager.startTracking()

        // Reset retry count on success
        if manager.isSessionActivated && manager.lastError == nil {
            Logger.connectivity.info("Retry successful, resetting retry count")
            retryCount = 0
        }
    }

    /// Returns color for severity level
    private func severityColor(_ severity: UserFacingError.Severity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }

    /// Returns background color for severity level
    private func errorBackgroundColor(_ severity: UserFacingError.Severity) -> Color {
        switch severity {
        case .info: return Color.blue.opacity(0.1)
        case .warning: return Color.orange.opacity(0.1)
        case .error: return Color.red.opacity(0.1)
        case .critical: return Color.purple.opacity(0.1)
        }
    }

    /// Returns human-readable severity name
    private func severityName(_ severity: UserFacingError.Severity) -> String {
        switch severity {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Advanced Error Handling Examples

/// Example: Custom error monitoring service
@MainActor
class ErrorMonitor: ObservableObject {
    @Published var errorLog: [ErrorLogEntry] = []

    struct ErrorLogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let error: UserFacingError
        let retryAttempts: Int
    }

    func logError(_ error: UserFacingError, retryAttempts: Int) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            error: error,
            retryAttempts: retryAttempts
        )
        errorLog.append(entry)

        // Keep only last 50 errors
        if errorLog.count > 50 {
            errorLog.removeFirst(errorLog.count - 50)
        }

        Logger.connectivity.error("Error logged: \(error.errorDescription ?? "Unknown"), attempts: \(retryAttempts)")
    }

    func clearLog() {
        errorLog.removeAll()
    }
}

/// Example: Error handling with custom recovery actions
struct CustomRecoveryView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var error: UserFacingError?

    var body: some View {
        content
            .errorAlert(error: $error) {
                await handleErrorRecovery()
            }
    }

    private func handleErrorRecovery() async {
        guard let error else { return }

        switch error {
        case .locationPermissionDenied, .locationServicesDisabled:
            // Open Settings
            openSettings()

        case .watchSessionNotActivated, .watchSessionActivationTimeout:
            // Retry activation with delay
            try? await Task.sleep(for: .seconds(2))
            await manager.startTracking()

        case .watchNotReachable:
            // Wait longer for reachability
            try? await Task.sleep(for: .seconds(5))
            await manager.startTracking()

        default:
            // Standard retry
            await manager.startTracking()
        }
    }

    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private var content: some View {
        Text("Custom Recovery Demo")
    }
}

/// Example: Error filtering for display
extension UserFacingError {
    /// Whether error should be displayed to user (vs logged silently)
    var shouldDisplay: Bool {
        switch self {
        case .poorGPSAccuracy, .staleLocationData:
            return false // Informational, don't interrupt user
        case .watchNotReachable:
            return false // Common during normal use
        default:
            return true // Show in alert
        }
    }

    /// Whether error should trigger notification
    var shouldNotify: Bool {
        switch severity {
        case .critical:
            return true
        case .error, .warning, .info:
            return false
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Error Handling") {
    ErrorHandlingDemoView()
        .environment(PetLocationManager())
}
#endif
