# PetTracker Integration Guide

**Version**: 0.1.0
**Last Updated**: 2025-11-08
**Swift**: 6.2.1
**iOS**: 26.0+
**watchOS**: 26.0+

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [iOS Integration](#ios-integration)
3. [watchOS Integration](#watchos-integration)
4. [Advanced Topics](#advanced-topics)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

- Xcode 26.1+ (macOS)
- Swift 6.2+
- iOS 26.0+ device (iPhone)
- watchOS 26.0+ device (Apple Watch)
- Apple Developer Account (for device deployment)

### Installation

#### Option 1: Swift Package Manager (Recommended)

1. Add package dependency to your project:

```swift
// In Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/pet-tracker", from: "0.1.0")
]
```

2. Add to target dependencies:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "PetTrackerFeature", package: "pet-tracker")
        ]
    )
]
```

#### Option 2: Local Package

1. Copy `PetTrackerPackage` to your project directory
2. Add local package in Xcode:
   - File → Add Package Dependencies → Add Local...
   - Select `PetTrackerPackage` folder

### Required Entitlements

#### iOS App Entitlements

Create or edit `YourApp.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- WatchConnectivity -->
    <key>com.apple.developer.associated-appextension</key>
    <true/>

    <!-- Background Location -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>
</dict>
</plist>
```

#### Watch App Entitlements

Create or edit `YourWatchApp.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- WatchConnectivity -->
    <key>com.apple.developer.associated-appextension</key>
    <true/>

    <!-- HealthKit -->
    <key>com.apple.developer.healthkit</key>
    <true/>

    <!-- Background Location -->
    <key>UIBackgroundModes</key>
    <array>
        <string>workout-processing</string>
        <string>location</string>
    </array>
</dict>
</plist>
```

### Info.plist Configuration

#### iOS App Info.plist

Add location permission descriptions:

```xml
<!-- Location Usage Descriptions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>PetTracker needs your location to calculate distance to your pet.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>PetTracker needs your location to track distance to your pet even when the app is in the background.</string>
```

#### Watch App Info.plist

Add location and HealthKit permission descriptions:

```xml
<!-- Location Usage Descriptions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>PetTracker needs location access to track your pet's GPS position.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>PetTracker needs location access to continuously track your pet's GPS position.</string>

<!-- HealthKit Usage Descriptions -->
<key>NSHealthShareUsageDescription</key>
<string>PetTracker uses HealthKit workouts to enable extended GPS tracking.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>PetTracker creates workout sessions to track your pet's location.</string>
```

---

## iOS Integration

### Basic Setup

#### 1. Import PetTrackerFeature

```swift
import SwiftUI
import PetTrackerFeature

@main
struct YourApp: App {
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

#### 2. Create Main View

```swift
import SwiftUI
import PetTrackerFeature

struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var error: UserFacingError?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Connection status
                ConnectionStatusView(
                    isActivated: manager.isSessionActivated,
                    isReachable: manager.isWatchReachable,
                    statusMessage: manager.connectionStatus
                ) {
                    await manager.startTracking()
                }

                // Pet location info
                if let location = manager.latestPetLocation {
                    petLocationView(location)
                } else {
                    Text("Waiting for pet location...")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("PetTracker")
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

    @ViewBuilder
    private func petLocationView(_ location: LocationFix) -> some View {
        VStack(spacing: 12) {
            // Distance
            if let distance = manager.distanceFromOwner {
                Label {
                    Text("\(Int(distance))m away")
                        .font(.title)
                } icon: {
                    Image(systemName: "location.circle.fill")
                        .foregroundStyle(.blue)
                }
            }

            // Battery
            if let battery = manager.petBatteryLevel {
                Label {
                    Text("\(battery)% battery")
                        .foregroundStyle(battery < 20 ? .red : .primary)
                } icon: {
                    Image(systemName: batteryIcon(for: battery))
                        .foregroundStyle(battery < 20 ? .red : .green)
                }
            }

            // Accuracy
            if let accuracy = manager.accuracyMeters {
                Label {
                    Text("±\(Int(accuracy))m accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "location.fill")
                }
            }

            // Time since update
            if let timeSince = manager.timeSinceLastUpdate {
                Text("Updated \(Int(timeSince))s ago")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(12)
    }

    private func batteryIcon(for level: Int) -> String {
        switch level {
        case 0..<10: return "battery.0"
        case 10..<25: return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default: return "battery.100"
        }
    }
}
```

### Consuming Location Data

#### Access Properties

```swift
struct DistanceView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        if let distance = manager.distanceFromOwner {
            Text("Pet is \(Int(distance))m away")
        }
    }
}
```

#### Access Latest Location

```swift
struct CoordinatesView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        if let location = manager.latestPetLocation {
            VStack {
                Text("Lat: \(location.coordinate.latitude)")
                Text("Lon: \(location.coordinate.longitude)")
                Text("Seq: #\(location.sequence)")
            }
        }
    }
}
```

#### Access Location History

```swift
struct TrailView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        List(manager.locationHistory) { fix in
            HStack {
                VStack(alignment: .leading) {
                    Text("\(fix.coordinate.latitude), \(fix.coordinate.longitude)")
                        .font(.caption)
                    Text("±\(Int(fix.horizontalAccuracyMeters))m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(fix.age))s ago")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Trail (\(manager.locationHistory.count) fixes)")
    }
}
```

### Handling Errors

```swift
struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var error: UserFacingError?

    var body: some View {
        content
            .errorAlert(error: $error) {
                // Retry action
                await manager.startTracking()
            }
            .task(id: manager.lastError?.localizedDescription) {
                // Map internal error to user-facing error
                if let internalError = manager.lastError {
                    error = UserFacingError.from(internalError)
                }
            }
    }
}
```

### Lifecycle Management

```swift
struct ContentView: View {
    @Environment(PetLocationManager.self) private var manager

    var body: some View {
        content
            .task {
                // Start tracking when view appears
                await manager.startTracking()
            }
            .onDisappear {
                // Stop tracking when view disappears
                manager.stopTracking()
            }
    }
}
```

### Background Modes

To receive location updates in the background, enable background modes in Xcode:

1. Select your iOS app target
2. Go to "Signing & Capabilities"
3. Add "Background Modes" capability
4. Check "Location updates"

---

## watchOS Integration

### Basic Setup

#### 1. Import PetTrackerFeature

```swift
import SwiftUI
import PetTrackerFeature

@main
struct YourWatchApp: App {
    @State private var locationProvider = WatchLocationProvider()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(locationProvider)
        }
    }
}
```

#### 2. Create Watch View

```swift
import SwiftUI
import PetTrackerFeature

struct WatchContentView: View {
    @Environment(WatchLocationProvider.self) private var provider
    @State private var error: UserFacingError?

    var body: some View {
        VStack(spacing: 12) {
            // Tracking button
            if provider.isTracking {
                Button {
                    Task { await provider.stopTracking() }
                } label: {
                    Label("Stop Tracking", systemImage: "stop.circle.fill")
                }
                .foregroundStyle(.red)
            } else {
                Button {
                    Task { await provider.startTracking() }
                } label: {
                    Label("Start Tracking", systemImage: "location.circle.fill")
                }
                .foregroundStyle(.green)
            }

            // Status indicators
            if provider.isTracking {
                statusView
            }
        }
        .padding()
        .errorAlert(error: $error) {
            await provider.startTracking()
        }
        .task(id: provider.lastError?.localizedDescription) {
            if let internalError = provider.lastError {
                error = UserFacingError.from(internalError)
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        VStack(spacing: 8) {
            // Battery
            HStack {
                Image(systemName: "battery.100")
                    .foregroundStyle(provider.batteryLevel < 0.2 ? .red : .green)
                Text("\(Int(provider.batteryLevel * 100))%")
                    .font(.caption)
            }

            // Fixes sent
            Text("\(provider.fixesSent) fixes sent")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Connection status
            HStack {
                Circle()
                    .fill(provider.isPhoneReachable ? .green : .red)
                    .frame(width: 6, height: 6)
                Text(provider.isPhoneReachable ? "Connected" : "Offline")
                    .font(.caption2)
            }

            // Latest location
            if let location = provider.latestLocation {
                Text("±\(Int(location.horizontalAccuracyMeters))m")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(8)
    }
}
```

### Managing HealthKit Workout

The `WatchLocationProvider` automatically manages HealthKit workout sessions. You don't need to manually start/stop workouts.

**Automatic Behavior**:
- `startTracking()` → Creates and starts HealthKit workout session
- `stopTracking()` → Ends and finishes workout session
- Workout type: `.other` (provides most frequent GPS updates)
- Location type: `.outdoor`

**Required Permissions**:
- HealthKit authorization requested automatically on first `startTracking()` call
- User must grant permission for workout tracking

### Battery Optimization

The provider implements adaptive throttling based on battery level:

```swift
struct BatteryAwareView: View {
    @Environment(WatchLocationProvider.self) private var provider

    var batteryStrategy: String {
        let level = provider.batteryLevel
        if level <= 0.10 {
            return "Aggressive throttling (5s)"
        } else if level <= 0.20 {
            return "Moderate throttling (2s stationary, 1s moving)"
        } else {
            return "Normal throttling (0.5s)"
        }
    }

    var body: some View {
        VStack {
            Text("Battery: \(Int(provider.batteryLevel * 100))%")
            Text(batteryStrategy)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

---

## Advanced Topics

### Custom Retry Logic

Implement custom retry behavior for connection failures:

```swift
struct SmartRetryView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var retryCount = 0
    @State private var retryDelay: TimeInterval = 1.0

    func retryWithBackoff() async {
        retryCount += 1

        // Exponential backoff (max 30 seconds)
        retryDelay = min(pow(2.0, Double(retryCount)), 30.0)

        Logger.connectivity.info("Retry #\(retryCount) after \(retryDelay)s")

        try? await Task.sleep(for: .seconds(retryDelay))
        await manager.startTracking()

        // Reset counter on success
        if manager.isSessionActivated {
            retryCount = 0
            retryDelay = 1.0
        }
    }

    var body: some View {
        content
            .errorAlert(error: $error) {
                await retryWithBackoff()
            }
    }
}
```

### Performance Monitoring

Track performance metrics in your app:

```swift
import PetTrackerFeature

struct PerformanceView: View {
    @State private var summary: PerformanceSummary?

    var body: some View {
        VStack {
            if let summary {
                Text("GPS Latency: \(Int(summary.gpsLatencyP95 * 1000))ms")
                Text("Message Latency: \(Int(summary.messageLatencyP95 * 1000))ms")
                Text("Memory: \(Int(summary.memoryUsageMB))MB")
                Text("CPU: \(Int(summary.cpuUsagePercent))%")
                Text("Battery: \(Int(summary.batteryLevel * 100))%")
            }
        }
        .task {
            while true {
                summary = await PerformanceMonitor.shared.getPerformanceSummary()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
}
```

### Custom Location Filtering

Filter location updates based on accuracy:

```swift
extension PetLocationManager {
    var highQualityLocation: LocationFix? {
        guard let location = latestPetLocation,
              location.hasValidAccuracy,
              location.horizontalAccuracyMeters < 20 else {
            return nil
        }
        return location
    }

    var recentLocations: [LocationFix] {
        locationHistory.filter { $0.age < 60 } // Last 60 seconds
    }
}
```

### MapKit Integration

Display pet location on a map:

```swift
import MapKit
import SwiftUI
import PetTrackerFeature

struct MapView: View {
    @Environment(PetLocationManager.self) private var manager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var petAnnotation: [LocationAnnotation] {
        guard let location = manager.latestPetLocation else { return [] }
        return [
            LocationAnnotation(
                coordinate: location.coordinate.clLocationCoordinate,
                title: "Pet",
                subtitle: "Battery: \(location.batteryPercentage)%"
            )
        ]
    }

    var ownerAnnotation: [LocationAnnotation] {
        guard let location = manager.ownerLocation else { return [] }
        return [
            LocationAnnotation(
                coordinate: location.coordinate,
                title: "You",
                subtitle: "Owner"
            )
        ]
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: petAnnotation + ownerAnnotation) { annotation in
            MapMarker(coordinate: annotation.coordinate, tint: annotation.title == "Pet" ? .blue : .green)
        }
        .onChange(of: manager.latestPetLocation) { _, newLocation in
            if let location = newLocation {
                withAnimation {
                    region.center = location.coordinate.clLocationCoordinate
                }
            }
        }
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
}
```

---

## Testing

### Unit Testing Services

Mock dependencies for testing:

```swift
import Testing
@testable import PetTrackerFeature

class MockLocationManager: CLLocationManager {
    var didRequestAuthorization = false
    var didStartUpdating = false

    override func requestWhenInUseAuthorization() {
        didRequestAuthorization = true
    }

    override func startUpdatingLocation() {
        didStartUpdating = true
    }
}

class MockWCSession: WCSession {
    var didActivate = false
    var mockIsReachable = false

    override var isReachable: Bool { mockIsReachable }

    override func activate() {
        didActivate = true
    }
}

@Test("PetLocationManager initialization")
func testInitialization() async throws {
    let mockCLLocationManager = MockLocationManager()
    let mockSession = MockWCSession()

    let manager = await PetLocationManager(
        locationManager: mockCLLocationManager,
        session: mockSession
    )

    #expect(mockSession.didActivate)
}
```

### Integration Testing

Test WatchConnectivity communication:

```swift
@Test("Location transmission")
func testLocationTransmission() async throws {
    // Setup Watch provider
    let watchProvider = WatchLocationProvider()
    await watchProvider.startTracking()

    // Wait for location fix
    try await Task.sleep(for: .seconds(5))

    #expect(watchProvider.latestLocation != nil)
    #expect(watchProvider.fixesSent > 0)
}
```

### UI Testing

Test error alert presentation:

```swift
@MainActor
@Test("Error alert displays")
func testErrorAlert() {
    let error: UserFacingError? = .locationPermissionDenied

    // Verify alert content
    #expect(error?.errorDescription == "Location Access Denied")
    #expect(error?.isRetryable == false)
}
```

---

## Troubleshooting

### WatchConnectivity Not Connecting

**Symptoms**: `isSessionActivated` is `false`, `isWatchReachable` is `false`

**Solutions**:
1. Check Bluetooth is enabled on both devices
2. Ensure devices are paired (open Watch app on iPhone)
3. Check both apps have WatchConnectivity entitlements
4. Restart both devices
5. Check logs for activation errors:
   ```bash
   log stream --predicate 'subsystem == "com.pettracker" AND category == "connectivity"'
   ```

### Location Permission Denied

**Symptoms**: `lastError` is `LocationError.permissionDenied`

**Solutions**:
1. Open Settings → Privacy & Security → Location Services
2. Enable Location Services (system-wide)
3. Find your app in the list
4. Select "While Using the App" or "Always"
5. For watchOS: Check permissions on Watch app via iPhone Watch app

### GPS Accuracy Too Low

**Symptoms**: `horizontalAccuracyMeters` > 50, `hasValidAccuracy` is `false`

**Solutions**:
1. Move to area with clear view of sky
2. Avoid dense tree cover, tall buildings, underground areas
3. Wait 30-60 seconds for GPS to acquire satellites
4. Check Watch has clear view (not under clothing)

### HealthKit Workout Fails

**Symptoms**: `startTracking()` fails, error mentions HealthKit

**Solutions**:
1. Open Settings → Privacy & Security → Health → Your App
2. Enable "Workouts" permission
3. Check Watch app Info.plist has HealthKit usage descriptions
4. Check Watch app entitlements include HealthKit capability
5. Try restarting Watch app

### Battery Drains Too Quickly

**Symptoms**: Watch battery drops fast during tracking

**Solutions**:
1. Check adaptive throttling is working:
   ```swift
   Logger.performance.info("Battery: \(provider.batteryLevel)")
   ```
2. Reduce GPS accuracy if acceptable:
   ```swift
   locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
   ```
3. Use aggressive throttling manually:
   ```swift
   // In WatchLocationProvider
   private let contextThrottleInterval: TimeInterval = 2.0  // Increase from 0.5s
   ```

### High Memory Usage

**Symptoms**: App crashes with memory warnings

**Solutions**:
1. Check location history size:
   ```swift
   print("History count: \(manager.locationHistory.count)")
   ```
2. Clear history periodically:
   ```swift
   manager.clearHistory()
   ```
3. Reduce history buffer size:
   ```swift
   // In PetLocationManager
   private let maxHistorySize = 50  // Reduce from 100
   ```

### Build Errors (Xcode 26.1)

**Symptoms**: Error 143 "Extensionless WatchKit app has a WatchKit extension"

**Solution**: See [`docs/architecture/watchapp2-bug-workaround.md`](architecture/watchapp2-bug-workaround.md) for detailed workaround.

---

## Support

For additional help:

- **Documentation**: [`docs/API_REFERENCE.md`](API_REFERENCE.md)
- **Architecture**: [`docs/ARCHITECTURE.md`](ARCHITECTURE.md)
- **Development Guidelines**: [`CLAUDE.md`](../CLAUDE.md)
- **Issues**: GitHub Issues (if open source)

---

**Last Updated**: 2025-11-08
**Version**: 0.1.0
**Maintained by**: PetTracker Development Team
