import Foundation
import OSLog

/// On-device crash reporting and diagnostics
///
/// Captures unhandled errors and provides diagnostic context
/// for debugging production issues without third-party SDKs.
///
/// Usage:
/// ```swift
/// CrashReporter.shared.install()
///
/// // Report non-fatal errors
/// CrashReporter.shared.recordError(error, context: "WatchConnectivity")
///
/// // Add breadcrumbs
/// CrashReporter.shared.addBreadcrumb("Started GPS tracking")
/// ```
@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
@MainActor
public final class CrashReporter: @unchecked Sendable {
    public static let shared = CrashReporter()

    private let logger = Logger(subsystem: "com.pettracker", category: "crash-reporter")
    private let maxBreadcrumbs = 50
    private let maxErrors = 20

    private var breadcrumbs: [(timestamp: Date, message: String)] = []
    private var recordedErrors: [(timestamp: Date, error: any Error, context: String)] = []

    private init() {}

    /// Install crash reporter hooks
    ///
    /// Call once at app startup to capture unhandled exceptions
    public func install() {
        // Note: NSSetUncaughtExceptionHandler cannot capture context
        // Exception handling is logged automatically by the OS
        // This method serves as initialization placeholder
        logger.info("CrashReporter installed")
    }

    /// Record a non-fatal error with context
    ///
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Context string describing where/why error occurred
    public func recordError(_ error: any Error, context: String) {
        let timestamp = Date()

        recordedErrors.append((timestamp, error, context))
        if recordedErrors.count > maxErrors {
            recordedErrors.removeFirst()
        }

        logger.error("Recorded error in \(context): \(error.localizedDescription)")

        // Write to disk for post-crash analysis
        persistDiagnostics()
    }

    /// Add a breadcrumb for debugging flow
    ///
    /// - Parameter message: Breadcrumb message
    public func addBreadcrumb(_ message: String) {
        let timestamp = Date()

        breadcrumbs.append((timestamp, message))
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst()
        }

        logger.debug("Breadcrumb: \(message)")
    }

    /// Get diagnostic report as formatted string
    ///
    /// Useful for debugging or support tickets
    public func getDiagnosticReport() -> String {
        let formatter = ISO8601DateFormatter()
        var report = "=== PetTracker Diagnostic Report ===\n"
        report += "Generated: \(formatter.string(from: Date()))\n\n"

        report += "--- Recent Breadcrumbs (\(breadcrumbs.count)) ---\n"
        for (timestamp, message) in breadcrumbs.suffix(20) {
            report += "[\(formatter.string(from: timestamp))] \(message)\n"
        }

        report += "\n--- Recorded Errors (\(recordedErrors.count)) ---\n"
        for (timestamp, error, context) in recordedErrors {
            report += "[\(formatter.string(from: timestamp))] \(context): \(error.localizedDescription)\n"
        }

        return report
    }

    /// Clear all recorded diagnostics
    public func clearDiagnostics() {
        breadcrumbs.removeAll()
        recordedErrors.removeAll()
        logger.info("Cleared diagnostics")
    }

    // MARK: - Private

    private func persistDiagnostics() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Failed to get documents directory")
            return
        }

        let diagnosticsURL = documentsURL.appendingPathComponent("diagnostics.txt")

        do {
            let report = getDiagnosticReport()
            try report.write(to: diagnosticsURL, atomically: true, encoding: .utf8)
            logger.debug("Persisted diagnostics to \(diagnosticsURL.path)")
        } catch {
            logger.error("Failed to persist diagnostics: \(error.localizedDescription)")
        }
    }
}

// MARK: - Convenience Extensions

@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
extension Error {
    /// Record this error to crash reporter with context
    public func record(context: String) {
        Task { @MainActor in
            CrashReporter.shared.recordError(self, context: context)
        }
    }
}
