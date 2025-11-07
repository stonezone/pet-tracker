# pawWatch - Claude Development Guidelines

**Last Updated**: 2025-11-07
**Project**: Pet GPS Tracker (iOS/watchOS Companion App)
**Status**: Active Development

---

## Critical Time Awareness Protocol

**YOUR KNOWLEDGE CUTOFF**: January 31, 2025
**TODAY'S DATE**: November 7, 2025 (10 months past cutoff)

### Version Verification Mandate

**BEFORE making ANY assumption about technology versions, YOU MUST:**

1. **Web search** to verify current versions exist
2. **NEVER** assume versions don't exist based on cutoff knowledge
3. **Check release dates** for all dependencies
4. **Validate compatibility** between framework versions

### Current Verified Versions (as of 2025-11-07)

- ✅ **Swift 6.2** (Released: 2025-09-15) - Swift 6.2.1 patch likely available
- ✅ **iOS 26.0** (Released: 2025-09-15)
- ✅ **watchOS 26.0** (Released: 2025-09-15)
- ✅ **Xcode 26.1** (Released: 2025-11-03)

**Always use `/verify-versions` command when working with dependencies.**

---

## Project Mission

**pawWatch** transforms an Apple Watch into a real-time GPS tracker for pets. The Watch captures GPS coordinates while attached to a pet's collar and wirelessly transmits location data to the owner's iPhone for live monitoring, distance calculation, and trail visualization.

**Core Value**: On-device pet tracking without cloud services or subscriptions.

---

## Architecture Overview

### Clean Architecture Principles

This project follows **Clean Architecture** with clear separation of concerns:

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
│  • PetLocationManager: Coordinates location relay           │
│  • State management with Observation framework              │
│  • WCSession delegate handling                              │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│  Domain Layer (Business Logic)                              │
│  • LocationFix: Core data model (Codable, Sendable)         │
│  • Distance calculations                                    │
│  • GPS accuracy validation                                  │
│  • No framework dependencies                                │
└────────────────┬────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────┐
│  Infrastructure Layer (Platform Services)                   │
│  • WatchLocationProvider: GPS capture + WatchConnectivity   │
│  • CoreLocation integration                                 │
│  • HealthKit workout sessions                               │
│  • Triple-path messaging implementation                     │
└─────────────────────────────────────────────────────────────┘
```

### Module Boundaries

**Rule 1**: Dependencies flow INWARD only (Domain has zero dependencies)
**Rule 2**: Platform-specific code stays in Infrastructure layer
**Rule 3**: Business logic never touches UIKit/SwiftUI directly

---

## Module Structure

### pawWatchPackage (Swift Package)

All application logic lives in the Swift Package:

```
pawWatchPackage/
├── Package.swift
├── Sources/
│   └── pawWatchFeature/
│       ├── Models/
│       │   └── LocationFix.swift           # Domain model
│       ├── Services/
│       │   ├── PetLocationManager.swift    # iOS location coordinator
│       │   └── WatchLocationProvider.swift # Watch GPS + relay
│       └── Views/
│           ├── ContentView.swift           # iOS main view
│           ├── WatchContentView.swift      # Watch UI
│           └── Components/
│               ├── LocationDetailView.swift
│               └── BatteryIndicatorView.swift
└── Tests/
    └── pawWatchFeatureTests/
        ├── LocationFixTests.swift
        ├── PetLocationManagerTests.swift
        └── WatchLocationProviderTests.swift
```

### App Targets (Minimal)

```
pawWatch/                      # iOS app shell
└── pawWatchApp.swift         # @main entry (imports pawWatchFeature)

pawWatch Watch App Extension/  # Watch extension
└── pawWatchApp.swift         # @main entry (imports pawWatchFeature)
```

**Targets contain ONLY**:
- App entry point (`@main`)
- Asset catalogs
- Info.plist / entitlements
- Everything else is in the package

---

## Core Technologies

### WatchConnectivity Triple-Path Messaging

**Problem**: Single messaging path is unreliable (device sleep, range limits, background states)

**Solution**: Three complementary delivery mechanisms

#### 1. Application Context (Background, Latest-Only)

```swift
// 0.5s throttle with accuracy bypass
func sendLocationViaContext(_ fix: LocationFix) async {
    let now = Date()
    guard now.timeIntervalSince(lastContextUpdate) > 0.5 ||
          abs(fix.horizontalAccuracyMeters - lastAccuracy) > 5.0 else {
        return // Throttled
    }

    try? session.updateApplicationContext(fix.jsonDict)
    lastContextUpdate = now
}
```

**Characteristics**:
- ~2Hz max update rate (0.5s throttle)
- Works in background
- Only latest data (not queued)
- Bypasses throttle if accuracy changes >5m

#### 2. Interactive Messages (Foreground, Immediate)

```swift
// Immediate delivery when both devices active
func sendLocationViaMessage(_ fix: LocationFix) async {
    guard session.isReachable else { return }

    session.sendMessage(fix.jsonDict) { reply in
        print("Ack received")
    } errorHandler: { error in
        // Fall back to file transfer
        sendLocationViaFile(fix)
    }
}
```

**Characteristics**:
- Requires Bluetooth reachability
- <100ms latency when reachable
- Falls back to file transfer on failure

#### 3. File Transfer (Background, Queued)

```swift
// Guaranteed delivery with automatic retry
func sendLocationViaFile(_ fix: LocationFix) async {
    let url = temporaryFileURL()
    try? JSONEncoder().encode(fix).write(to: url)
    session.transferFile(url, metadata: ["type": "location"])
}
```

**Characteristics**:
- Queued for offline periods
- Automatic retry on failure
- Background delivery when reachable
- Guaranteed delivery (eventually)

### GPS Configuration (Apple Watch)

```swift
// HealthKit workout session for extended GPS runtime
let configuration = HKWorkoutConfiguration()
configuration.activityType = .other // Most frequent updates
configuration.locationType = .outdoor

locationManager.desiredAccuracy = kCLLocationAccuracyBest
locationManager.distanceFilter = kCLDistanceFilterNone // No throttling
locationManager.allowsBackgroundLocationUpdates = true
```

**Result**: ~1Hz GPS updates with 8-10 hour battery life

---

## Development Workflow

### 1. Feature Development (TDD Approach)

```bash
# Step 1: Create failing test
swift test --filter TestName

# Step 2: Implement feature to pass test
# (Edit source files)

# Step 3: Verify all tests pass
swift test

# Step 4: Run quality checks
swift-format lint --recursive Sources/
```

**Use `/add-feature` command** for scaffolding new features with tests.

### 2. Bug Fixes (Regression Testing)

```bash
# Step 1: Write test that reproduces bug
# Step 2: Fix bug
# Step 3: Verify test passes
# Step 4: Add to regression test suite
```

**Use `/fix-bug` command** for TDD bug fix workflow.

### 3. Build and Run

**Note**: Xcode 26.1 has a critical watchapp2 bug (error 143) requiring separate installation.

```bash
# Build iOS app for simulator
xcodebuild -workspace pawWatch.xcworkspace \
  -scheme pawWatch \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Build Watch app for physical device (workaround)
xcodebuild -workspace pawWatch.xcworkspace \
  -scheme "pawWatch Watch App" \
  -destination 'platform=watchOS,id=WATCH_UUID' \
  build

# Install separately (not App Store compatible until Xcode fix)
xcrun simctl install booted pawWatch.app
xcrun devicectl device install app --device WATCH_UUID pawWatch\ Watch\ App.app
```

---

## Anti-Patterns (NEVER DO THIS)

### ❌ Placeholders

```swift
// BAD: Never ship placeholder code
func calculateDistance() -> Double {
    // TODO: Implement distance calculation
    return 0.0
}

// GOOD: Complete implementation or use guard
func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
    guard from.coordinate.isValid, to.coordinate.isValid else {
        return 0.0
    }
    return from.distance(from: to)
}
```

### ❌ Force Unwrapping

```swift
// BAD: Crashes on nil
let distance = petLocation!.distance(from: ownerLocation!)

// GOOD: Guard statement with early return
guard let pet = petLocation,
      let owner = ownerLocation else {
    return nil
}
let distance = pet.distance(from: owner)
```

### ❌ ViewModels in SwiftUI

```swift
// BAD: Unnecessary ViewModel layer
class LocationViewModel: ObservableObject {
    @Published var location: LocationFix?
}

// GOOD: @Observable model directly
@Observable
class PetLocationManager {
    var latestLocation: LocationFix?
}
```

### ❌ Task in onAppear

```swift
// BAD: Task doesn't cancel when view disappears
.onAppear {
    Task {
        await startTracking()
    }
}

// GOOD: .task modifier auto-cancels
.task {
    await startTracking()
}
```

### ❌ GCD (Grand Central Dispatch)

```swift
// BAD: Old concurrency model
DispatchQueue.main.async {
    updateUI()
}

// GOOD: Swift Concurrency
@MainActor
func updateUI() {
    // Automatically on main thread
}
```

---

## Success Metrics

### Code Quality Gates

- ✅ **Test Coverage**: >90% for business logic, >80% for UI
- ✅ **No Placeholders**: Zero TODO/FIXME in production code
- ✅ **No Force Unwraps**: Zero `!` operators (except IUO properties)
- ✅ **Strict Concurrency**: All Sendable violations resolved
- ✅ **No Retain Cycles**: Memory graph analysis clean
- ✅ **SwiftLint**: Zero warnings on `--strict` mode

### Performance Targets

- 📍 GPS update latency: <500ms (application context)
- 📍 Interactive message latency: <100ms (when reachable)
- 🔋 Watch battery life: >8 hours continuous GPS
- 📶 Distance accuracy: ±10 meters horizontal

### Architecture Compliance

- 🏗️ Zero circular dependencies between modules
- 🏗️ Domain layer has zero framework imports
- 🏗️ All platform code isolated to Infrastructure layer
- 🏗️ Views contain zero business logic

---

## Common Commands

### Development

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter pawWatchFeatureTests

# Run tests with coverage
swift test --enable-code-coverage

# Build package
swift build

# Lint code
swift-format lint --recursive Sources/

# Format code
swift-format format --in-place --recursive Sources/
```

### Xcode

```bash
# Open workspace
open pawWatch.xcworkspace

# Build iOS app
xcodebuild -workspace pawWatch.xcworkspace -scheme pawWatch build

# Clean build
xcodebuild clean -workspace pawWatch.xcworkspace -scheme pawWatch
```

### Git

```bash
# Verify no uncommitted changes before testing
git status

# Commit with conventional commits
git commit -m "feat: add distance alerts"
git commit -m "fix: resolve WatchConnectivity timeout"
git commit -m "test: add LocationFix encoding tests"
```

---

## Swift Concurrency Rules

### @MainActor Isolation

```swift
// All UI updates MUST be @MainActor
@MainActor
class PetLocationManager: NSObject, ObservableObject {
    @Published var latestLocation: LocationFix?

    // WCSession delegate runs on background queue
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let fix = LocationFix.from(json: message) {
            Task { @MainActor in
                self.latestLocation = fix // Safe: @MainActor context
            }
        }
    }
}
```

### Sendable Conformance

```swift
// All types crossing concurrency boundaries MUST be Sendable
public struct LocationFix: Codable, Sendable {
    // Value type = automatic Sendable conformance
}

// Reference types need @unchecked Sendable (with caution)
class LocationManager: NSObject, @unchecked Sendable {
    private let queue = DispatchQueue(label: "location")
    // Thread-safe implementation required
}
```

### Task Lifecycle

```swift
// SwiftUI: Use .task for automatic cancellation
struct ContentView: View {
    @State private var manager = PetLocationManager()

    var body: some View {
        Map()
            .task {
                // Automatically cancelled when view disappears
                await manager.startReceivingLocations()
            }
    }
}
```

---

## Reference Implementation

This project adapts patterns from:

**GPS Relay Framework**: `/Users/zackjordan/code/jetson/dev/gps-relay-framework`

### Key Inherited Patterns

1. **WatchLocationProvider** - Triple-path WatchConnectivity messaging
2. **LocationFix** - Comprehensive GPS data model with JSON encoding
3. **Workout-driven GPS** - HealthKit workout for extended runtime
4. **@Observable pattern** - Modern reactive state management

### Key Differences

| Aspect | GPS Relay Framework | pawWatch |
|--------|---------------------|----------|
| **External relay** | WebSocket to server | None (on-device only) |
| **Data streams** | Remote + Base + Fused | Pet (Watch) + Owner (iPhone) |
| **Architecture** | 3 packages (Core, Watch, iOS) | 1 feature package |
| **Target versions** | Swift 6.0, iOS 18.0 | Swift 6.2, iOS 26.0 |

---

## Known Issues

### Xcode 26.1 Watchapp2 Bug (Error 143)

**Symptom**: iOS rejects Watch app installation with:
```
MIInstallerErrorDomain error 143:
"Extensionless WatchKit app has a WatchKit extension"
```

**Root Cause**: Xcode 26.1 generates both executable AND stub for watchapp2, confusing iOS installer

**Workaround** (Development Only):
1. Remove "Embed Watch Content" build phase from iOS target
2. Remove Watch target dependency from iOS target
3. Build and install iOS app separately
4. Build and install Watch app separately

**Limitation**: NOT App Store compatible (temporary until Apple fixes Xcode)

**Tracking**: See `docs/architecture/watchapp2-bug-workaround.md`

---

## Testing Strategy

### Swift Testing Framework

```swift
import Testing
@testable import pawWatchFeature

@Test("LocationFix encodes correctly")
func testLocationFixEncoding() async throws {
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

@Test("Distance calculation is accurate")
func testDistanceCalculation() async throws {
    let manager = PetLocationManager()

    // San Francisco coordinates
    let pet = LocationFix(/* ... */)

    // Test distance logic
    // (Use real CLLocation.distance(from:) in implementation)
}
```

### Coverage Targets

- **Models**: 100% (LocationFix serialization, equality)
- **Services**: 90% (PetLocationManager, WatchLocationProvider)
- **Views**: 70% (snapshot/preview testing)

---

## Resources

### Documentation

- `README.md` - Quick start and overview
- `CLAUDE.md` - This file (comprehensive guidelines)
- `PROJECT_CHECKLIST.md` - Quality gates and setup status
- `docs/architecture/` - Design decisions and diagrams
- `docs/api/` - API documentation (generated)

### Slash Commands

- `/verify-versions` - Web search current dependency versions
- `/add-feature` - Scaffold new feature with tests
- `/fix-bug` - TDD bug fix workflow

### External References

- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [HealthKit Workouts](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings)
- [CoreLocation Best Practices](https://developer.apple.com/documentation/corelocation)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

## Quick Reference

### Starting Development

```bash
# 1. Verify versions are current
/verify-versions

# 2. Open workspace
open pawWatch.xcworkspace

# 3. Run tests
swift test

# 4. Build and run on simulator
# (Use Xcode Run button or xcodebuild)
```

### Adding New Feature

```bash
# 1. Use scaffolding command
/add-feature

# 2. Follow TDD: Write test first
# 3. Implement feature
# 4. Verify all tests pass
# 5. Commit with conventional commit message
```

### Before Committing

```bash
# 1. Run all tests
swift test

# 2. Verify code formatting
swift-format lint --recursive Sources/

# 3. Check for placeholders
grep -r "TODO\|FIXME" Sources/

# 4. Verify strict concurrency
# (Build with strict concurrency checking enabled)
```

---

**Remember**: This is a production-quality project. Every file must be complete, tested, and follow SOLID principles. No placeholders. No shortcuts. Excellence is the standard.
