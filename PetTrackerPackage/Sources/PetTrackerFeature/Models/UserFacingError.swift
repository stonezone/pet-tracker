import Foundation

/// User-facing error messages with recovery suggestions
///
/// Maps internal error types to localized, user-friendly messages with actionable recovery steps.
///
/// ## Architecture
/// - **Pattern**: Error mapping from domain to presentation layer
/// - **Conformance**: LocalizedError for automatic system integration
/// - **Recovery**: Each error includes specific recovery suggestions
///
/// ## Usage
/// ```swift
/// // Map internal error to user-facing error
/// if let error = locationManager.lastError {
///     let userError = UserFacingError.from(error)
///     // Display userError.localizedDescription
///     // Show userError.recoverySuggestion in alert
/// }
/// ```
public enum UserFacingError: LocalizedError, Equatable {

    // MARK: - Location Errors

    /// Location permission was denied by user
    case locationPermissionDenied

    /// Location services are disabled system-wide
    case locationServicesDisabled

    /// GPS accuracy is too low for tracking
    case poorGPSAccuracy

    /// Location updates failed for unknown reason
    case locationUpdateFailed(underlyingError: String)

    // MARK: - WatchConnectivity Errors

    /// WatchConnectivity is not supported on this device
    case watchConnectivityNotSupported

    /// WatchConnectivity session not activated
    case watchSessionNotActivated

    /// WatchConnectivity session activation timed out
    case watchSessionActivationTimeout

    /// Apple Watch is not reachable
    case watchNotReachable

    /// Failed to send message to Watch
    case messageSendFailed(underlyingError: String)

    /// Failed to decode location data from Watch
    case locationDecodingFailed

    // MARK: - Data Errors

    /// No location data available
    case noLocationData

    /// Location data is stale (too old)
    case staleLocationData(age: TimeInterval)

    /// Generic error with underlying description
    case unknown(description: String)

    // MARK: - LocalizedError Conformance

    public var errorDescription: String? {
        switch self {
        case .locationPermissionDenied:
            return "Location Access Denied"

        case .locationServicesDisabled:
            return "Location Services Disabled"

        case .poorGPSAccuracy:
            return "Poor GPS Signal"

        case .locationUpdateFailed:
            return "Location Update Failed"

        case .watchConnectivityNotSupported:
            return "Watch Not Supported"

        case .watchSessionNotActivated:
            return "Watch Not Connected"

        case .watchSessionActivationTimeout:
            return "Watch Connection Timeout"

        case .watchNotReachable:
            return "Watch Not Reachable"

        case .messageSendFailed:
            return "Communication Failed"

        case .locationDecodingFailed:
            return "Invalid Location Data"

        case .noLocationData:
            return "No Location Data"

        case .staleLocationData:
            return "Outdated Location"

        case .unknown:
            return "Unknown Error"
        }
    }

    public var failureReason: String? {
        switch self {
        case .locationPermissionDenied:
            return "The app does not have permission to access your location."

        case .locationServicesDisabled:
            return "Location services are turned off on this device."

        case .poorGPSAccuracy:
            return "The GPS signal is not strong enough for accurate tracking."

        case .locationUpdateFailed(let error):
            return "Failed to update location: \(error)"

        case .watchConnectivityNotSupported:
            return "This device does not support WatchConnectivity."

        case .watchSessionNotActivated:
            return "The connection to your Apple Watch could not be established."

        case .watchSessionActivationTimeout:
            return "The Watch connection took too long to establish."

        case .watchNotReachable:
            return "Your Apple Watch is out of range or not powered on."

        case .messageSendFailed(let error):
            return "Failed to send data to Watch: \(error)"

        case .locationDecodingFailed:
            return "Received invalid location data from the Watch."

        case .noLocationData:
            return "No location updates have been received from the Watch yet."

        case .staleLocationData(let age):
            return "Last location update was \(Int(age)) seconds ago."

        case .unknown(let description):
            return description
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .locationPermissionDenied:
            return "Go to Settings > Privacy & Security > Location Services and enable access for PetTracker."

        case .locationServicesDisabled:
            return "Go to Settings > Privacy & Security > Location Services and turn on Location Services."

        case .poorGPSAccuracy:
            return "Move to an area with clear view of the sky. Avoid buildings and dense tree cover."

        case .locationUpdateFailed:
            return "Try restarting the app or check your location permissions."

        case .watchConnectivityNotSupported:
            return "WatchConnectivity requires an iPhone paired with an Apple Watch."

        case .watchSessionNotActivated:
            return "Try restarting both your iPhone and Apple Watch, then reopen the app."

        case .watchSessionActivationTimeout:
            return "Try restarting the app. If the problem persists, restart both devices."

        case .watchNotReachable:
            return "Make sure your Apple Watch is nearby, powered on, and unlocked. Check Bluetooth is enabled."

        case .messageSendFailed:
            return "Check that your Watch is nearby and connected. Try toggling Bluetooth off and on."

        case .locationDecodingFailed:
            return "Try restarting the Watch app. Make sure both apps are updated to the latest version."

        case .noLocationData:
            return "Make sure the PetTracker Watch app is running and tracking is started on the Watch."

        case .staleLocationData:
            return "Check that the Watch app is still running and the Watch has a clear view of the sky."

        case .unknown:
            return "Try restarting the app. If the problem persists, restart your device."
        }
    }

    // MARK: - Error Mapping

    /// Maps any error to a user-facing error with appropriate messaging
    /// - Parameter error: The internal error to map
    /// - Returns: A user-facing error with localized description and recovery suggestion
    public static func from(_ error: any Error) -> UserFacingError {
        // Check for decoding errors
        if error is DecodingError {
            return .locationDecodingFailed
        }

        // Check error description for known patterns (works across module boundaries)
        let description = error.localizedDescription.lowercased()

        if description.contains("permission denied") || description.contains("location access") {
            return .locationPermissionDenied
        }

        if description.contains("not supported") && description.contains("watchconnectivity") {
            return .watchConnectivityNotSupported
        }

        if description.contains("not activated") && description.contains("session") {
            return .watchSessionNotActivated
        }

        if description.contains("timeout") || description.contains("timed out") {
            if description.contains("activation") || description.contains("session") || description.contains("watchconnectivity") {
                return .watchSessionActivationTimeout
            }
        }

        // Fallback to unknown error
        return .unknown(description: error.localizedDescription)
    }

    // MARK: - Error Severity

    /// Indicates the severity level of the error for UI presentation
    public var severity: Severity {
        switch self {
        case .locationPermissionDenied, .locationServicesDisabled, .watchConnectivityNotSupported:
            return .critical // Requires user action, app cannot function

        case .watchSessionNotActivated, .watchSessionActivationTimeout, .watchNotReachable:
            return .warning // Temporary issue, may resolve automatically

        case .poorGPSAccuracy, .staleLocationData, .noLocationData:
            return .info // Informational, not blocking

        case .locationUpdateFailed, .messageSendFailed, .locationDecodingFailed, .unknown:
            return .error // Error condition, may need retry
        }
    }

    public enum Severity {
        case info
        case warning
        case error
        case critical

        /// Color for UI presentation
        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .error: return "red"
            case .critical: return "purple"
            }
        }
    }

    // MARK: - Retry Support

    /// Indicates whether this error can potentially be resolved by retrying
    public var isRetryable: Bool {
        switch self {
        case .locationPermissionDenied, .locationServicesDisabled, .watchConnectivityNotSupported:
            return false // Requires settings change

        case .watchSessionNotActivated, .watchSessionActivationTimeout, .watchNotReachable,
             .messageSendFailed, .locationUpdateFailed, .locationDecodingFailed,
             .noLocationData, .staleLocationData, .unknown:
            return true // May succeed on retry

        case .poorGPSAccuracy:
            return false // Requires physical movement
        }
    }
}
