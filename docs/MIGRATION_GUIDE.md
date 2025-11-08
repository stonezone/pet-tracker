# PetTracker Migration Guide

**Last Updated**: 2025-11-08

---

## Version History

### v0.1.0 (Current)

**Release Date**: 2025-11-08
**Status**: Initial Release

**Features**:
- Real-time GPS tracking (Watch → iPhone)
- Distance calculation (Pet ↔ Owner)
- Location history (last 100 fixes)
- Triple-path WatchConnectivity messaging
- Battery monitoring and adaptive throttling
- Error handling with user-friendly alerts
- Performance monitoring

**Requirements**:
- Swift 6.2.1+
- iOS 26.0+
- watchOS 26.0+
- Xcode 26.1+

**Breaking Changes**: None (initial release)

**Deprecations**: None

**Known Issues**:
- Xcode 26.1 watchapp2 bug (Error 143) requires separate installation workaround
  - See `docs/architecture/watchapp2-bug-workaround.md`

---

## Future Versions

### v0.2.0 (Planned)

**Expected Release**: TBD

**Planned Features**:
- Map view with real-time pet location
- Historical trail visualization
- GPX export functionality
- Distance alerts (notifications)
- Battery alerts
- Multi-pet support

**Planned Breaking Changes**: None currently planned

**Migration Effort**: Drop-in upgrade expected

---

## Migration Instructions

### From v0.1.0 to v0.2.0 (Future)

**Note**: This is a planned migration. Details will be updated when v0.2.0 is released.

**Expected Changes**:
- No breaking API changes expected
- New optional features available
- Backward compatible

**Steps**:
1. Update package dependency to v0.2.0
2. Review new features documentation
3. Optionally integrate new UI components
4. Test existing functionality

---

## Breaking Changes Log

### v0.1.0

No breaking changes (initial release).

---

## Deprecation Policy

PetTracker follows semantic versioning (SemVer):

- **Major versions** (x.0.0): Breaking changes allowed
- **Minor versions** (0.x.0): New features, no breaking changes
- **Patch versions** (0.0.x): Bug fixes only

**Deprecation Process**:
1. API marked as deprecated with `@available` annotation
2. Deprecation warning includes replacement API
3. Deprecated API maintained for at least one major version
4. Removal only in next major version

**Example**:
```swift
@available(*, deprecated, renamed: "newMethod")
public func oldMethod() {
    newMethod()
}
```

---

## API Stability

### Stable APIs (v0.1.0)

These APIs are stable and will not change in minor versions:

**Domain Layer**:
- ✅ `LocationFix` - Core GPS data model
- ✅ `LocationFix.Source` - Source device enum
- ✅ `LocationFix.Coordinate` - Geographic coordinate
- ✅ `UserFacingError` - User-friendly error mapping

**Application Layer**:
- ✅ `PetLocationManager` - iOS location coordinator
  - ✅ `latestPetLocation: LocationFix?`
  - ✅ `locationHistory: [LocationFix]`
  - ✅ `ownerLocation: CLLocation?`
  - ✅ `distanceFromOwner: Double?`
  - ✅ `startTracking() async`
  - ✅ `stopTracking()`
  - ✅ `clearHistory()`

- ✅ `WatchLocationProvider` - watchOS GPS provider
  - ✅ `isTracking: Bool`
  - ✅ `latestLocation: LocationFix?`
  - ✅ `batteryLevel: Double`
  - ✅ `startTracking() async`
  - ✅ `stopTracking() async`

**Presentation Layer**:
- ✅ `ErrorAlertModifier` - Error alert view modifier
- ✅ `ConnectionStatusView` - Connection status component

**Utilities**:
- ✅ `PerformanceMonitor` - Performance tracking
- ✅ `Logger` extensions - Structured logging

### Experimental APIs

No experimental APIs in v0.1.0.

---

## Compatibility Matrix

| PetTracker Version | Swift Version | iOS Version | watchOS Version | Xcode Version |
|--------------------|---------------|-------------|-----------------|---------------|
| 0.1.0              | 6.2.1+        | 26.0+       | 26.0+           | 26.1+         |

---

## Platform Support

### iOS

**Minimum**: iOS 26.0
**Tested**: iOS 26.0

**Required Frameworks**:
- SwiftUI
- CoreLocation
- WatchConnectivity
- UIKit (for settings URL)

### watchOS

**Minimum**: watchOS 26.0
**Tested**: watchOS 26.0

**Required Frameworks**:
- SwiftUI
- CoreLocation
- WatchConnectivity
- HealthKit
- WatchKit

---

## Data Migration

### Location History

**v0.1.0**: Location history stored in-memory only (not persisted)

**Future (v0.2.0+)**: May add persistence with Core Data or SwiftData

**Migration**: If persistence is added, no migration needed (no existing data to migrate).

---

## Testing Migration

### v0.1.0

**Test Framework**: Swift Testing (modern)

**Coverage Requirements**:
- Models: 100%
- Services: 90%
- Views: 70%

**Example**:
```swift
import Testing
@testable import PetTrackerFeature

@Test("LocationFix encoding")
func testLocationFixEncoding() async throws {
    let fix = LocationFix.sample()
    let encoded = try JSONEncoder().encode(fix)
    let decoded = try JSONDecoder().decode(LocationFix.self, from: encoded)
    #expect(decoded == fix)
}
```

---

## Configuration Migration

### v0.1.0

No configuration required. All defaults are optimal.

**Optional Customization**:
```swift
// Custom throttle interval (default: 0.5s)
private let contextThrottleInterval: TimeInterval = 1.0

// Custom history size (default: 100)
private let maxHistorySize = 200

// Custom distance filter (default: 10m for iOS, none for Watch)
locationManager.distanceFilter = 20
```

---

## Troubleshooting Migration Issues

### Common Issues

#### Build Errors After Update

**Solution**:
1. Clean build folder (⇧⌘K in Xcode)
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Close and reopen Xcode
4. Rebuild project

#### Runtime Crashes

**Solution**:
1. Check Swift version compatibility
2. Verify all entitlements are configured
3. Check Info.plist usage descriptions
4. Review error logs:
   ```bash
   log show --predicate 'subsystem == "com.pettracker"' --last 1h
   ```

#### Tests Failing

**Solution**:
1. Update test code to match new APIs
2. Check for deprecated API usage
3. Review breaking changes log
4. Run tests individually to isolate failures

---

## Getting Help

For migration assistance:

1. **Documentation**: Review updated API reference
2. **Examples**: Check `docs/examples/` for updated code samples
3. **Issues**: Report migration problems on GitHub
4. **Community**: Join discussions for migration questions

---

## Changelog Format

Future versions will follow this changelog format:

```markdown
## [Version] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes
```

---

**Last Updated**: 2025-11-08
**Maintained by**: PetTracker Development Team
