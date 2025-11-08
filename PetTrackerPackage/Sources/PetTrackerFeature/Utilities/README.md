# Utilities

Logging and diagnostics utilities for PetTracker.

## Logging (OSLog)

Centralized logging configuration using Apple's unified logging system.

### Available Loggers

```swift
import OSLog

// Watch-side GPS tracking
Logger.watchLocation.info("Started GPS tracking")
Logger.watchLocation.debug("GPS accuracy: \(fix.horizontalAccuracyMeters)m")

// WatchConnectivity messaging
Logger.connectivity.info("Sent location via context: sequence=\(fix.sequence)")
Logger.connectivity.error("Failed to send message: \(error)")

// iOS location tracking
Logger.iOSLocation.info("Started monitoring owner location")

// HealthKit workouts
Logger.healthKit.info("Workout session started")
Logger.healthKit.error("Failed to start workout: \(error)")

// UI events
Logger.ui.debug("ContentView appeared")

// Performance monitoring
Logger.performance.info("Battery level: \(level)%")
```

### Helper Methods

```swift
// Log with automatic file/line context
Logger.watchLocation.logError("GPS authorization failed", error: error)
// Output: "GPS authorization failed at WatchLocationProvider.swift:42 - Error description"

Logger.connectivity.logWarning("Reachability lost")
// Output: "Reachability lost at PetLocationManager.swift:156"

Logger.healthKit.logCritical("Workout session crashed", error: error)
// Output: "Workout session crashed at WorkoutManager.swift:89 - Error description"
```

### Console Filtering

View logs in Console.app or Xcode console:

```bash
# Filter by subsystem
log stream --predicate 'subsystem == "com.pettracker"'

# Filter by category
log stream --predicate 'category == "connectivity"'

# Filter by level
log stream --predicate 'subsystem == "com.pettracker" AND messageType >= 16'  # Errors only
```

## CrashReporter

On-device crash reporting without third-party SDKs.

### Setup

```swift
import PetTrackerFeature

@main
struct PetTrackerApp: App {
    init() {
        // Install crash reporter at startup
        if #available(iOS 14.0, watchOS 7.0, *) {
            CrashReporter.shared.install()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Recording Errors

```swift
// Record non-fatal errors with context
do {
    try startGPSTracking()
} catch {
    CrashReporter.shared.recordError(error, context: "WatchLocationProvider.start")
}

// Convenience extension
do {
    try sendLocationUpdate()
} catch {
    error.record(context: "WatchConnectivity.sendMessage")
}
```

### Breadcrumbs

```swift
// Track application flow for debugging
CrashReporter.shared.addBreadcrumb("Started GPS tracking")
CrashReporter.shared.addBreadcrumb("Sent first location fix")
CrashReporter.shared.addBreadcrumb("Received acknowledgment from iPhone")
```

### Diagnostic Reports

```swift
// Get diagnostic report for debugging
let report = CrashReporter.shared.getDiagnosticReport()
print(report)

// Output:
// === PetTracker Diagnostic Report ===
// Generated: 2025-11-07T23:15:42Z
//
// --- Recent Breadcrumbs (3) ---
// [2025-11-07T23:14:12Z] Started GPS tracking
// [2025-11-07T23:14:45Z] Sent first location fix
// [2025-11-07T23:15:01Z] Received acknowledgment from iPhone
//
// --- Recorded Errors (1) ---
// [2025-11-07T23:15:42Z] WatchConnectivity.sendMessage: The operation couldn't be completed
```

### Persisted Diagnostics

Diagnostics are automatically saved to disk on error:

```swift
// Location: Documents/diagnostics.txt
// Access via Files app or Xcode device window
```

## Architecture Notes

### Platform Availability

Both utilities require:
- iOS 14.0+ / watchOS 7.0+ (OSLog)
- macOS 11.0+ (for SPM builds)

### Concurrency

- `Logger` extensions are thread-safe (OSLog handles synchronization)
- `CrashReporter` is `@MainActor` isolated for state safety
- All methods can be called from any actor context (async bridging handled automatically)

### Performance

- **Logging**: Zero-cost when disabled, negligible overhead when enabled
- **CrashReporter**: Ring buffers with max capacity (50 breadcrumbs, 20 errors)
- **Disk I/O**: Only on error recording (not on breadcrumbs)

## Testing

Since logging is infrastructure-level, avoid testing log output directly. Instead:

```swift
// BAD: Testing log messages
func testLogging() {
    Logger.watchLocation.info("Test message")
    // How do we verify this?
}

// GOOD: Test business logic, not logging
func testGPSTracking() {
    let provider = WatchLocationProvider()
    provider.startTracking()

    // Logger.watchLocation is called internally
    XCTAssertTrue(provider.isTracking)
}
```

For CrashReporter, test the diagnostic report:

```swift
func testErrorRecording() async {
    await CrashReporter.shared.clearDiagnostics()

    let error = NSError(domain: "test", code: 1)
    await CrashReporter.shared.recordError(error, context: "Test")

    let report = await CrashReporter.shared.getDiagnosticReport()
    XCTAssertTrue(report.contains("Test"))
}
```
