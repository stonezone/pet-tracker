import SwiftUI

#if os(iOS)
import UIKit
#endif

/// View modifier for displaying user-friendly error alerts with retry capability
///
/// Provides consistent error presentation across the app with:
/// - User-friendly error messages
/// - Recovery suggestions
/// - Retry button for retryable errors
/// - Dismissible alerts
///
/// ## Architecture
/// - **Pattern**: SwiftUI ViewModifier for reusable error handling
/// - **Layer**: Presentation layer only
/// - **State**: Uses @Binding to track error state in parent view
///
/// ## Usage
/// ```swift
/// struct ContentView: View {
///     @State private var currentError: UserFacingError?
///
///     var body: some View {
///         content
///             .errorAlert(error: $currentError) {
///                 // Retry action
///                 await retryOperation()
///             }
///     }
/// }
/// ```
@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
public struct ErrorAlertModifier: ViewModifier {

    /// The current error to display (nil when no error)
    @Binding var error: UserFacingError?

    /// Optional retry action to execute when user taps retry button
    var retryAction: (() async -> Void)?

    /// Tracks whether retry is in progress
    @State private var isRetrying: Bool = false

    public func body(content: Content) -> some View {
        content
            .alert(
                error?.errorDescription ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                // Action buttons
                if let currentError = error {
                    if currentError.isRetryable, let retry = retryAction {
                        Button("Retry") {
                            Task {
                                await handleRetry(retry)
                            }
                        }
                    }

                    Button("Dismiss", role: .cancel) {
                        error = nil
                    }

                    // Settings button for permission errors
                    if requiresSettings(currentError) {
                        Button("Open Settings") {
                            openSettings()
                            error = nil
                        }
                    }
                }
            } message: {
                if let currentError = error {
                    VStack(alignment: .leading, spacing: 8) {
                        if let reason = currentError.failureReason {
                            Text(reason)
                        }

                        if let suggestion = currentError.recoverySuggestion {
                            Text("\n\(suggestion)")
                                .font(.caption)
                        }
                    }
                }
            }
    }

    // MARK: - Private Helpers

    /// Handles retry action with loading state
    private func handleRetry(_ action: @escaping () async -> Void) async {
        isRetrying = true
        error = nil // Dismiss alert while retrying
        await action()
        isRetrying = false
    }

    /// Determines if error requires opening Settings
    private func requiresSettings(_ error: UserFacingError) -> Bool {
        switch error {
        case .locationPermissionDenied, .locationServicesDisabled:
            return true
        default:
            return false
        }
    }

    /// Opens iOS Settings app
    private func openSettings() {
        #if os(iOS)
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
        #endif
    }
}

// MARK: - View Extension

@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
extension View {

    /// Presents error alerts with user-friendly messages and retry capability
    ///
    /// - Parameters:
    ///   - error: Binding to current error (nil when no error)
    ///   - retryAction: Optional async action to execute when user taps retry
    /// - Returns: Modified view with error alert handling
    ///
    /// ## Example
    /// ```swift
    /// .errorAlert(error: $viewModel.error) {
    ///     await viewModel.retryLastOperation()
    /// }
    /// ```
    public func errorAlert(
        error: Binding<UserFacingError?>,
        retryAction: (() async -> Void)? = nil
    ) -> some View {
        modifier(ErrorAlertModifier(error: error, retryAction: retryAction))
    }
}

// MARK: - Preview Support

#if DEBUG
@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
struct ErrorAlertPreview: View {
    @State private var currentError: UserFacingError?
    @State private var errorType: ErrorType = .locationPermission

    enum ErrorType: String, CaseIterable {
        case locationPermission = "Location Permission"
        case watchNotReachable = "Watch Not Reachable"
        case sessionTimeout = "Session Timeout"
        case poorGPS = "Poor GPS"
        case noData = "No Data"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Error Alert Previews")
                .font(.title)

            Picker("Error Type", selection: $errorType) {
                ForEach(ErrorType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Button("Show Error") {
                currentError = sampleError(for: errorType)
            }
            .buttonStyle(.borderedProminent)

            if let error = currentError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Error:")
                        .font(.headline)
                    Text(error.errorDescription ?? "Unknown")
                        .foregroundStyle(.secondary)
                    if error.isRetryable {
                        Text("(Retryable)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                .cornerRadius(8)
            }
        }
        .padding()
        .errorAlert(error: $currentError) {
            // Simulate retry
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    private func sampleError(for type: ErrorType) -> UserFacingError {
        switch type {
        case .locationPermission:
            return .locationPermissionDenied
        case .watchNotReachable:
            return .watchNotReachable
        case .sessionTimeout:
            return .watchSessionActivationTimeout
        case .poorGPS:
            return .poorGPSAccuracy
        case .noData:
            return .noLocationData
        }
    }
}

@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
#Preview("Error Alert") {
    ErrorAlertPreview()
}
#endif
