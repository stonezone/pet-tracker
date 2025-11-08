# PetTracker API Reference

**Version**: 0.1.0
**Last Updated**: 2025-11-08
**Swift**: 6.2.1
**iOS**: 26.0+
**watchOS**: 26.0+

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Domain Layer](#domain-layer)
   - [LocationFix](#locationfix)
   - [UserFacingError](#userfacingerror)
3. [Application Layer](#application-layer)
   - [PetLocationManager (iOS)](#petlocationmanager-ios)
   - [WatchLocationProvider (watchOS)](#watchlocationprovider-watchos)
4. [Utilities Layer](#utilities-layer)
   - [PerformanceMonitor](#performancemonitor)
   - [Logging](#logging)
5. [Presentation Layer](#presentation-layer)
   - [ErrorAlert](#erroralert)
   - [ConnectionStatusView](#connectionstatusview)

---

## Architecture Overview

PetTracker follows Clean Architecture principles with clear layer separation:

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (SwiftUI)                               │
│  • Views consume @Observable models                         │
│  • No business logic in views                               │
│  • @MainActor isolation for UI updates                      │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│  Application Layer (@Observable Models)                     │
│  • PetLocationManager: iOS coordinator                      │
│  • WatchLocationProvider: Watch GPS provider                │
│  • State management with Observation framework              │
│  • WCSession delegate handling                              │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│  Domain Layer (Business Logic)                              │
│  • LocationFix: Core GPS data model                         │
│  • UserFacingError: Error mapping                           │
│  • No framework dependencies                                │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│  Infrastructure Layer (Platform Services)                   │
│  • WatchConnectivity (triple-path messaging)                │
│  • CoreLocation (GPS capture)                               │
│  • HealthKit (workout sessions)                             │
└─────────────────────────────────────────────────────────────┘
```

### Module Structure

All application logic is contained in the `PetTrackerFeature` Swift Package:

```
PetTrackerPackage/
└── Sources/
    └── PetTrackerFeature/
        ├── Models/               # Domain layer
        │   ├── LocationFix.swift
        │   └── UserFacingError.swift
        ├── Services/             # Application layer
        │   ├── PetLocationManager.swift     (iOS)
        │   └── WatchLocationProvider.swift  (watchOS)
        ├── Utilities/            # Cross-cutting concerns
        │   ├── PerformanceMonitor.swift
        │   └── Logging.swift
        └── Views/                # Presentation layer
            └── Components/
                ├── ErrorAlert.swift
                └── ConnectionStatusView.swift
```

---

## Domain Layer

The domain layer contains pure business logic with no framework dependencies. All types are `Sendable` for safe concurrency.

### LocationFix

**File**: `Models/LocationFix.swift`

**Purpose**: Represents a single GPS location fix with comprehensive metadata.

#### Overview

`LocationFix` is the core domain model for location data, used across iOS and watchOS platforms. It captures all relevant GPS information including position, accuracy, motion data, and device metadata.

**Design Principles**:
- **Value Type**: Immutable struct for thread-safety
- **Sendable**: Safe to pass across concurrency boundaries
- **Codable**: Efficient JSON serialization for WatchConnectivity transmission
- **Platform-Agnostic**: Works on both iOS and watchOS

#### Public Interface

```swift
public struct LocationFix: Codable, Sendable, Identifiable
```

#### Properties

##### Core Properties

```swift
public let id: UUID
```
Unique identifier for this location fix.

```swift
public let timestamp: Date
```
Timestamp when this location fix was captured.

```swift
public let source: Source
```
Source device that captured this location (`.watchOS` or `.iOS`).

```swift
public let coordinate: Coordinate
```
Geographic coordinate (latitude, longitude).

```swift
public let altitudeMeters: Double?
```
Altitude above mean sea level in meters. `nil` if unavailable.

##### Accuracy Metrics

```swift
public let horizontalAccuracyMeters: Double
```
Horizontal accuracy (radius of uncertainty) in meters. Lower values indicate more precise location:
- < 5m: Excellent (Best accuracy)
- 5-10m: Good
- 10-50m: Fair
- > 50m: Poor

```swift
public let verticalAccuracyMeters: Double
```
Vertical accuracy (altitude uncertainty) in meters. Negative values indicate invalid altitude data.

##### Motion Data

```swift
public let speedMetersPerSecond: Double
```
Instantaneous speed in meters per second. Negative value indicates invalid speed data.

```swift
public let courseDegrees: Double
```
Course (direction of travel) in degrees from true north (0-360):
- 0° = North
- 90° = East
- 180° = South
- 270° = West

Negative value indicates invalid course data.

```swift
public let headingDegrees: Double?
```
Device heading in degrees from true north (0-360). `nil` for watchOS (Apple Watch has no magnetometer).

##### Device Metadata

```swift
public let batteryFraction: Double
```
Device battery level as fraction (0.0 - 1.0):
- 1.0 = 100% charged
- 0.5 = 50% charged
- 0.0 = Empty

```swift
public let sequence: Int
```
Monotonically increasing sequence number for ordering. Used to detect dropped messages and ensure proper ordering when messages arrive out-of-order.

##### Computed Properties

```swift
public var batteryPercentage: Int
```
Battery level as percentage (0-100).

```swift
public var age: TimeInterval
```
Age of this location fix (time since timestamp).

```swift
public var hasValidAccuracy: Bool
```
Whether this location fix has valid accuracy (horizontalAccuracyMeters >= 0).

```swift
public var hasValidAltitude: Bool
```
Whether this location fix has valid altitude (altitudeMeters != nil && verticalAccuracyMeters >= 0).

```swift
public var hasValidSpeed: Bool
```
Whether this location fix has valid speed (speedMetersPerSecond >= 0).

```swift
public var hasValidCourse: Bool
```
Whether this location fix has valid course (courseDegrees >= 0).

```swift
public var clLocation: CLLocation
```
Converts to CLLocation for use with MapKit and CoreLocation APIs.

#### Initializers

##### Full Initialization

```swift
public init(
    id: UUID = UUID(),
    timestamp: Date,
    source: Source,
    coordinate: Coordinate,
    altitudeMeters: Double?,
    horizontalAccuracyMeters: Double,
    verticalAccuracyMeters: Double,
    speedMetersPerSecond: Double,
    courseDegrees: Double,
    headingDegrees: Double?,
    batteryFraction: Double,
    sequence: Int
)
```

Creates a location fix with all parameters.

**Parameters**:
- `id`: Unique identifier (defaults to new UUID)
- `timestamp`: When the fix was captured
- `source`: Device that captured the location
- `coordinate`: Geographic position
- `altitudeMeters`: Altitude above sea level (optional)
- `horizontalAccuracyMeters`: Position uncertainty radius
- `verticalAccuracyMeters`: Altitude uncertainty
- `speedMetersPerSecond`: Instantaneous speed
- `courseDegrees`: Direction of travel (0-360)
- `headingDegrees`: Device heading (nil for Watch)
- `batteryFraction`: Battery level (0.0-1.0)
- `sequence`: Monotonic sequence number

##### CLLocation Conversion

```swift
public init(
    from location: CLLocation,
    source: Source,
    batteryLevel: Double,
    sequence: Int,
    heading: CLHeading? = nil
)
```

Creates a location fix from a CoreLocation CLLocation.

**Parameters**:
- `location`: The CLLocation to convert
- `source`: Which device captured this location
- `batteryLevel`: Current device battery level (0.0-1.0)
- `sequence`: Sequence number for ordering
- `heading`: Optional device heading (iPhone only)

#### Nested Types

##### Source

```swift
public enum Source: String, Codable, Sendable {
    case watchOS  // Captured on Apple Watch (pet's device)
    case iOS      // Captured on iPhone (owner's device)
}
```

##### Coordinate

```swift
public struct Coordinate: Codable, Equatable, Sendable {
    public let latitude: Double   // -90 to +90 (positive = North)
    public let longitude: Double  // -180 to +180 (positive = East)

    public init(latitude: Double, longitude: Double)

    public var isValid: Bool
    public var clLocationCoordinate: CLLocationCoordinate2D
}
```

#### JSON Encoding

LocationFix uses compact field names to minimize payload size over WatchConnectivity:

```json
{
  "id": "UUID-string",
  "ts_unix_ms": 1699401234567.0,
  "source": "watchOS",
  "coordinate": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "alt_m": 10.0,
  "h_accuracy_m": 5.0,
  "v_accuracy_m": 10.0,
  "speed_mps": 0.5,
  "course_deg": 180.0,
  "heading_deg": null,
  "battery_pct": 85.0,
  "seq": 42
}
```

**Field Mappings**:
- `ts_unix_ms`: Timestamp in Unix milliseconds
- `alt_m`: Altitude in meters
- `h_accuracy_m`: Horizontal accuracy in meters
- `v_accuracy_m`: Vertical accuracy in meters
- `speed_mps`: Speed in meters per second
- `course_deg`: Course in degrees
- `heading_deg`: Heading in degrees
- `battery_pct`: Battery as percentage (0-100)
- `seq`: Sequence number

**Payload Size**: ~200-300 bytes per fix

#### Usage Examples

##### Creating from CLLocation

```swift
import CoreLocation
import PetTrackerFeature

let clLocation = CLLocation(/* ... */)
let batteryLevel = 0.85
let sequence = 42

let fix = LocationFix(
    from: clLocation,
    source: .watchOS,
    batteryLevel: batteryLevel,
    sequence: sequence
)
```

##### Encoding for Transmission

```swift
let encoder = JSONEncoder()
let jsonData = try encoder.encode(fix)

// Convert to dictionary for WatchConnectivity
let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
session.updateApplicationContext(dict ?? [:])
```

##### Decoding from Received Data

```swift
let decoder = JSONDecoder()
let receivedFix = try decoder.decode(LocationFix.self, from: jsonData)

print("Received location at \(receivedFix.coordinate.latitude), \(receivedFix.coordinate.longitude)")
print("Battery: \(receivedFix.batteryPercentage)%")
print("Accuracy: \(Int(receivedFix.horizontalAccuracyMeters))m")
```

##### Validation

```swift
if fix.hasValidAccuracy && fix.horizontalAccuracyMeters < 10 {
    print("Excellent GPS accuracy")
}

if fix.coordinate.isValid {
    // Use coordinate in map
    let mapCoordinate = fix.coordinate.clLocationCoordinate
}

if fix.hasValidSpeed && fix.speedMetersPerSecond > 1.0 {
    print("Pet is moving at \(fix.speedMetersPerSecond) m/s")
}
```

#### Thread Safety

`LocationFix` is `Sendable` and can be safely passed across concurrency boundaries:

```swift
Task.detached {
    let fix = LocationFix.sample()

    await MainActor.run {
        // Safe to use on main thread
        self.latestLocation = fix
    }
}
```

#### Test Fixtures

```swift
#if DEBUG
// Sample location (San Francisco)
let sample = LocationFix.sample(sequence: 1)

// Sample with poor accuracy
let poorAccuracy = LocationFix.samplePoorAccuracy(sequence: 2)
#endif
```

---

### UserFacingError

**File**: `Models/UserFacingError.swift`

**Purpose**: Maps internal errors to user-friendly messages with recovery suggestions.

#### Overview

`UserFacingError` provides localized, user-friendly error messages with actionable recovery steps. It serves as the error mapping layer between domain/application errors and presentation layer.

**Design Principles**:
- **Pattern**: Error mapping from domain to presentation layer
- **Conformance**: LocalizedError for automatic system integration
- **Recovery**: Each error includes specific recovery suggestions
- **Severity**: Categorizes errors by impact (info, warning, error, critical)
- **Retry Support**: Indicates which errors can be retried

#### Public Interface

```swift
public enum UserFacingError: LocalizedError, Equatable
```

#### Cases

##### Location Errors

```swift
case locationPermissionDenied
```
Location permission was denied by user. **Critical** - Requires settings change.

```swift
case locationServicesDisabled
```
Location services are disabled system-wide. **Critical** - Requires settings change.

```swift
case poorGPSAccuracy
```
GPS accuracy is too low for tracking. **Info** - Requires physical movement.

```swift
case locationUpdateFailed(underlyingError: String)
```
Location updates failed for unknown reason. **Error** - Retryable.

##### WatchConnectivity Errors

```swift
case watchConnectivityNotSupported
```
WatchConnectivity is not supported on this device. **Critical** - Non-retryable.

```swift
case watchSessionNotActivated
```
WatchConnectivity session not activated. **Warning** - Retryable.

```swift
case watchSessionActivationTimeout
```
WatchConnectivity session activation timed out. **Warning** - Retryable.

```swift
case watchNotReachable
```
Apple Watch is not reachable. **Warning** - Retryable.

```swift
case messageSendFailed(underlyingError: String)
```
Failed to send message to Watch. **Error** - Retryable.

```swift
case locationDecodingFailed
```
Failed to decode location data from Watch. **Error** - Retryable.

##### Data Errors

```swift
case noLocationData
```
No location data available. **Info** - Retryable.

```swift
case staleLocationData(age: TimeInterval)
```
Location data is stale (too old). **Info** - Retryable.

```swift
case unknown(description: String)
```
Generic error with underlying description. **Error** - Retryable.

#### Properties

##### LocalizedError Conformance

```swift
public var errorDescription: String?
```
Short error title for alert display.

Examples:
- "Location Access Denied"
- "Watch Not Connected"
- "Poor GPS Signal"

```swift
public var failureReason: String?
```
Detailed explanation of why the error occurred.

Examples:
- "The app does not have permission to access your location."
- "Your Apple Watch is out of range or not powered on."

```swift
public var recoverySuggestion: String?
```
Actionable steps to resolve the error.

Examples:
- "Go to Settings > Privacy & Security > Location Services and enable access for PetTracker."
- "Make sure your Apple Watch is nearby, powered on, and unlocked. Check Bluetooth is enabled."

##### Error Severity

```swift
public var severity: Severity
```
Indicates the severity level of the error for UI presentation.

```swift
public enum Severity {
    case info      // Informational, not blocking
    case warning   // Temporary issue, may resolve automatically
    case error     // Error condition, may need retry
    case critical  // Requires user action, app cannot function
}
```

##### Retry Support

```swift
public var isRetryable: Bool
```
Indicates whether this error can potentially be resolved by retrying.

Returns `false` for:
- Permission errors (requires settings change)
- Not supported errors (hardware limitation)
- Poor GPS accuracy (requires physical movement)

Returns `true` for:
- Connection errors (may reconnect)
- Timeout errors (may succeed on retry)
- Data errors (may receive data later)

#### Methods

##### Error Mapping

```swift
public static func from(_ error: any Error) -> UserFacingError
```

Maps any error to a user-facing error with appropriate messaging.

**Parameters**:
- `error`: The internal error to map

**Returns**: A user-facing error with localized description and recovery suggestion

**Detection Logic**:
- Checks for `DecodingError` → `.locationDecodingFailed`
- Parses error description for known patterns:
  - "permission denied" → `.locationPermissionDenied`
  - "not supported" + "watchconnectivity" → `.watchConnectivityNotSupported`
  - "not activated" + "session" → `.watchSessionNotActivated`
  - "timeout" → `.watchSessionActivationTimeout`
- Falls back to `.unknown(description:)` for unrecognized errors

#### Usage Examples

##### Mapping Internal Errors

```swift
import PetTrackerFeature

// In iOS app
if let error = locationManager.lastError {
    let userError = UserFacingError.from(error)
    print(userError.errorDescription ?? "Unknown error")
    print(userError.recoverySuggestion ?? "No suggestion")
}
```

##### Displaying in Alert

```swift
struct ContentView: View {
    @State private var error: UserFacingError?
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        content
            .errorAlert(error: $error) {
                // Retry action
                await manager.startTracking()
            }
            .task(id: manager.lastError?.localizedDescription) {
                if let internalError = manager.lastError {
                    error = UserFacingError.from(internalError)
                }
            }
    }
}
```

##### Checking Severity

```swift
let error = UserFacingError.locationPermissionDenied

switch error.severity {
case .critical:
    // Show modal blocking UI
    showCriticalErrorModal(error)
case .warning:
    // Show banner
    showWarningBanner(error)
case .error, .info:
    // Show dismissible alert
    showAlert(error)
}
```

##### Conditional Retry

```swift
if error.isRetryable {
    // Show retry button
    Button("Retry") {
        Task { await retryOperation() }
    }
} else {
    // Show settings button
    Button("Open Settings") {
        openSettingsApp()
    }
}
```

#### Localization

All error messages are in English by default. To add localization:

1. Add `Localizable.strings` files for each language
2. Use `NSLocalizedString` in `errorDescription`, `failureReason`, and `recoverySuggestion`
3. Provide translation keys for all error cases

Example:

```swift
public var errorDescription: String? {
    switch self {
    case .locationPermissionDenied:
        return NSLocalizedString(
            "error.location.permission.denied.title",
            value: "Location Access Denied",
            comment: "Title for location permission denied error"
        )
    // ...
    }
}
```

---

## Application Layer

The application layer coordinates business logic and manages state. All services use the `@Observable` macro for reactive SwiftUI integration.

### PetLocationManager (iOS)

**File**: `Services/PetLocationManager.swift`
**Platform**: iOS only (`#if os(iOS)`)

**Purpose**: Manages pet location tracking by receiving GPS data from Apple Watch.

#### Overview

`PetLocationManager` is the central coordinator for the iOS app that:
- Receives location fixes from Watch via WatchConnectivity
- Tracks owner's location using iPhone GPS
- Calculates distance between pet and owner
- Maintains historical trail of pet locations (last 100 fixes)
- Manages WatchConnectivity session lifecycle

**Architecture**:
- **Pattern**: @Observable for reactive SwiftUI integration
- **Thread Safety**: All UI-related properties are @MainActor isolated
- **Delegate**: Implements WCSessionDelegate for receiving Watch messages
- **Delegation**: Implements CLLocationManagerDelegate for iPhone GPS

#### Public Interface

```swift
@MainActor
@Observable
public final class PetLocationManager: NSObject
```

#### Properties

##### Published State

```swift
public private(set) var latestPetLocation: LocationFix?
```
Latest location fix received from pet's Apple Watch. Observable.

```swift
public private(set) var locationHistory: [LocationFix]
```
Historical trail of pet locations (last 100 fixes). Observable.

```swift
public private(set) var ownerLocation: CLLocation?
```
Owner's current location (from iPhone GPS). Observable.

```swift
public var distanceFromOwner: Double?
```
Calculated distance from owner to pet in meters. Returns `nil` if either location unavailable.

```swift
public var petBatteryLevel: Int?
```
Pet's (Watch) battery level as percentage (0-100). Derived from `latestPetLocation.batteryPercentage`.

```swift
public var accuracyMeters: Double?
```
GPS horizontal accuracy in meters. Derived from `latestPetLocation.horizontalAccuracyMeters`.

```swift
public var timeSinceLastUpdate: TimeInterval?
```
Time since last location update in seconds. Derived from `latestPetLocation.age`.

```swift
public private(set) var isWatchReachable: Bool
```
Whether Watch is currently reachable via WatchConnectivity. Observable.

```swift
public private(set) var isSessionActivated: Bool
```
Whether WatchConnectivity session is activated. Observable.

```swift
public private(set) var lastError: (any Error)?
```
Last error encountered. Observable.

```swift
public var connectionStatus: String
```
Connection status message for UI display. Computed property that returns:
- "Connecting to Watch..." when session not activated
- "Watch not reachable" when session activated but not reachable
- "Connected" when session activated and reachable

#### Initializers

```swift
public init(
    locationManager: CLLocationManager = CLLocationManager(),
    session: WCSession = WCSession.default
)
```

Creates a new pet location manager.

**Parameters**:
- `locationManager`: Location manager instance (defaults to new CLLocationManager for production, injectable for testing)
- `session`: WatchConnectivity session (defaults to WCSession.default for production, injectable for testing)

**Side Effects**:
- Sets up CLLocationManager with best accuracy, 10m distance filter, background updates enabled
- Activates WCSession asynchronously (deferred to avoid blocking initialization)

#### Methods

##### Public API

```swift
public func startTracking() async
```

Starts tracking both pet (via Watch) and owner (via iPhone GPS).

**Behavior**:
1. Waits for WCSession to activate (timeout: 1 second)
2. Returns early with error if session not activated
3. Requests location permissions if `notDetermined`
4. Returns early with error if permission `denied` or `restricted`
5. Starts CLLocationManager updates if permission granted

**Errors**:
- Sets `lastError` to `WatchConnectivityError.sessionNotActivated` if session fails to activate
- Sets `lastError` to `LocationError.permissionDenied` if location permission denied

**Usage**:
```swift
let manager = PetLocationManager()
await manager.startTracking()
```

```swift
public func stopTracking()
```

Stops tracking iPhone GPS. Does not stop Watch tracking (Watch manages its own lifecycle).

**Usage**:
```swift
manager.stopTracking()
```

```swift
public func clearHistory()
```

Clears location history array.

**Usage**:
```swift
manager.clearHistory()
```

#### Error Types

```swift
public enum LocationError: LocalizedError, Equatable {
    case permissionDenied

    public var errorDescription: String? {
        "Location permission denied. Please enable location access in Settings."
    }
}
```

```swift
public enum WatchConnectivityError: LocalizedError, Equatable {
    case notSupported
    case sessionNotActivated
    case activationTimeout

    public var errorDescription: String? { /* ... */ }
}
```

#### Delegate Implementations

##### CLLocationManagerDelegate

```swift
nonisolated public func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
)
```
Updates `ownerLocation` with latest iPhone GPS fix.

```swift
nonisolated public func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: any Error
)
```
Sets `lastError` on main thread.

```swift
nonisolated public func locationManagerDidChangeAuthorization(
    _ manager: CLLocationManager
)
```
Starts/stops tracking based on new authorization status.

##### WCSessionDelegate

**Session Lifecycle**:

```swift
nonisolated public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
)
```
Updates `isSessionActivated` and `isWatchReachable` on main thread.

```swift
nonisolated public func sessionDidBecomeInactive(_ session: WCSession)
```
Sets `isSessionActivated = false`.

```swift
nonisolated public func sessionDidDeactivate(_ session: WCSession)
```
Sets `isSessionActivated = false` and reactivates session.

```swift
nonisolated public func sessionReachabilityDidChange(_ session: WCSession)
```
Updates `isWatchReachable`.

**Message Reception (Triple-Path)**:

```swift
nonisolated public func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any]
)
```
Receives interactive messages (foreground, immediate).

```swift
nonisolated public func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
)
```
Receives interactive messages with reply handler. Sends `["status": "received"]` reply.

```swift
nonisolated public func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
)
```
Receives application context updates (background, latest-only).

```swift
nonisolated public func session(
    _ session: WCSession,
    didReceive file: WCSessionFile
)
```
Receives file transfers (background, guaranteed delivery).

All message handlers decode the dictionary to `LocationFix` and call `handleReceivedLocationFix(_:)` on main thread.

#### Usage Examples

##### Basic Setup

```swift
import SwiftUI
import PetTrackerFeature

@main
struct PetTrackerApp: App {
    @State private var locationManager = PetLocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .task {
                    await locationManager.startTracking()
                }
        }
    }
}
```

##### Consuming Location Data

```swift
struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        VStack {
            if let distance = manager.distanceFromOwner {
                Text("Pet is \(Int(distance))m away")
                    .font(.title)
            }

            if let battery = manager.petBatteryLevel {
                Text("Watch battery: \(battery)%")
                    .foregroundStyle(battery < 20 ? .red : .primary)
            }

            if let accuracy = manager.accuracyMeters {
                Text("GPS accuracy: ±\(Int(accuracy))m")
                    .font(.caption)
            }
        }
    }
}
```

##### Handling Errors

```swift
struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var error: UserFacingError?

    var body: some View {
        content
            .errorAlert(error: $error) {
                await manager.startTracking()
            }
            .task(id: manager.lastError?.localizedDescription) {
                if let internalError = manager.lastError {
                    error = UserFacingError.from(internalError)
                }
            }
    }
}
```

##### Connection Status

```swift
struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        VStack {
            ConnectionStatusView(
                isActivated: manager.isSessionActivated,
                isReachable: manager.isWatchReachable,
                statusMessage: manager.connectionStatus
            ) {
                await manager.startTracking()
            }

            // Your content
        }
    }
}
```

##### Location History

```swift
struct TrailView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        List(manager.locationHistory) { fix in
            HStack {
                Text("\(fix.coordinate.latitude), \(fix.coordinate.longitude)")
                Spacer()
                Text("\(Int(fix.age))s ago")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Trail (\(manager.locationHistory.count) fixes)")
    }
}
```

#### Thread Safety

All public properties are `@MainActor` isolated. Delegate callbacks are `nonisolated` and dispatch to main thread:

```swift
nonisolated public func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
) {
    Task { @MainActor in
        self.ownerLocation = locations.last
    }
}
```

#### Performance Characteristics

- **WCSession Activation**: <5 seconds (timeout protection)
- **GPS Update Latency**: <500ms target
- **Memory Usage**: <50MB target (iOS)
- **History Buffer**: 100 fixes (~20-30KB)

---

### WatchLocationProvider (watchOS)

**File**: `Services/WatchLocationProvider.swift`
**Platform**: watchOS only (`#if os(watchOS)`)

**Purpose**: Provides GPS location tracking on Apple Watch and transmits to paired iPhone.

#### Overview

`WatchLocationProvider` is the Watch-side component that:
- Captures GPS fixes using CLLocationManager with HealthKit workout session
- Monitors device battery level
- Transmits location data to iPhone via triple-path WatchConnectivity
- Manages workout session lifecycle for extended GPS runtime (>8 hours)
- Implements adaptive throttling based on battery and motion state

**Triple-Path Transmission Strategy**:
1. **Application Context**: Background, latest-only, ~2Hz max (0.5s throttle)
2. **Interactive Messages**: Foreground, immediate (<100ms), requires reachability
3. **File Transfer**: Background, guaranteed delivery, automatic retry

#### Public Interface

```swift
@MainActor
@Observable
public final class WatchLocationProvider: NSObject
```

#### Properties

##### Published State

```swift
public private(set) var isTracking: Bool
```
Current tracking status. Observable.

```swift
public private(set) var latestLocation: LocationFix?
```
Latest captured location fix. Observable.

```swift
public private(set) var batteryLevel: Double
```
Current battery level (0.0-1.0). Observable. Updated automatically via NotificationCenter.

```swift
public private(set) var isPhoneReachable: Bool
```
Whether iPhone is currently reachable. Observable.

```swift
public private(set) var lastError: (any Error)?
```
Last error encountered. Observable.

```swift
public private(set) var fixesSent: Int
```
Number of location fixes sent. Observable. Increments with each transmission.

#### Initializers

```swift
public override init()
```

Creates a new Watch location provider.

**Side Effects**:
- Creates CLLocationManager with best accuracy, no distance filter, background updates enabled
- Activates WCSession
- Enables battery monitoring via WKInterfaceDevice
- Subscribes to battery level change notifications

#### Methods

##### Public API

```swift
public func startTracking() async
```

Starts GPS tracking with HealthKit workout session.

**Behavior**:
1. Returns early if already tracking
2. Waits for WCSession to activate (timeout: 1 second)
3. Returns early with error if session not activated
4. Checks location permission:
   - If `notDetermined`: Requests permission and returns (user must call again after granting)
   - If `denied`/`restricted`: Sets error and returns
   - If `authorized`: Continues
5. Starts HealthKit workout session for extended GPS runtime
6. Returns early with error if workout fails to start
7. Starts CLLocationManager updates
8. Sets `isTracking = true`

**Errors**:
- Sets `lastError` to `WatchConnectivityError.sessionNotActivated` if session fails to activate
- Sets `lastError` to `LocationError.permissionDenied` if location permission denied
- Sets `lastError` if HealthKit workout session fails to start

**Usage**:
```swift
let provider = WatchLocationProvider()
await provider.startTracking()
```

```swift
public func stopTracking() async
```

Stops GPS tracking and ends workout session.

**Behavior**:
1. Returns early if not tracking
2. Sets `isTracking = false` immediately (UI updates)
3. Stops CLLocationManager updates
4. Ends HealthKit workout session and finishes workout
5. Cleans up workout references

**Usage**:
```swift
await provider.stopTracking()
```

#### Error Types

```swift
public enum LocationError: LocalizedError {
    case permissionDenied
    case healthKitNotAvailable

    public var errorDescription: String? { /* ... */ }
}
```

```swift
public enum WatchConnectivityError: LocalizedError {
    case notSupported
    case sessionNotActivated

    public var errorDescription: String? { /* ... */ }
}
```

#### Triple-Path Messaging

The provider sends location fixes via three complementary paths for maximum reliability:

##### Path 1: Application Context

```swift
private func sendViaApplicationContext(_ fix: LocationFix)
```

**Characteristics**:
- Throttled to 0.5s interval (bypassed if accuracy changes >5m)
- Works in background
- Only latest data (not queued)
- ~2Hz max update rate

**Algorithm**:
```
IF session not activated: return
IF time since last update < 0.5s AND accuracy change < 5m: return
ELSE: send fix, update timestamp and last accuracy
```

##### Path 2: Interactive Messages

```swift
private func sendViaInteractiveMessage(_ fix: LocationFix)
```

**Characteristics**:
- Requires Bluetooth reachability
- <100ms latency when reachable
- Falls back to file transfer on failure
- Sends reply acknowledgment to watch

**Algorithm**:
```
IF session not activated OR not reachable: return
ELSE: send message with error handler
ON ERROR: call sendViaFileTransfer(fix)
```

##### Path 3: File Transfer

```swift
private func sendViaFileTransfer(_ fix: LocationFix)
```

**Characteristics**:
- Queued for offline periods
- Automatic retry on failure (system-managed)
- Background delivery when reachable
- Guaranteed delivery (eventually)
- Writes JSON to temporary file

**Algorithm**:
```
IF session not activated: return
ELSE: encode fix to JSON, write to temp file, transfer file with metadata
```

#### Adaptive Throttling

The provider implements battery-aware throttling to extend Watch runtime:

```swift
private func shouldThrottleUpdate(location: CLLocation, isStationary: Bool) -> Bool
```

**Strategy**:
- **Normal battery (>20%)**: Standard throttling (0.5s)
- **Low battery (10-20%)**: Reduce frequency when stationary (2.0s), normal when moving (1.0s)
- **Critical battery (<10%)**: Aggressive throttling (5.0s)
- **Accuracy bypass**: Always send if accuracy changed >5m (bypasses throttle)

**Motion Detection**:
- Stationary threshold: 5 meters
- Confirmation time: 30 seconds
- Tracks last movement time to determine if device is stationary

```swift
private func isDeviceStationary(_ location: CLLocation) -> Bool
```

Returns `true` if device hasn't moved significantly (>5m) in the last 30 seconds.

#### Battery Monitoring

The provider tracks battery state and adjusts behavior:

```swift
private func updateBatteryLevel()
```

**Behavior**:
- Reads battery level from `WKInterfaceDevice.current().batteryLevel`
- Logs warnings at 20% (low) and 10% (critical)
- Updates `batteryLevel` property (observable)

**Notifications**:
- Subscribes to `WKInterfaceDeviceBatteryLevelDidChange`
- Updates battery level automatically

#### HealthKit Workout Session

The provider uses HealthKit workouts to enable extended GPS runtime (>8 hours):

```swift
private func startWorkoutSession() async throws
```

**Configuration**:
- Activity type: `.other` (provides most frequent GPS updates)
- Location type: `.outdoor`
- Requires HealthKit authorization for workout type

**Lifecycle**:
1. Request HealthKit authorization
2. Create `HKWorkoutConfiguration`
3. Create `HKWorkoutSession` with configuration
4. Create `HKLiveWorkoutBuilder` with data source
5. Start session with current date
6. Begin builder collection

```swift
private func stopWorkoutSession() async
```

**Lifecycle**:
1. End workout session
2. End builder collection
3. Finish workout (saves to HealthKit)
4. Clean up references

#### Delegate Implementations

##### CLLocationManagerDelegate

```swift
nonisolated public func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
)
```
Calls `sendLocation(_:)` on main thread for each new location.

```swift
nonisolated public func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: any Error
)
```
Sets `lastError` on main thread.

```swift
nonisolated public func locationManagerDidChangeAuthorization(
    _ manager: CLLocationManager
)
```
Sets `lastError` if permission denied/restricted.

##### WCSessionDelegate

```swift
nonisolated public func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: (any Error)?
)
```
Updates `isPhoneReachable` on main thread.

```swift
nonisolated public func sessionReachabilityDidChange(_ session: WCSession)
```
Updates `isPhoneReachable` on main thread.

#### Usage Examples

##### Basic Setup

```swift
import SwiftUI
import PetTrackerFeature

@main
struct PetTrackerWatchApp: App {
    @State private var locationProvider = WatchLocationProvider()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(locationProvider)
        }
    }
}
```

##### Start/Stop Tracking

```swift
struct WatchContentView: View {
    @Environment(WatchLocationProvider.self) private var provider

    var body: some View {
        VStack {
            if provider.isTracking {
                Button("Stop Tracking") {
                    Task { await provider.stopTracking() }
                }
                .foregroundStyle(.red)
            } else {
                Button("Start Tracking") {
                    Task { await provider.startTracking() }
                }
                .foregroundStyle(.green)
            }
        }
    }
}
```

##### Display Tracking Status

```swift
struct StatusView: View {
    @Environment(WatchLocationProvider.self) private var provider

    var body: some View {
        VStack(spacing: 8) {
            // Battery indicator
            HStack {
                Image(systemName: "battery.100")
                Text("\(Int(provider.batteryLevel * 100))%")
                    .foregroundStyle(provider.batteryLevel < 0.2 ? .red : .primary)
            }

            // Tracking status
            if provider.isTracking {
                Text("Tracking: \(provider.fixesSent) fixes sent")
                    .font(.caption)
            }

            // Connection status
            HStack {
                Circle()
                    .fill(provider.isPhoneReachable ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(provider.isPhoneReachable ? "Connected" : "Disconnected")
                    .font(.caption)
            }

            // Latest location
            if let location = provider.latestLocation {
                Text("Accuracy: ±\(Int(location.horizontalAccuracyMeters))m")
                    .font(.caption2)
            }
        }
    }
}
```

##### Error Handling

```swift
struct WatchContentView: View {
    @Environment(WatchLocationProvider.self) private var provider
    @State private var error: UserFacingError?

    var body: some View {
        content
            .errorAlert(error: $error) {
                await provider.startTracking()
            }
            .task(id: provider.lastError?.localizedDescription) {
                if let internalError = provider.lastError {
                    error = UserFacingError.from(internalError)
                }
            }
    }
}
```

#### Thread Safety

All public properties are `@MainActor` isolated. Delegate callbacks are `nonisolated` and dispatch to main thread.

#### Performance Characteristics

- **GPS Update Rate**: ~1Hz (HealthKit workout with `.other` activity)
- **Transmission Rate**: ~2Hz max (application context throttled)
- **Interactive Message Latency**: <100ms (when reachable)
- **Battery Life**: >8 hours continuous GPS tracking
- **Memory Usage**: <25MB target (watchOS)

---

## Utilities Layer

### PerformanceMonitor

**File**: `Utilities/PerformanceMonitor.swift`
**Availability**: iOS 14.0+, watchOS 7.0+, macOS 11.0+

**Purpose**: Monitors application performance and battery metrics.

#### Overview

`PerformanceMonitor` tracks critical performance indicators:
- GPS update latency (target: <500ms p95)
- WatchConnectivity message latency (target: <100ms when reachable)
- Memory usage (iOS <50MB, Watch <25MB)
- CPU usage (average <10%)
- Battery drain rate (percent per hour)

**Pattern**: Singleton with automatic metrics collection.

#### Public Interface

```swift
@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
@MainActor
public final class PerformanceMonitor
```

#### Properties

```swift
public static let shared: PerformanceMonitor
```
Singleton instance.

##### Performance Metrics

```swift
public private(set) var memoryUsageMB: Double
```
Current memory usage in megabytes. Updated every 5 seconds.

```swift
public private(set) var cpuUsagePercent: Double
```
Current CPU usage percentage (0-100). Updated every 5 seconds.

```swift
public private(set) var batteryLevel: Double
```
Current battery level (0.0-1.0). Updated via NotificationCenter.

```swift
public private(set) var batteryDrainRate: Double
```
Battery drain rate (percent per hour). Calculated from battery level changes over time.

##### Performance Targets

```swift
public let gpsLatencyTarget: TimeInterval = 0.5  // 500ms
public let messageLatencyTarget: TimeInterval = 0.1  // 100ms
public let memoryTargetMB_iOS: Double = 50.0
public let memoryTargetMB_Watch: Double = 25.0
public let cpuTargetPercent: Double = 10.0
public let lowBatteryThreshold: Double = 0.20  // 20%
public let criticalBatteryThreshold: Double = 0.10  // 10%
```

##### Computed Properties

```swift
public var averageGPSLatency: TimeInterval
```
Average GPS latency from last 100 samples.

```swift
public var p95GPSLatency: TimeInterval
```
95th percentile GPS latency from last 100 samples.

```swift
public var averageMessageLatency: TimeInterval
```
Average message latency from last 100 samples.

```swift
public var p95MessageLatency: TimeInterval
```
95th percentile message latency from last 100 samples.

```swift
public var isLowBattery: Bool
```
Whether battery is at or below 20%.

```swift
public var isCriticalBattery: Bool
```
Whether battery is at or below 10%.

```swift
public var batteryPercentage: Int
```
Battery percentage (0-100).

#### Methods

##### GPS Latency Tracking

```swift
public func recordGPSLatency(_ latency: TimeInterval)
```

Records GPS update latency.

**Parameters**:
- `latency`: Time interval from GPS request to receipt (seconds)

**Behavior**:
- Appends to latency samples (max 100 samples)
- Logs warning if exceeds 500ms target
- Logs debug message with latency in milliseconds

**Usage**:
```swift
let gpsTimestamp = Date()
// ... wait for GPS update ...
let latency = Date().timeIntervalSince(gpsTimestamp)
PerformanceMonitor.shared.recordGPSLatency(latency)
```

##### Message Latency Tracking

```swift
public func recordMessageSent(messageId: String)
```

Records that a message was sent (start latency timer).

**Parameters**:
- `messageId`: Unique identifier for the message

**Usage**:
```swift
let messageId = UUID().uuidString
PerformanceMonitor.shared.recordMessageSent(messageId: messageId)
session.sendMessage(dict, replyHandler: { reply in
    PerformanceMonitor.shared.recordMessageReceived(messageId: messageId)
})
```

```swift
public func recordMessageReceived(messageId: String)
```

Records that a message was received/acknowledged (stop latency timer).

**Parameters**:
- `messageId`: Unique identifier for the message

**Behavior**:
- Calculates latency from sent timestamp
- Appends to latency samples (max 100 samples)
- Logs warning if exceeds 100ms target
- Logs debug message with latency in milliseconds

##### Performance Summary

```swift
public func getPerformanceSummary() -> PerformanceSummary
```

Returns a snapshot of all performance metrics.

**Returns**: `PerformanceSummary` struct with all current metrics.

**Usage**:
```swift
let summary = PerformanceMonitor.shared.getPerformanceSummary()
print("GPS latency p95: \(Int(summary.gpsLatencyP95 * 1000))ms")
print("Memory usage: \(Int(summary.memoryUsageMB))MB")
print("Meets targets: GPS=\(summary.meetsGPSTarget), Memory=\(summary.meetsMemoryTarget)")
```

```swift
public func logMetrics()
```

Logs current performance metrics to OSLog.

**Output**:
```
Performance Metrics:
- GPS Latency: avg=250ms, p95=450ms
- Message Latency: avg=50ms, p95=80ms
- Memory: 35MB
- CPU: 5%
- Battery: 85%, drain=8.5%/hour
```

##### Testing Support

```swift
public func resetMetrics()
```

Resets all metrics (useful for testing). Clears all latency samples and pending messages.

#### Supporting Types

##### PerformanceSummary

```swift
@available(iOS 14.0, watchOS 7.0, macOS 11.0, *)
public struct PerformanceSummary: Sendable {
    public let gpsLatencyAvg: TimeInterval
    public let gpsLatencyP95: TimeInterval
    public let messageLatencyAvg: TimeInterval
    public let messageLatencyP95: TimeInterval
    public let memoryUsageMB: Double
    public let cpuUsagePercent: Double
    public let batteryLevel: Double
    public let batteryDrainRate: Double

    public var meetsGPSTarget: Bool  // p95 < 500ms
    public var meetsMessageTarget: Bool  // p95 < 100ms
    public var meetsMemoryTarget: Bool  // iOS <50MB, Watch <25MB
    public var meetsCPUTarget: Bool  // <10%
    public var isLowBattery: Bool  // <=20%
    public var isCriticalBattery: Bool  // <=10%
}
```

#### Usage Examples

##### Basic Tracking

```swift
import PetTrackerFeature

// Track GPS latency
let startTime = Date()
locationManager.startUpdatingLocation()
// ... wait for location update ...
let latency = Date().timeIntervalSince(startTime)
PerformanceMonitor.shared.recordGPSLatency(latency)

// Track message latency
let messageId = "\(sequence)"
PerformanceMonitor.shared.recordMessageSent(messageId: messageId)
session.sendMessage(dict) { reply in
    PerformanceMonitor.shared.recordMessageReceived(messageId: messageId)
}
```

##### Battery-Aware Throttling

```swift
func shouldThrottle() -> Bool {
    let monitor = PerformanceMonitor.shared

    if monitor.isCriticalBattery {
        // Aggressive throttling at <10%
        return true
    } else if monitor.isLowBattery {
        // Moderate throttling at <20%
        return shouldThrottleModerately()
    } else {
        // Normal throttling
        return shouldThrottleNormally()
    }
}
```

##### Performance Reporting

```swift
Task {
    while isTracking {
        try await Task.sleep(for: .seconds(60))

        let summary = PerformanceMonitor.shared.getPerformanceSummary()

        // Check targets
        if !summary.meetsGPSTarget {
            Logger.performance.warning("GPS latency exceeds target")
        }

        if !summary.meetsMemoryTarget {
            Logger.performance.warning("Memory usage exceeds target")
        }

        // Log full metrics
        PerformanceMonitor.shared.logMetrics()
    }
}
```

#### Thread Safety

`PerformanceMonitor` is `@MainActor` isolated. All methods must be called from the main thread.

#### Automatic Metrics Collection

The monitor automatically collects metrics every 5 seconds:
- Memory usage (via `mach_task_basic_info`)
- CPU usage (via `task_threads` and `thread_basic_info`)
- Battery level (via UIDevice/WKInterfaceDevice notifications)

---

### Logging

**File**: `Utilities/Logging.swift`

**Purpose**: Centralized logging subsystems for structured logging.

#### Overview

Provides pre-configured `OSLog.Logger` instances for different subsystems:
- GPS location tracking
- WatchConnectivity messaging
- HealthKit workout sessions
- Performance metrics
- Crash reporting

**Pattern**: Static logger instances with subsystem/category organization.

#### Public Interface

```swift
import OSLog

extension Logger {
    // iOS location tracking
    public static let iOSLocation = Logger(subsystem: "com.pettracker", category: "ios-location")

    // Watch location tracking
    public static let watchLocation = Logger(subsystem: "com.pettracker", category: "watch-location")

    // WatchConnectivity
    public static let connectivity = Logger(subsystem: "com.pettracker", category: "connectivity")

    // HealthKit workout sessions
    public static let healthKit = Logger(subsystem: "com.pettracker", category: "healthkit")

    // Performance monitoring
    public static let performance = Logger(subsystem: "com.pettracker", category: "performance")

    // Crash reporting
    public static let crashReporter = Logger(subsystem: "com.pettracker", category: "crash-reporter")
}
```

#### Usage Examples

```swift
import OSLog
import PetTrackerFeature

// Log GPS updates
Logger.watchLocation.info("Starting GPS tracking")
Logger.watchLocation.debug("GPS update: lat=\(latitude), lon=\(longitude)")
Logger.watchLocation.error("GPS permission denied")

// Log WatchConnectivity
Logger.connectivity.info("WCSession activated: reachable=\(isReachable)")
Logger.connectivity.debug("Sending location fix #\(sequence)")
Logger.connectivity.warning("Session not reachable, using file transfer")
Logger.connectivity.error("Failed to send message: \(error.localizedDescription)")

// Log HealthKit
Logger.healthKit.info("Starting workout session")
Logger.healthKit.debug("Workout session started successfully")
Logger.healthKit.error("Failed to start workout: \(error.localizedDescription)")

// Log performance
Logger.performance.info("GPS latency: \(latencyMs)ms")
Logger.performance.warning("Memory usage \(memoryMB)MB exceeds target")
Logger.performance.debug("Battery: \(batteryPct)%, drain rate: \(drainRate)%/hour")
```

#### Log Levels

- **debug**: Detailed diagnostic information (development only)
- **info**: Informational messages (normal operation)
- **warning**: Warning conditions (recoverable issues)
- **error**: Error conditions (failures that need attention)
- **fault**: Critical failures (app cannot continue)

#### Viewing Logs

**Console.app** (macOS):
1. Open Console.app
2. Connect iPhone/Watch via USB
3. Filter by subsystem: `com.pettracker`
4. Filter by category: `ios-location`, `watch-location`, `connectivity`, etc.

**Instruments** (Xcode):
1. Product → Profile
2. Choose "os_signpost" or "Logging" template
3. Filter by subsystem/category

**Command Line**:
```bash
# Stream logs from device
log stream --device-name "iPhone" --predicate 'subsystem == "com.pettracker"'

# Show logs for specific category
log show --predicate 'subsystem == "com.pettracker" AND category == "connectivity"'
```

---

## Presentation Layer

The presentation layer contains SwiftUI views and view modifiers for user interface.

### ErrorAlert

**File**: `Views/Components/ErrorAlert.swift`
**Availability**: iOS 15.0+, watchOS 8.0+, macOS 12.0+

**Purpose**: View modifier for displaying user-friendly error alerts with retry capability.

#### Overview

`ErrorAlertModifier` provides consistent error presentation across the app with:
- User-friendly error messages
- Recovery suggestions
- Retry button for retryable errors
- Settings button for permission errors
- Dismissible alerts

**Pattern**: SwiftUI ViewModifier for reusable error handling.

#### Public Interface

```swift
@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
public struct ErrorAlertModifier: ViewModifier
```

#### Properties

```swift
@Binding var error: UserFacingError?
```
The current error to display. `nil` when no error.

```swift
var retryAction: (() async -> Void)?
```
Optional retry action to execute when user taps retry button.

#### View Extension

```swift
@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
extension View {
    public func errorAlert(
        error: Binding<UserFacingError?>,
        retryAction: (() async -> Void)? = nil
    ) -> some View
}
```

Presents error alerts with user-friendly messages and retry capability.

**Parameters**:
- `error`: Binding to current error (`nil` when no error)
- `retryAction`: Optional async action to execute when user taps retry

**Returns**: Modified view with error alert handling.

#### Alert Behavior

**Title**: Error description (e.g., "Location Access Denied")

**Message**:
- Failure reason (e.g., "The app does not have permission to access your location.")
- Recovery suggestion (e.g., "Go to Settings > Privacy & Security > Location Services...")

**Buttons**:
- **Retry**: Shown if `error.isRetryable` and `retryAction` provided
- **Open Settings**: Shown if error is `.locationPermissionDenied` or `.locationServicesDisabled`
- **Dismiss**: Always shown (cancel role)

**Loading State**: Shows "Retrying..." while retry action executes.

#### Usage Examples

##### Basic Error Alert

```swift
struct ContentView: View {
    @State private var error: UserFacingError?

    var body: some View {
        content
            .errorAlert(error: $error) {
                // Retry action
                await retryOperation()
            }
    }
}
```

##### With PetLocationManager

```swift
struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var error: UserFacingError?

    var body: some View {
        content
            .errorAlert(error: $error) {
                await manager.startTracking()
            }
            .task(id: manager.lastError?.localizedDescription) {
                if let internalError = manager.lastError {
                    error = UserFacingError.from(internalError)
                }
            }
    }
}
```

##### Manual Error Display

```swift
Button("Trigger Error") {
    error = .locationPermissionDenied
}
.errorAlert(error: $error)
```

#### Thread Safety

Must be used from main thread (@MainActor context).

---

### ConnectionStatusView

**File**: `Views/Components/ConnectionStatusView.swift`
**Availability**: iOS 15.0+, watchOS 8.0+, macOS 12.0+

**Purpose**: Displays WatchConnectivity connection status with visual indicators.

#### Overview

`ConnectionStatusView` shows:
- Color-coded status indicator (green/orange/red)
- Connection status message
- Retry button when disconnected
- Loading state during retry
- Pulse animation for connecting state

**Pattern**: Reusable SwiftUI component.

#### Public Interface

```swift
@available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
public struct ConnectionStatusView: View
```

#### Properties

```swift
let isActivated: Bool
```
Whether WCSession is activated.

```swift
let isReachable: Bool
```
Whether Watch is currently reachable.

```swift
let statusMessage: String
```
Connection status message to display.

```swift
var retryAction: (() async -> Void)?
```
Optional retry action to execute when user taps retry button.

#### Initializer

```swift
public init(
    isActivated: Bool,
    isReachable: Bool,
    statusMessage: String,
    retryAction: (() async -> Void)? = nil
)
```

Creates a connection status view.

**Parameters**:
- `isActivated`: Whether WCSession is activated
- `isReachable`: Whether Watch is reachable
- `statusMessage`: Status message to display
- `retryAction`: Optional action to execute on retry

#### Visual States

**Connected** (isActivated = true, isReachable = true):
- Green indicator circle
- Primary text color
- Light gray background
- No retry button

**Disconnected** (isActivated = true, isReachable = false):
- Red indicator circle
- Red text color
- Light red background
- Retry button shown

**Connecting** (isActivated = false):
- Orange indicator circle with pulse animation
- Secondary text color
- Light orange background
- Retry button shown

#### Usage Examples

##### With PetLocationManager

```swift
struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        VStack {
            ConnectionStatusView(
                isActivated: manager.isSessionActivated,
                isReachable: manager.isWatchReachable,
                statusMessage: manager.connectionStatus
            ) {
                await manager.startTracking()
            }

            // Your content
        }
    }
}
```

##### Static Display

```swift
ConnectionStatusView(
    isActivated: true,
    isReachable: false,
    statusMessage: "Watch not reachable"
)
```

##### Custom Retry Action

```swift
ConnectionStatusView(
    isActivated: session.activationState == .activated,
    isReachable: session.isReachable,
    statusMessage: statusText
) {
    // Custom retry logic
    session.activate()
    try await Task.sleep(for: .seconds(2))
}
```

#### Thread Safety

Must be used from main thread (@MainActor context).

#### Accessibility

- Status message has `.subheadline` font with `.medium` weight
- Color indicators include text descriptions
- Retry button has accessible label

---

## Complete Examples

See the `docs/examples/` directory for complete, compilable examples:

- **BasicUsage.swift**: Complete iOS app with location tracking
- **ErrorHandling.swift**: Error handling with retry logic
- **WatchApp.swift**: Watch app GPS tracking

---

## Migration Guide

For migrating between versions, see [`docs/MIGRATION_GUIDE.md`](MIGRATION_GUIDE.md).

---

## Architecture Diagrams

For visual architecture documentation, see [`docs/ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Integration Guide

For step-by-step integration instructions, see [`docs/INTEGRATION_GUIDE.md`](INTEGRATION_GUIDE.md).

---

## Contributing

For development guidelines, see [`CLAUDE.md`](../CLAUDE.md).

---

**Last Updated**: 2025-11-08
**Version**: 0.1.0
**Maintained by**: PetTracker Development Team
