# PetTracker Test Infrastructure

**Created**: 2025-11-07
**Status**: Ready for use
**Swift Version**: 6.2
**Testing Framework**: Swift Testing (native)

---

## Overview

This directory contains the complete test infrastructure for PetTracker, including mocks, test helpers, and example tests demonstrating best practices.

## Directory Structure

```
Tests/PetTrackerFeatureTests/
├── README.md                      # This file
├── LocationFixTests.swift         # LocationFix model tests (19 tests)
├── ExampleServiceTests.swift      # Reference implementation examples
├── Mocks/
│   ├── MockWCSession.swift        # WatchConnectivity mock (iOS/watchOS)
│   ├── MockCLLocationManager.swift # Core Location mock
│   └── MockHKHealthStore.swift    # HealthKit mock (iOS/watchOS)
└── Helpers/
    └── TestHelpers.swift          # Test data factories and utilities
```

## Running Tests

### All Tests

```bash
cd PetTrackerPackage
swift test
```

### Specific Test Suite

```bash
swift test --filter "LocationFix Tests"
swift test --filter "Example Service Tests"
```

### Specific Test

```bash
swift test --filter testLocationFixEncoding
```

### With Coverage

```bash
swift test --enable-code-coverage
```

---

## Mock Classes

### 1. MockWCSession

**File**: `Mocks/MockWCSession.swift`
**Platforms**: iOS, watchOS
**Purpose**: Mock WatchConnectivity session for testing triple-path messaging

#### Features

- Captures all sent messages (application context, interactive messages, file transfers)
- Controllable activation state and reachability
- Error injection for testing failure scenarios
- Delegate callback simulation
- Platform-aware (iOS/watchOS only)

#### Example Usage

```swift
@MainActor
func testWatchConnectivity() async throws {
    // ARRANGE: Create mock with desired state
    let mockSession = MockWCSession()
    mockSession.mockActivationState = .activated
    mockSession.mockIsReachable = true

    // ACT: Send message through session
    let testMessage = ["key": "value"]
    mockSession.sendMessage(testMessage, replyHandler: nil, errorHandler: nil)

    // ASSERT: Verify message was captured
    #expect(mockSession.capturedMessages.count == 1)
    #expect(mockSession.capturedMessages[0]["key"] as? String == "value")

    // CLEANUP: Reset for next test
    mockSession.reset()
}
```

#### Key Properties

- `capturedContextUpdates`: All application context updates
- `capturedMessages`: All interactive messages
- `capturedFileTransfers`: All file transfers
- `mockActivationState`: Control session state
- `mockIsReachable`: Control reachability
- `errorToInject`: Inject errors for failure testing

---

### 2. MockCLLocationManager

**File**: `Mocks/MockCLLocationManager.swift`
**Platforms**: All (macOS compatible)
**Purpose**: Mock Core Location manager for GPS testing

#### Features

- Captures all configuration settings
- Controllable authorization status
- Simulates location updates and errors
- Platform-aware authorization (macOS uses .authorizedAlways)
- Records method calls for verification

#### Example Usage

```swift
@MainActor
func testLocationTracking() async throws {
    // ARRANGE: Create mock with authorized status
    let mockManager = MockCLLocationManager()
    mockManager.mockAuthorizationStatus = .authorizedAlways

    // ACT: Configure and start location updates
    mockManager.desiredAccuracy = kCLLocationAccuracyBest
    mockManager.startUpdatingLocation()

    // Simulate receiving location
    let testLocation = CLLocation.testLocation(
        latitude: 37.7749,
        longitude: -122.4194
    )
    mockManager.simulateLocationUpdate([testLocation])

    // ASSERT: Verify configuration captured
    #expect(mockManager.startUpdatingLocationCalled)
    #expect(mockManager.capturedDesiredAccuracy == kCLLocationAccuracyBest)
}
```

#### Key Properties

- `startUpdatingLocationCalled`: Track location updates started
- `mockAuthorizationStatus`: Control auth state
- `mockLocation`: Set current location
- `capturedDesiredAccuracy`: Verify accuracy settings
- `errorToInject`: Simulate location errors

---

### 3. MockHKHealthStore

**File**: `Mocks/MockHKHealthStore.swift`
**Platforms**: iOS, watchOS
**Purpose**: Mock HealthKit store for workout session testing

#### Features

- Authorization simulation
- Workout session creation tracking
- Data collection verification
- Error injection for failure scenarios
- Includes MockHKWorkoutSession and MockHKLiveWorkoutBuilder

#### Example Usage

```swift
@MainActor
func testWorkoutSession() async throws {
    // ARRANGE: Create mock with authorization
    let mockStore = MockHKHealthStore()
    mockStore.shouldAuthorize = true

    // ACT: Request authorization
    try await mockStore.requestAuthorization(
        toShare: [HKObjectType.workoutType()],
        read: []
    )

    // Create mock workout session
    let session = mockStore.createMockWorkoutSession(
        activityType: .other,
        locationType: .outdoor
    )

    // ASSERT: Verify authorization requested
    #expect(mockStore.authorizationRequestCount == 1)
    #expect(mockStore.capturedTypesToShare.contains(.workoutType()))
}
```

#### Key Properties

- `authorizationRequestCount`: Track auth requests
- `shouldAuthorize`: Control auth success/failure
- `capturedTypesToShare`: Verify requested permissions
- `authorizationError`: Inject auth errors

---

## Test Helpers

### TestDataFactory

**File**: `Helpers/TestHelpers.swift`
**Purpose**: Factory for creating consistent test data

#### Factory Methods

##### createLocationFix()

Creates a LocationFix with sensible defaults:

```swift
let fix = TestDataFactory.createLocationFix(
    latitude: 37.7749,
    longitude: -122.4194,
    sequence: 42
)
```

**Parameters** (all optional):
- `timestamp`: Date (default: now)
- `source`: .watchOS or .iOS (default: .watchOS)
- `latitude`: Double (default: San Francisco)
- `longitude`: Double (default: San Francisco)
- `altitude`: Double? (default: 10.0m)
- `horizontalAccuracy`: Double (default: 5.0m)
- `verticalAccuracy`: Double (default: 10.0m)
- `speed`: Double (default: 0.5 m/s)
- `course`: Double (default: 180°)
- `heading`: Double? (default: nil)
- `batteryLevel`: Double (default: 0.85)
- `sequence`: Int (default: 1)

##### createLocationTrail()

Creates a sequence of locations forming a path:

```swift
let trail = TestDataFactory.createLocationTrail(
    count: 10,
    startLatitude: 37.7749,
    startLongitude: -122.4194,
    latitudeStep: 0.001,
    longitudeStep: 0.001
)
// Returns [LocationFix] with sequence numbers 1-10
```

##### createCLLocation()

Creates a test CLLocation:

```swift
let location = TestDataFactory.createCLLocation(
    latitude: 37.7749,
    longitude: -122.4194,
    horizontalAccuracy: 5.0
)
```

---

### LocationAssertions

**File**: `Helpers/TestHelpers.swift`
**Purpose**: Custom assertions for GPS data

#### Assertion Methods

##### assertCoordinatesEqual()

Compares coordinates with tolerance:

```swift
LocationAssertions.assertCoordinatesEqual(
    actual: (latitude: 37.7749, longitude: -122.4194),
    expected: (latitude: 37.7749, longitude: -122.4194),
    tolerance: 0.000001
)
```

##### assertDistanceWithin()

Validates distance is within expected range:

```swift
LocationAssertions.assertDistanceWithin(
    distance,
    expected: 111_195, // ~1 degree latitude
    tolerance: 1000    // ±1km
)
```

##### assertValidLocationFix()

Validates all LocationFix fields are reasonable:

```swift
LocationAssertions.assertValidLocationFix(fix)
// Checks: latitude range, longitude range, accuracy > 0, battery 0-1
```

---

### AsyncTestHelpers

**File**: `Helpers/TestHelpers.swift`
**Purpose**: Utilities for async testing patterns

#### Helper Methods

##### waitForCondition()

Waits for a condition to become true:

```swift
@MainActor
try await AsyncTestHelpers.waitForCondition(timeout: 1.0) {
    manager.isReady
}
```

##### waitForChange()

Waits for a value to change:

```swift
@MainActor
let newValue = try await AsyncTestHelpers.waitForChange(
    timeout: 1.0,
    getValue: { manager.status }
)
```

##### collectValues()

Collects all values emitted during a period:

```swift
@MainActor
let values = await AsyncTestHelpers.collectValues(
    duration: 1.0,
    getValue: { manager.latestLocation }
)
```

---

### JSONTestHelpers

**File**: `Helpers/TestHelpers.swift`
**Purpose**: JSON encoding/decoding utilities

#### Helper Methods

##### verifyRoundTrip()

Encodes then decodes, verifying equality:

```swift
let original = TestDataFactory.createLocationFix()
let roundTripped = try JSONTestHelpers.verifyRoundTrip(original)
#expect(roundTripped == original)
```

##### toDictionary()

Converts Codable to [String: Any]:

```swift
let dict = try JSONTestHelpers.toDictionary(locationFix)
// Use for WatchConnectivity message simulation
```

##### fromDictionary()

Converts [String: Any] to Codable:

```swift
let fix = try JSONTestHelpers.fromDictionary(
    dict,
    type: LocationFix.self
)
```

---

## Test Patterns

### Test Structure (Arrange-Act-Assert)

Every test follows this pattern:

```swift
@Test("Description of behavior being tested")
@MainActor  // If testing UI components
func testSomething() async throws {
    // ARRANGE: Set up mocks and test data
    let mock = MockCLLocationManager()
    mock.mockAuthorizationStatus = .authorizedAlways

    // ACT: Execute the code under test
    let result = await performOperation(with: mock)

    // ASSERT: Verify expected behavior
    #expect(result.isSuccess)
    #expect(mock.startUpdatingLocationCalled)
}
```

### Testing Async Code

Use `.task` modifier for SwiftUI or `async`/`await` in tests:

```swift
@Test("Async operation completes")
@MainActor
func testAsyncOperation() async throws {
    let manager = PetLocationManager()

    // Start async operation
    await manager.startTracking()

    // Wait for condition
    try await AsyncTestHelpers.waitForCondition {
        manager.isTracking
    }

    #expect(manager.isTracking)
}
```

### Testing Error Cases

Inject errors via mocks:

```swift
@Test("Handles location error gracefully")
@MainActor
func testErrorHandling() async throws {
    let mock = MockCLLocationManager()
    mock.errorToInject = MockLocationError.timeout

    // Trigger error
    mock.simulateLocationError(MockLocationError.timeout)

    // Verify error handling
    #expect(manager.lastError != nil)
}
```

### Testing Concurrency

Use `@MainActor` for UI components:

```swift
@Test("UI updates on main actor")
@MainActor
func testMainActorIsolation() async throws {
    let manager = PetLocationManager()

    // This runs on main actor automatically
    manager.latestLocation = TestDataFactory.createLocationFix()

    #expect(manager.latestLocation != nil)
}
```

---

## Platform-Specific Tests

Some mocks are only available on iOS/watchOS due to framework limitations:

### Cross-Platform Tests (All)

- LocationFix model tests
- JSON encoding/decoding tests
- Distance calculations
- Data validation

### Platform-Specific Tests (iOS/watchOS)

- WatchConnectivity messaging (MockWCSession)
- HealthKit workouts (MockHKHealthStore)
- Watch-specific features

**Note**: Build the package on macOS for development, but run comprehensive tests on iOS/watchOS simulators or devices.

---

## Writing New Tests

### 1. Choose Test Location

- **Model tests**: Same file as model (`LocationFixTests.swift`)
- **Service tests**: New file per service (`PetLocationManagerTests.swift`)
- **Integration tests**: Separate suite (`IntegrationTests.swift`)

### 2. Import Dependencies

```swift
import Testing
import Foundation
import CoreLocation
@testable import PetTrackerFeature
```

### 3. Create Test Suite

```swift
@Suite("Service Name Tests")
struct ServiceTests {

    @Test("Describes expected behavior")
    @MainActor  // If needed
    func testSomething() async throws {
        // Test implementation
    }
}
```

### 4. Use Test Helpers

```swift
// Create test data
let fix = TestDataFactory.createLocationFix()

// Validate GPS data
LocationAssertions.assertValidLocationFix(fix)

// Wait for async conditions
try await AsyncTestHelpers.waitForCondition { isReady }
```

### 5. Use Mocks for Dependencies

```swift
let mockSession = MockWCSession()
mockSession.mockIsReachable = true

// Inject mock into service
let manager = PetLocationManager(session: mockSession)
```

---

## Test Coverage Goals

### Current Coverage

```bash
swift test --enable-code-coverage
# View coverage report
```

### Coverage Targets

- **Models**: 100% (LocationFix, domain logic)
- **Services**: 90% (PetLocationManager, WatchLocationProvider)
- **Views**: 70% (UI snapshot/preview testing)
- **Overall**: 85%+

---

## Troubleshooting

### Build Warnings

**Concurrency warnings** in mocks are expected due to CLLocationManager's nonisolated methods. The `@unchecked Sendable` conformance and proper `@MainActor` isolation ensure thread safety.

### Platform Issues

If tests fail on macOS due to missing frameworks:
- WatchConnectivity tests are skipped (iOS/watchOS only)
- HealthKit tests are skipped (iOS/watchOS only)
- Run full test suite on iOS simulator for complete coverage

### Test Timeout

If tests timeout:
- Check `AsyncTestHelpers.waitForCondition` timeout values
- Increase timeout for slower CI environments
- Verify async operations complete properly

---

## Best Practices

### DO

- ✅ Use TestDataFactory for consistent test data
- ✅ Follow Arrange-Act-Assert pattern
- ✅ Use descriptive test names (behavior, not implementation)
- ✅ Test edge cases and error scenarios
- ✅ Use `@MainActor` for UI-related tests
- ✅ Reset mocks between tests
- ✅ Verify both success and failure paths

### DON'T

- ❌ Test implementation details (test behavior)
- ❌ Use hardcoded delays (use AsyncTestHelpers)
- ❌ Share state between tests
- ❌ Test third-party framework behavior
- ❌ Ignore concurrency warnings
- ❌ Skip error case testing
- ❌ Write flaky tests (deterministic only)

---

## Next Steps

1. **Write Service Tests**: Create tests for PetLocationManager and WatchLocationProvider
2. **Integration Tests**: Test end-to-end location relay flow
3. **UI Tests**: Add snapshot tests for SwiftUI views
4. **Performance Tests**: Add benchmarks for critical paths
5. **Coverage Report**: Set up automated coverage tracking in CI

---

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [Swift Concurrency Testing](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Core Location Testing Guide](https://developer.apple.com/documentation/corelocation)
- [Project Testing Guidelines](../../../CLAUDE.md#testing-strategy)

---

**Test Infrastructure Status**: ✅ Complete and Ready

All mocks, helpers, and example tests are in place. Begin writing service tests using the patterns demonstrated in `ExampleServiceTests.swift`.
