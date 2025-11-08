# PetTracker Pet Tracker - Project Specification

## Project Basics

### 1. What type of project is this?

**PetTracker** is a native iOS and watchOS companion application pair that transforms an Apple Watch into a real-time GPS tracker for pets. The Apple Watch is attached to a pet's collar to capture GPS coordinates, which are wirelessly transmitted to the owner's iPhone for live monitoring, distance calculation, and historical trail visualization.

**Project Type**: iOS/watchOS Companion App
**Architecture**: Workspace + Swift Package Manager
**Deployment**: Physical devices (iPhone + Apple Watch)
**Communication**: WatchConnectivity framework for device-to-device data relay

### 2. What is the primary programming language and version?

- **Language**: Swift 6.2.1
- **Concurrency**: Swift Concurrency (async/await, actors, @MainActor isolation) with strict mode
- **UI Framework**: SwiftUI (declarative, modern UI)
- **Minimum Deployment**:
  - iOS 26.0+
  - watchOS 26.0+
- **Development Tools**:
  - Xcode 26.1+ (currently affected by watchapp2 bug)
  - Swift Package Manager for modular architecture

### 3. What problem does this project solve?

**Primary Problem**: Pet owners need a way to track their pet's real-time location when the pet is wearing an Apple Watch but the owner may not be within visual range.

**Specific Use Cases**:
- **Off-leash dog parks**: Monitor distance and direction while dog explores
- **Hiking with pets**: Track pet's location on trails
- **Home monitoring**: Track pet location around property
- **Pet safety**: Quickly locate pet if they wander off
- **Activity tracking**: Visualize trails and movement patterns

**Solution Approach**:
1. Apple Watch (worn by pet) captures GPS fixes using HealthKit workout session
2. Location data transmitted to iPhone via triple-path WatchConnectivity messaging
3. iPhone displays real-time location, distance from owner, battery level, and historical trail
4. All processing happens on-device (no cloud services required)

## Technical Architecture

### Core Components

#### 1. Watch App (`PetTracker Watch App Extension`)

**Purpose**: GPS capture and transmission to iPhone

**Key Classes**:
- `WatchLocationProvider`: Manages GPS capture and WatchConnectivity relay
- `ContentView`: SwiftUI interface for tracking control
- `ExtensionDelegate`: Workout session lifecycle management

**GPS Configuration**:
- **Activity Type**: `.other` (provides most frequent updates)
- **Desired Accuracy**: `kCLLocationAccuracyBest` (highest precision)
- **Distance Filter**: `kCLDistanceFilterNone` (no throttling)
- **Update Frequency**: ~1Hz native Apple Watch GPS rate
- **Runtime Extension**: HealthKit workout session for background GPS

**Data Transmission Strategy** (Triple-Path):
1. **Application Context** (Background, latest-only)
   - 0.5s throttle: ~2Hz max update rate to phone
   - Accuracy bypass: Immediate update if horizontal accuracy changes >5m
   - Works in background

2. **Interactive Messages** (Foreground, immediate)
   - Requires phone reachability (Bluetooth range)
   - Immediate delivery when both devices active
   - Falls back to file transfer on failure

3. **File Transfer** (Background, queued)
   - Guaranteed delivery with automatic retry
   - Used when phone not reachable
   - Queued for offline periods

#### 2. iOS App (`PetTrackerPackage/Sources/PetTrackerFeature`)

**Purpose**: Receive GPS data, calculate distance, display location and trail

**Key Classes**:
- `PetLocationManager`: Receives Watch GPS via WatchConnectivity, tracks owner location
- `LocationFix`: Shared data model for GPS coordinates with metadata
- SwiftUI views: Display location, distance, battery, accuracy, historical trail

**State Management**:
- **@Observable**: Modern observable pattern for `PetLocationManager`
- **@State**: View-local state in SwiftUI
- **@Environment**: Shared services and app state
- **No ViewModels**: Pure SwiftUI MV pattern

**Received Data**:
- Latest pet location (lat/lon, altitude, accuracy)
- Battery level (Apple Watch battery percentage)
- Movement data (speed, course)
- Timestamp and sequence number
- Historical trail (last 100 GPS fixes)

**Calculated Metrics**:
- Distance from owner to pet (using iPhone GPS vs Watch GPS)
- Time since last update
- GPS accuracy in meters
- Battery status

### Data Models

#### LocationFix

```swift
public struct LocationFix: Codable, Equatable, Sendable {
    // Geographic data
    public let timestamp: Date
    public let source: Source  // .watchOS or .iOS
    public let coordinate: Coordinate  // lat/lon
    public let altitudeMeters: Double?

    // Accuracy metrics
    public let horizontalAccuracyMeters: Double
    public let verticalAccuracyMeters: Double

    // Motion data
    public let speedMetersPerSecond: Double
    public let courseDegrees: Double  // 0-360, 0 = true north
    public let headingDegrees: Double?  // nil for Watch (no compass)

    // Device metadata
    public let batteryFraction: Double  // 0.0-1.0
    public let sequence: Int  // Monotonic sequence number
}
```

**Encoding**: JSON with compact field names for efficient transmission
- `ts_unix_ms`: Unix milliseconds timestamp
- `lat`/`lon`: Coordinates
- `h_accuracy_m`: Horizontal accuracy meters
- `battery_pct`: Battery percentage

### Communication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Apple Watch (on pet collar)                                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  WatchLocationProvider                                    │  │
│  │  • CLLocationManager: ~1Hz GPS updates                    │  │
│  │  • HealthKit workout: Extended runtime                    │  │
│  │  • Convert CLLocation → LocationFix                       │  │
│  └───────────────────────┬───────────────────────────────────┘  │
│                          │                                       │
│                          ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  WatchConnectivity Triple-Path Messaging                  │  │
│  │  1. updateApplicationContext (0.5s throttle)              │  │
│  │  2. sendMessage (if reachable)                            │  │
│  │  3. transferFile (guaranteed delivery)                    │  │
│  └───────────────────────┬───────────────────────────────────┘  │
└────────────────────────────┼───────────────────────────────────┘
                             │ Bluetooth / Wi-Fi
                             │
┌────────────────────────────┼───────────────────────────────────┐
│  iPhone (owner monitoring) │                                    │
│                            ▼                                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  WCSessionDelegate (PetLocationManager)                   │  │
│  │  • didReceiveMessage                                      │  │
│  │  • didReceiveApplicationContext                           │  │
│  │  • didReceiveMessageData                                  │  │
│  │  • didReceive file                                        │  │
│  └───────────────────────┬───────────────────────────────────┘  │
│                          │                                       │
│                          ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  PetLocationManager (@Observable)                         │  │
│  │  • latestLocation: LocationFix?                           │  │
│  │  • locationHistory: [LocationFix] (last 100)              │  │
│  │  • ownerLocation: CLLocation? (iPhone GPS)                │  │
│  │  • distanceFromOwner: Double? (calculated)                │  │
│  │  • batteryLevel, accuracyMeters, lastUpdateTime           │  │
│  └───────────────────────┬───────────────────────────────────┘  │
│                          │                                       │
│                          ▼                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  SwiftUI Views                                            │  │
│  │  • Map with pet location marker                           │  │
│  │  • Distance display (owner → pet)                         │  │
│  │  • Battery level indicator                                │  │
│  │  • GPS accuracy indicator                                 │  │
│  │  • Historical trail overlay                               │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Performance Characteristics

### GPS Update Rates

| Component | Capture Rate | Transmission Rate | Latency |
|-----------|--------------|-------------------|---------|
| **Watch GPS Capture** | ~1Hz (native) | N/A | Immediate |
| **Application Context** | N/A | ~2Hz max (0.5s throttle) | <500ms |
| **Interactive Messages** | N/A | ~1-2Hz (when reachable) | <100ms |
| **File Transfer** | N/A | Queued (background) | Variable |

### Battery Life

**Apple Watch** (GPS tracking mode):
- ~8-10 hours continuous GPS with HealthKit workout session
- Battery level transmitted with each GPS fix
- Real-time battery monitoring on iPhone

**iPhone** (monitoring mode):
- Minimal impact (WatchConnectivity receiver + occasional own GPS)
- Native iOS background task management

### Data Efficiency

**LocationFix JSON Size**: ~200-300 bytes per fix
- Compact field names reduce payload size
- Binary data transmission via WatchConnectivity
- 100-fix history buffer: ~20-30KB total

## Reference Implementation

This project adapts patterns from the **GPS Relay Framework** (`/Users/zackjordan/code/jetson/dev/gps-relay-framework`):

### Inherited Patterns

1. **Triple-Path WatchConnectivity** (from `WatchLocationProvider`)
   - Application context with throttling
   - Interactive messaging when reachable
   - File transfer fallback with retry logic

2. **LocationFix Data Model** (from `LocationCore`)
   - Comprehensive GPS metadata
   - JSON serialization with compact field names
   - Sendable/Codable for cross-platform transfer

3. **Workout-Driven GPS** (from `WatchLocationProvider`)
   - HealthKit workout session for extended runtime
   - Background GPS capability
   - Activity type `.other` for maximum update frequency

4. **State Management** (from `LocationRelayService`)
   - @Observable pattern for reactive state
   - WCSession delegate handling
   - Connection status tracking

### Key Differences from Reference

| Feature | GPS Relay Framework | PetTracker |
|---------|---------------------|----------|
| **Swift Version** | Swift 6.0 | Swift 6.2.1 |
| **iOS Version** | iOS 18.0+ | iOS 26.0+ |
| **External Relay** | Optional WebSocket to Jetson/server | None (on-device only) |
| **Base Station GPS** | Optional iPhone GPS as "base" | iPhone GPS for owner location only |
| **Data Streams** | Remote + Base + Fused | Pet (Watch) + Owner (iPhone) |
| **Architecture** | Triple Package (Core, Watch, iOS) | Single Feature Package |
| **Telemetry** | Queue depth, drops, duplicates | Basic connection status |

## Development Workflow

### Project Structure

```
PetTracker-app/
├── Config/                         # XCConfig build settings
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   ├── Shared.xcconfig
│   └── PetTracker.entitlements      # App capabilities
├── PetTracker.xcworkspace/           # Workspace container
├── PetTracker.xcodeproj/             # App shell (minimal)
├── PetTracker/                       # iOS app target
│   ├── Assets.xcassets/
│   └── PetTrackerApp.swift          # @main entry point
├── PetTracker Watch App/             # Watch container
│   └── Info.plist                 # WKApplication=true
├── PetTracker Watch App Extension/   # Watch extension
│   ├── Info.plist                 # NSExtension config
│   ├── PetTrackerApp.swift          # Watch @main
│   ├── WatchLocationProvider.swift
│   └── ContentView.swift
└── PetTrackerPackage/                # All features and logic
    ├── Package.swift
    ├── Sources/
    │   └── PetTrackerFeature/
    │       ├── PetLocationManager.swift
    │       ├── LocationFix.swift
    │       └── [SwiftUI Views]
    └── Tests/
        └── PetTrackerFeatureTests/
```

### Build and Test (XcodeBuildMCP)

**Note**: Xcode 26.1 has a critical build system bug (error 143) for watchapp2 products. Current workaround uses separate installation (not App Store compatible).

```javascript
// Discover projects
discover_projs({ workspaceRoot: "/path/to/PetTracker-app" })

// List schemes
list_schemes({ workspacePath: "/path/to/PetTracker.xcworkspace" })

// Build iOS app for simulator
build_run_sim({
    workspacePath: "/path/to/PetTracker.xcworkspace",
    scheme: "PetTracker",
    simulatorName: "iPhone 16"
})

// Build Watch app for physical device
build_device({
    workspacePath: "/path/to/PetTracker.xcworkspace",
    scheme: "PetTracker Watch App",
    deviceId: "WATCH_UUID"
})

// Install on devices (separate installation workaround)
install_app_device({ deviceId: "IPHONE_UUID", appPath: "PetTracker.app" })
install_app_device({ deviceId: "WATCH_UUID", appPath: "PetTracker Watch App.app" })

// Run tests
swift_package_test({ packagePath: "/path/to/PetTrackerPackage" })
```

## Key Technologies

### Frameworks

- **SwiftUI**: Declarative UI for both iOS and watchOS
- **CoreLocation**: GPS capture on both platforms
- **WatchConnectivity**: Device-to-device communication
- **HealthKit**: Workout sessions for extended Watch GPS runtime
- **Observation**: @Observable macro for reactive state management

### Swift Language Features

- **Swift 6.2.1**: Latest Swift with strict concurrency checking
- **Sendable**: All types crossing concurrency boundaries are Sendable-conformant
- **@MainActor**: UI updates isolated to main thread
- **async/await**: Async operations throughout
- **@Observable**: Modern alternative to ObservableObject
- **Value types**: Prefer struct over class for models

### Design Patterns

- **MV (Model-View)**: No ViewModels, pure SwiftUI state management
- **Triple-Path Messaging**: Three complementary WatchConnectivity delivery paths
- **Throttling with Bypass**: Time-based throttle with accuracy-based bypass logic
- **Guaranteed Delivery**: File transfer retry on failure
- **State Machine**: Connection status tracking (connected, reachable, error states)

## Testing Strategy

### Swift Testing Framework

```swift
import Testing
import PetTrackerFeature

@Test func locationFixEncodesCorrectly() async throws {
    let fix = LocationFix(
        timestamp: Date(),
        source: .watchOS,
        coordinate: .init(latitude: 37.7749, longitude: -122.4194),
        altitudeMeters: 10.0,
        horizontalAccuracyMeters: 5.0,
        verticalAccuracyMeters: 10.0,
        speedMetersPerSecond: 0.5,
        courseDegrees: 180.0,
        headingDegrees: nil,
        batteryFraction: 0.85,
        sequence: 12345
    )

    let encoded = try JSONEncoder().encode(fix)
    let decoded = try JSONDecoder().decode(LocationFix.self, from: encoded)

    #expect(decoded == fix)
}

@Test func petLocationManagerCalculatesDistanceCorrectly() async throws {
    let manager = PetLocationManager()

    // Simulate Watch location (San Francisco)
    let petFix = LocationFix(
        timestamp: Date(),
        source: .watchOS,
        coordinate: .init(latitude: 37.7749, longitude: -122.4194),
        altitudeMeters: nil,
        horizontalAccuracyMeters: 10.0,
        verticalAccuracyMeters: 0.0,
        speedMetersPerSecond: 0.0,
        courseDegrees: 0.0,
        headingDegrees: nil,
        batteryFraction: 1.0,
        sequence: 1
    )

    // Test distance calculation logic
    // (Real tests would use actual CLLocation mocking)
}
```

### Test Coverage Goals

- **LocationFix**: 100% (data model, serialization)
- **WatchLocationProvider**: 80%+ (GPS capture, messaging)
- **PetLocationManager**: 80%+ (relay coordination, calculations)
- **SwiftUI Views**: Snapshot/preview testing

## Known Issues and Workarounds

### Xcode 26.1 Watchapp2 Bug (Error 143)

**Issue**: Xcode 26.1 generates both a real executable AND a stub for watchapp2 products, causing iOS to reject installation with:
```
MIInstallerErrorDomain error 143:
"Extensionless WatchKit app has a WatchKit extension"
```

**Workaround**: Separate Installation (development only)
1. Remove "Embed Watch Content" build phase from iOS target
2. Remove watch target dependency from iOS target
3. Build and install iOS app separately
4. Build and install Watch app separately

**Trade-off**: NOT App Store compatible (temporary until Apple fixes Xcode)

**Tracking**: Documented in `CURRENT_STATE.md` and `CLAUDE_CHANGES.md`

## Future Enhancements

### Planned Features

- [ ] Map view with pet location marker
- [ ] Historical trail visualization (polyline overlay)
- [ ] Distance alerts (notification when pet exceeds threshold)
- [ ] Battery alerts (notification when Watch battery low)
- [ ] Location export (GPX format)
- [ ] Multi-pet support (track multiple Watches)

### Performance Optimizations

- [ ] Adaptive throttling based on movement (faster when moving, slower when stationary)
- [ ] Geofencing (alert when pet leaves defined area)
- [ ] Energy monitoring (track battery drain rate)
- [ ] Offline queue management (store fixes when iPhone unreachable)

### Watch App Features

- [ ] Haptic feedback for tracking status
- [ ] Complications showing tracking duration
- [ ] Emergency stop button (ends workout and GPS)
- [ ] Manual location update trigger

## Development Guidelines

### Code Style

- **Naming**: `UpperCamelCase` for types, `lowerCamelCase` for properties/functions
- **Immutability**: Prefer `let` over `var`
- **Early Returns**: Avoid nested conditionals
- **Optionals**: Use `guard let` with failure paths, never force-unwrap

### SwiftUI Best Practices

- **State Management**: Use @State, @Observable, @Environment (no ViewModels)
- **Async Work**: Always use `.task { }` modifier (never `Task { }` in `onAppear`)
- **Small Views**: Extract reusable components
- **Accessibility**: Add accessibilityLabel for all interactive elements

### Concurrency Rules

- **@MainActor**: All UI updates must use @MainActor isolation
- **Sendable**: All types crossing concurrency boundaries must be Sendable
- **.task modifier**: For async operations tied to view lifecycle (auto-cancels)
- **No GCD**: Swift Concurrency only (no DispatchQueue)

## Resources

### Documentation

- `CLAUDE.md`: Comprehensive project guidelines and architecture
- `CURRENT_STATE.md`: Verified project state after setup
- `CLAUDE_CHANGES.md`: Session log of configuration verification
- [GPS Relay Framework README](../jetson/dev/gps-relay-framework/README.md): Reference implementation

### External References

- [Apple WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [HealthKit Workout Sessions](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings)
- [CoreLocation Best Practices](https://developer.apple.com/documentation/corelocation)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

**Last Updated**: 2025-11-07
**Project Status**: Active Development (blocked by Xcode 26.1 bug, workaround implemented)
**Target Release**: TBD (pending Xcode fix for App Store deployment)
