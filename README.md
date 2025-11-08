# PetTracker - Pet GPS Tracker

Transform your Apple Watch into a real-time GPS tracker for your pet. Simply attach the Watch to your pet's collar and monitor their location live on your iPhone.

**Status**: 🚧 Initial Setup Complete - Xcode Project Creation Pending
**Version**: 0.1.0-dev
**Last Updated**: 2025-11-07

---

## Overview

**PetTracker** is a native iOS/watchOS companion app that provides real-time pet location tracking without cloud services or subscriptions. All processing happens on-device for maximum privacy and reliability.

### Key Features

- 📍 **Real-Time GPS Tracking** - Monitor pet location with ~1Hz update rate
- 📏 **Distance Monitoring** - Calculate distance from owner to pet in real-time
- 🔋 **Battery Monitoring** - Track Apple Watch battery level remotely
- 🗺️ **Location History** - Visualize historical trails (last 100 GPS fixes)
- 🔒 **Privacy First** - All data stays on your devices (no cloud required)
- ⚡ **Triple-Path Messaging** - Reliable data delivery via WatchConnectivity

### How It Works

```
┌─────────────────┐           ┌─────────────────┐
│  Apple Watch    │  Bluetooth │   iPhone        │
│  (on pet)       │ ◄────────► │  (owner)        │
│                 │            │                 │
│  GPS Capture    │   ~1Hz     │  Live Display   │
│  Battery Monitor│   Update   │  Distance Calc  │
│  HealthKit Run  │            │  Trail Map      │
└─────────────────┘            └─────────────────┘
```

1. Apple Watch (attached to pet collar) captures GPS coordinates
2. Location data transmitted to iPhone via WatchConnectivity
3. iPhone displays real-time location, distance, battery, and trail

---

## Quick Start

### Prerequisites

- **Xcode 26.1+** (macOS)
- **iOS 26.0+** device (iPhone)
- **watchOS 26.0+** device (Apple Watch)
- **Swift 6.2+**
- **Apple Developer Account** (for device deployment)

### Build and Run

> **Note**: Xcode project creation is pending. This section will be updated once the workspace is set up.

```bash
# 1. Clone repository
git clone <repository-url>
cd pet-tracker

# 2. Open workspace
open PetTracker.xcworkspace

# 3. Run tests (Swift package)
swift test

# 4. Build for simulator (iOS)
# Select PetTracker scheme and iPhone 16 simulator in Xcode, then press Run

# 5. Build for physical devices
# See docs/architecture/watchapp2-bug-workaround.md for Xcode 26.1 installation workaround
```

### Known Issue: Xcode 26.1 Watchapp2 Bug

Xcode 26.1 has a critical bug that prevents normal Watch app installation. A workaround requires separate installation of iOS and Watch apps. See [watchapp2 Bug Workaround](docs/architecture/watchapp2-bug-workaround.md) (pending creation).

---

## Architecture

PetTracker follows **Clean Architecture** principles with clear separation of concerns:

### Module Structure

```
PetTracker/
├── PetTrackerPackage/              # Swift Package (all logic)
│   ├── Sources/PetTrackerFeature/
│   │   ├── Models/               # Domain layer
│   │   │   └── LocationFix.swift # GPS data model
│   │   ├── Services/             # Application layer
│   │   │   ├── PetLocationManager.swift     (iOS)
│   │   │   └── WatchLocationProvider.swift  (watchOS)
│   │   └── Views/                # Presentation layer
│   │       └── (SwiftUI views - pending)
│   └── Tests/PetTrackerFeatureTests/
│       └── LocationFixTests.swift
├── PetTracker/                      # iOS app shell
├── PetTracker Watch App Extension/  # Watch app shell
└── Config/                        # Build configurations
```

### Core Technologies

- **SwiftUI** - Declarative UI for both platforms
- **CoreLocation** - GPS capture on iPhone and Watch
- **WatchConnectivity** - Device-to-device communication
- **HealthKit** - Workout sessions for extended Watch GPS runtime
- **@Observable** - Modern reactive state management

### Triple-Path WatchConnectivity

Uses three complementary delivery mechanisms for reliable transmission:

1. **Application Context** - Background, latest-only (~2Hz max, 0.5s throttle)
2. **Interactive Messages** - Foreground, immediate (<100ms latency)
3. **File Transfer** - Background, guaranteed delivery with retry

---

## Development

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter LocationFixTests

# Run with coverage
swift test --enable-code-coverage
```

### Code Quality Standards

This project maintains high quality standards:

- ✅ **Test Coverage**: >90% for models, >80% for services
- ✅ **No Placeholders**: Zero TODO/FIXME in production code
- ✅ **Strict Concurrency**: Swift 6.2 strict mode enabled
- ✅ **Clean Architecture**: Clear layer boundaries
- ✅ **No Force Unwraps**: Guard statements only

### Slash Commands

Custom development workflows:

```bash
# Verify all technology versions are current
/verify-versions

# Scaffold new feature with TDD workflow
/add-feature

# Fix bug with regression testing
/fix-bug
```

### Git Workflow

Conventional commits:

```bash
git commit -m "feat: add distance alerts"
git commit -m "fix: resolve WatchConnectivity timeout"
git commit -m "test: add PetLocationManager tests"
```

---

## Documentation

### Project Docs

- [`CLAUDE.md`](CLAUDE.md) - Comprehensive development guidelines
- [`PROJECT_CHECKLIST.md`](PROJECT_CHECKLIST.md) - Quality gates and setup status
- [`pet-tracker.md`](pet-tracker.md) - Original specification
- [`docs/architecture/`](docs/architecture/) - Architecture decisions (pending)

### External Resources

- [WatchConnectivity Framework](https://developer.apple.com/documentation/watchconnectivity)
- [HealthKit Workouts](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings)
- [CoreLocation Best Practices](https://developer.apple.com/documentation/corelocation)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

## Project Status

### ✅ Completed

- [x] Project structure and architecture
- [x] Swift Package with PetTrackerFeature module
- [x] LocationFix domain model (fully tested)
- [x] PetLocationManager (@Observable iOS coordinator)
- [x] WatchLocationProvider (triple-path Watch GPS)
- [x] Comprehensive test suite for LocationFix
- [x] Documentation and development guidelines
- [x] Git repository initialization

### 🔄 In Progress

- [ ] Xcode workspace and project setup
- [ ] Build configurations (Debug/Release)
- [ ] SwiftUI views for iOS and Watch
- [ ] Integration tests for services
- [ ] Physical device testing

### 📋 Planned Features

- [ ] Map view with pet location marker
- [ ] Historical trail visualization
- [ ] Distance alerts (notifications)
- [ ] Battery alerts
- [ ] Location export (GPX format)
- [ ] Multi-pet support

---

## Technical Details

### Performance Characteristics

| Metric | Target | Notes |
|--------|--------|-------|
| GPS Update Rate | ~1Hz | Native Apple Watch GPS |
| Transmission Rate | ~2Hz max | Application context (throttled) |
| Interactive Latency | <100ms | When devices reachable |
| Battery Life (Watch) | >8 hours | Continuous GPS with HealthKit |
| Distance Accuracy | ±10m | kCLLocationAccuracyBest |

### Data Efficiency

- **LocationFix JSON Size**: ~200-300 bytes per fix
- **100-fix History Buffer**: ~20-30KB total
- **Compact Field Names**: Minimizes WatchConnectivity payload

---

## Reference Implementation

This project adapts patterns from the **GPS Relay Framework**:

📁 `/Users/zackjordan/code/jetson/dev/gps-relay-framework`

### Inherited Patterns

- Triple-path WatchConnectivity messaging
- LocationFix data model with compact JSON encoding
- HealthKit workout-driven GPS capture
- @Observable reactive state management

### Key Differences

| Aspect | GPS Relay | PetTracker |
|--------|-----------|----------|
| External relay | WebSocket server | None (on-device only) |
| Data streams | Remote + Base + Fused | Pet + Owner |
| Architecture | 3 packages | 1 feature package |
| Swift version | 6.0 | 6.2.1 |
| iOS version | 18.0+ | 26.0+ |

---

## License

[To be determined]

---

## Contact

[To be determined]

---

**Built with ❤️ using Swift 6.2, SwiftUI, and Clean Architecture**
