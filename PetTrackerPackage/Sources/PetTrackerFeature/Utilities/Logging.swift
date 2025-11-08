import OSLog

/// Centralized logging configuration for PetTracker
///
/// Usage:
/// ```swift
/// Logger.watchLocation.info("Started GPS tracking")
/// Logger.connectivity.debug("Sent location via context: \(fix.sequence)")
/// Logger.healthKit.error("Failed to start workout: \(error)")
/// ```
@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
extension Logger {
    private static let subsystem = "com.pettracker"

    /// Watch location and GPS tracking
    ///
    /// Used for:
    /// - GPS coordinate capture
    /// - Location accuracy changes
    /// - CLLocationManager events
    /// - Watch-side location updates
    static let watchLocation = Logger(subsystem: subsystem, category: "watch-location")

    /// WatchConnectivity session and messaging
    ///
    /// Used for:
    /// - Application context updates
    /// - Interactive message sending/receiving
    /// - File transfer operations
    /// - Session activation state changes
    /// - Reachability changes
    static let connectivity = Logger(subsystem: subsystem, category: "connectivity")

    /// iOS location tracking
    ///
    /// Used for:
    /// - iPhone GPS coordinate capture
    /// - Owner location updates
    /// - iOS CLLocationManager events
    /// - Distance calculations
    static let iOSLocation = Logger(subsystem: subsystem, category: "ios-location")

    /// HealthKit workout sessions
    ///
    /// Used for:
    /// - Workout session start/stop
    /// - Background runtime extension
    /// - Session state changes
    /// - HealthKit authorization
    static let healthKit = Logger(subsystem: subsystem, category: "healthkit")

    /// UI and view lifecycle
    ///
    /// Used for:
    /// - View appear/disappear events
    /// - SwiftUI state changes
    /// - User interactions
    /// - Navigation events
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Performance and battery monitoring
    ///
    /// Used for:
    /// - Battery level changes
    /// - Performance metrics
    /// - Memory warnings
    /// - Thermal state changes
    static let performance = Logger(subsystem: subsystem, category: "performance")
}

/// Log level helpers for consistent formatting
@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
extension Logger {
    /// Log critical error with context
    ///
    /// Use for unrecoverable errors that require immediate attention
    func logCritical(_ message: String, error: (any Error)? = nil, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            self.critical("\(message) at \(fileName):\(line) - \(error.localizedDescription)")
        } else {
            self.critical("\(message) at \(fileName):\(line)")
        }
    }

    /// Log error with context
    ///
    /// Use for recoverable errors that should be investigated
    func logError(_ message: String, error: (any Error)? = nil, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            self.error("\(message) at \(fileName):\(line) - \(error.localizedDescription)")
        } else {
            self.error("\(message) at \(fileName):\(line)")
        }
    }

    /// Log warning with context
    ///
    /// Use for unexpected but handled conditions
    func logWarning(_ message: String, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.warning("\(message) at \(fileName):\(line)")
    }
}
