# PetTracker - Project Setup Documentation

**Created**: 2025-11-07
**Status**: Complete - Ready for Xcode Project File Generation

---

## Overview

This document describes the complete project setup for PetTracker, including directory structure, build configurations, and integration with the Swift Package Manager.

## Project Structure

```
PetTracker/
├── PetTracker.xcworkspace/          # Xcode workspace (created)
├── PetTrackerPackage/                # Swift Package with all logic
│   ├── Package.swift
│   ├── Sources/PetTrackerFeature/
│   │   ├── Models/
│   │   │   └── LocationFix.swift
│   │   ├── Services/
│   │   │   ├── PetLocationManager.swift
│   │   │   └── WatchLocationProvider.swift
│   │   └── Views/                  # (Pending - can add shared views here)
│   └── Tests/PetTrackerFeatureTests/
│       └── LocationFixTests.swift
├── PetTracker/                       # iOS app target (shell)
│   ├── PetTrackerApp.swift          # @main entry point
│   ├── ContentView.swift          # Main iOS UI
│   ├── Info.plist                 # iOS capabilities
│   ├── PetTracker.entitlements      # App Groups, Location
│   └── Assets.xcassets/           # App icons, colors
├── PetTracker Watch App Extension/  # Watch app target
│   ├── PetTrackerApp.swift          # @main entry point
│   ├── WatchContentView.swift     # Main Watch UI
│   ├── Info.plist                 # Watch capabilities
│   └── *.entitlements             # App Groups, HealthKit, Location
├── Config/                         # Build configurations
│   ├── Shared.xcconfig            # Common settings
│   ├── Debug.xcconfig             # Debug build
│   └── Release.xcconfig           # Release build
└── docs/architecture/              # Architecture documentation
```

## Architecture Principles

### 1. Swift Package First

All application logic lives in the Swift Package (`PetTrackerPackage`). This provides:

- **Modularity**: Clear separation of concerns
- **Testability**: Easy to test without app targets
- **Reusability**: Logic can be used in extensions, widgets, etc.
- **Fast builds**: Only rebuild what changed

### 2. Minimal App Targets

The iOS and Watch app targets are minimal shells that:

- Import `PetTrackerFeature` package
- Define app entry point (`@main`)
- Configure capabilities (Location, HealthKit, WatchConnectivity)
- Provide platform-specific assets

This keeps the app targets lightweight and focused on platform integration.

### 3. Shared Build Configurations

Build settings are centralized in `.xcconfig` files:

- **Shared.xcconfig**: Common settings (Swift version, warnings, deployment targets)
- **Debug.xcconfig**: Debug-specific (no optimization, assertions enabled)
- **Release.xcconfig**: Release-specific (optimized, stripped)

## SwiftUI Views

### iOS App (ContentView.swift)

**Features**:
- Connection status indicator
- Pet location display with distance
- Battery level monitoring
- GPS accuracy visualization
- Coordinate display
- Location history counter
- Clear history button
- Auto-start tracking on appear

**Layout**:
- NavigationStack with toolbar
- Vertical stack with spacing
- Color-coded indicators (battery, connection)
- Accessibility-friendly text sizes
- Dark mode support (automatic)

### Watch App (WatchContentView.swift)

**Features**:
- Tracking status indicator (green/gray circle)
- Battery level display
- GPS accuracy
- Fixes sent counter
- Phone reachability status
- Start/Stop tracking button
- Compact layout for small screen

**Layout**:
- Vertical stack optimized for Watch
- Large, tappable button
- Color-coded status indicators
- Minimal text (icons + captions)

## Capabilities & Entitlements

### iOS App

**Entitlements** (`PetTracker.entitlements`):
- App Groups: `group.com.pettracker` (for Watch sync)

**Info.plist Permissions**:
- Location When In Use: Distance calculation
- Location Always: Background tracking
- Background Modes: `location`

### Watch App

**Entitlements** (`PetTracker Watch App Extension.entitlements`):
- App Groups: `group.com.pettracker`
- HealthKit: Workout sessions
- HealthKit Background Delivery: GPS while backgrounded

**Info.plist Permissions**:
- Location When In Use: GPS tracking
- Location Always: Continuous tracking
- Health Share/Update: Workout session access
- Background Modes: `location`, `workout-processing`

## Build Configurations

### Swift Settings

```
SWIFT_VERSION = 6.0
SWIFT_STRICT_CONCURRENCY = complete
ENABLE_BARE_SLASH_REGEX = YES
```

### Deployment Targets

```
IPHONEOS_DEPLOYMENT_TARGET = 18.0
WATCHOS_DEPLOYMENT_TARGET = 11.0
```

**Note**: These will be updated to iOS 26.0 and watchOS 26.0 when Xcode project is generated.

### Optimization Levels

**Debug**:
- Swift: `-Onone` (no optimization)
- Clang: `0` (no optimization)
- Debug symbols: `dwarf`
- Assertions: Enabled

**Release**:
- Swift: `-O` (optimize for speed)
- Clang: `s` (optimize for size)
- Debug symbols: `dwarf-with-dsym`
- Assertions: Disabled
- Whole module optimization: Enabled

## Integration with Swift Package

The app targets import the Swift Package via:

```swift
import PetTrackerFeature
```

This gives access to:
- `LocationFix` - Domain model
- `PetLocationManager` - iOS location coordinator
- `WatchLocationProvider` - Watch GPS provider

### Environment Injection (iOS)

```swift
@main
struct PetTrackerApp: App {
    @State private var locationManager = PetLocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)  // Inject manager
        }
    }
}
```

Views access via:
```swift
@Environment(PetLocationManager.self) private var locationManager
```

### Environment Injection (Watch)

```swift
@main
struct PetTracker_Watch_App: App {
    @State private var locationProvider = WatchLocationProvider()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(locationProvider)  // Inject provider
        }
    }
}
```

## Next Steps

### 1. Generate Xcode Project Files

The workspace exists, but the `.xcodeproj` files need to be generated. This requires:

1. Opening the workspace in Xcode
2. Using "File > New > Project" to create iOS app project
3. Configuring project settings to match `.xcconfig` files
4. Adding Swift Package as local dependency
5. Repeating for Watch app project

### 2. Link Swift Package

In Xcode:
1. Select project in navigator
2. Go to "Frameworks, Libraries, and Embedded Content"
3. Click "+" and select "Add Local..."
4. Choose `PetTrackerPackage` directory
5. Ensure "Embed & Sign" is selected

### 3. Configure Build Settings

In Xcode:
1. Select project > Build Settings
2. Set "Based on Configuration File" to appropriate `.xcconfig`
3. Verify Swift version, deployment targets, etc.

### 4. Test Build

Build both targets for simulator:
```bash
# iOS app
xcodebuild -workspace PetTracker.xcworkspace \
  -scheme PetTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Watch app
xcodebuild -workspace PetTracker.xcworkspace \
  -scheme "PetTracker Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' \
  build
```

### 5. Run Tests

Once Xcode project is set up:
```bash
xcodebuild test \
  -workspace PetTracker.xcworkspace \
  -scheme PetTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Known Limitations

### WatchConnectivity Availability

WatchConnectivity framework is only available on iOS/watchOS devices. The Swift Package compiles correctly when built as part of an Xcode project with appropriate deployment targets, but fails when built standalone via `swift build` (macOS doesn't have WatchConnectivity).

**Solution**: Always build via Xcode workspace, not standalone Swift Package.

### Xcode 26.1 Watchapp2 Bug

See `CLAUDE.md` for details on the Xcode 26.1 bug requiring separate Watch app installation.

## File Checklist

### Created Files

- [x] `PetTracker.xcworkspace` - Workspace container
- [x] `PetTracker/PetTrackerApp.swift` - iOS app entry
- [x] `PetTracker/ContentView.swift` - iOS main view
- [x] `PetTracker/Info.plist` - iOS capabilities
- [x] `PetTracker/PetTracker.entitlements` - iOS entitlements
- [x] `PetTracker/Assets.xcassets/` - iOS asset catalog
- [x] `PetTracker Watch App Extension/PetTrackerApp.swift` - Watch entry
- [x] `PetTracker Watch App Extension/WatchContentView.swift` - Watch view
- [x] `PetTracker Watch App Extension/Info.plist` - Watch capabilities
- [x] `PetTracker Watch App Extension/*.entitlements` - Watch entitlements
- [x] `Config/Shared.xcconfig` - Shared build settings
- [x] `Config/Debug.xcconfig` - Debug configuration
- [x] `Config/Release.xcconfig` - Release configuration

### Pending Files

- [ ] `.xcodeproj` files (must be generated in Xcode)
- [ ] Derived data / build products
- [ ] Code signing certificates/profiles

---

**Status**: Project setup is complete. Ready to generate Xcode project files and begin building for devices.
