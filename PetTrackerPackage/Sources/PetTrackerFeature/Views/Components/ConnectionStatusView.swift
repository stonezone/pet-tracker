import SwiftUI

/// Displays WatchConnectivity connection status with visual indicators
///
/// Shows:
/// - Color-coded status indicator (green/orange/red)
/// - Connection status message
/// - Retry button when disconnected
/// - Loading state during retry
///
/// ## Architecture
/// - **Pattern**: Reusable SwiftUI component
/// - **Layer**: Presentation layer only
/// - **State**: Reads connection state, executes retry action
///
/// ## Usage
/// ```swift
/// ConnectionStatusView(
///     isActivated: locationManager.isSessionActivated,
///     isReachable: locationManager.isWatchReachable,
///     statusMessage: locationManager.connectionStatus
/// ) {
///     await locationManager.startTracking()
/// }
/// ```
@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
public struct ConnectionStatusView: View {

    // MARK: - Properties

    /// Whether WCSession is activated
    let isActivated: Bool

    /// Whether Watch is currently reachable
    let isReachable: Bool

    /// Connection status message to display
    let statusMessage: String

    /// Optional retry action to execute when user taps retry button
    var retryAction: (() async -> Void)?

    /// Tracks whether retry is in progress
    @State private var isRetrying: Bool = false

    // MARK: - Initialization

    /// Creates a connection status view
    ///
    /// - Parameters:
    ///   - isActivated: Whether WCSession is activated
    ///   - isReachable: Whether Watch is reachable
    ///   - statusMessage: Status message to display
    ///   - retryAction: Optional action to execute on retry
    public init(
        isActivated: Bool,
        isReachable: Bool,
        statusMessage: String,
        retryAction: (() async -> Void)? = nil
    ) {
        self.isActivated = isActivated
        self.isReachable = isReachable
        self.statusMessage = statusMessage
        self.retryAction = retryAction
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            statusIndicator

            // Status message
            VStack(alignment: .leading, spacing: 2) {
                Text(statusMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(statusTextColor)

                if isRetrying {
                    Text("Retrying...")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Retry button (only shown when disconnected and not retrying)
            if shouldShowRetryButton {
                Button {
                    Task {
                        await handleRetry()
                    }
                } label: {
                    if isRetrying {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                .disabled(isRetrying)
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(statusBackgroundColor)
        .cornerRadius(10)
    }

    // MARK: - Computed Properties

    /// Connection status enum for internal logic
    private var status: ConnectionStatus {
        if !isActivated {
            return .connecting
        } else if !isReachable {
            return .disconnected
        } else {
            return .connected
        }
    }

    /// Status indicator view with color and icon
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            // Pulse animation for connecting state
            if status == .connecting {
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .scaleEffect(isRetrying ? 1.5 : 1.0)
                    .opacity(isRetrying ? 0.0 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: isRetrying
                    )
            }
        }
    }

    /// Status indicator color based on connection state
    private var statusColor: Color {
        switch status {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .connecting:
            return .orange
        }
    }

    /// Status text color based on connection state
    private var statusTextColor: Color {
        switch status {
        case .connected:
            return .primary
        case .disconnected:
            return .red
        case .connecting:
            return .secondary
        }
    }

    /// Background color based on connection state
    private var statusBackgroundColor: Color {
        switch status {
        case .connected:
            return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .disconnected:
            return Color.red.opacity(0.1)
        case .connecting:
            return Color.orange.opacity(0.1)
        }
    }

    /// Whether to show retry button
    private var shouldShowRetryButton: Bool {
        status != .connected && retryAction != nil
    }

    // MARK: - Actions

    /// Handles retry action with loading state
    private func handleRetry() async {
        guard let action = retryAction else { return }

        isRetrying = true
        await action()

        // Keep retrying state for a moment to show feedback
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRetrying = false
    }

    // MARK: - Supporting Types

    private enum ConnectionStatus {
        case connected
        case disconnected
        case connecting
    }
}


// MARK: - Previews

#if DEBUG
@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
struct ConnectionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Connection Status States")
                .font(.title2)
                .padding(.top)

            // Connected state
            ConnectionStatusView(
                isActivated: true,
                isReachable: true,
                statusMessage: "Connected"
            )

            // Disconnected state with retry
            ConnectionStatusView(
                isActivated: true,
                isReachable: false,
                statusMessage: "Watch not reachable"
            ) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            // Connecting state
            ConnectionStatusView(
                isActivated: false,
                isReachable: false,
                statusMessage: "Connecting to Watch..."
            ) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            Spacer()
        }
        .padding()
    }
}

@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
#Preview("Connection Status") {
    ConnectionStatusView_Previews.previews
}

@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
#Preview("Connected") {
    ConnectionStatusView(
        isActivated: true,
        isReachable: true,
        statusMessage: "Connected"
    )
    .padding()
}

@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
#Preview("Disconnected") {
    ConnectionStatusView(
        isActivated: true,
        isReachable: false,
        statusMessage: "Watch not reachable"
    ) {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    .padding()
}

@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
#Preview("Connecting") {
    ConnectionStatusView(
        isActivated: false,
        isReachable: false,
        statusMessage: "Connecting to Watch..."
    )
    .padding()
}
#endif
