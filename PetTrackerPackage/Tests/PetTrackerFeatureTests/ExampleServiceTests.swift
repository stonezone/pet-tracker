import Testing
import Foundation
import CoreLocation
@testable import PetTrackerFeature

/// Example test suite demonstrating testing patterns with mocks
///
/// This file serves as a reference for writing tests with:
/// - Mock dependency injection
/// - Async testing patterns
/// - Triple-path messaging verification
/// - Location data validation
/// - Test data factories
///
/// ## Test Structure
/// Each test follows the Arrange-Act-Assert pattern:
/// 1. **Arrange**: Set up mocks and test data
/// 2. **Act**: Execute the code under test
/// 3. **Assert**: Verify expected behavior
///
/// ## Running Tests
/// ```bash
/// swift test --filter ExampleServiceTests
/// ```
@Suite("Example Service Tests - Reference Implementation")
struct ExampleServiceTests {

    // MARK: - Mock-Based Testing Example

    // NOTE: Platform-specific mock tests (WCSession, HealthKit) are demonstrated
    // but will only compile on iOS/watchOS targets. For cross-platform tests,
    // focus on LocationFix model and data validation tests.

    // MARK: - Location Data Validation Example

    @Test("Example: Validate LocationFix has valid GPS coordinates")
    func testLocationFixValidation() async throws {
        // ARRANGE: Create location with valid data
        let validFix = TestDataFactory.createLocationFix(
            latitude: 37.7749,
            longitude: -122.4194
        )

        // ACT & ASSERT: Verify fix is valid
        LocationAssertions.assertValidLocationFix(validFix)

        // Additional specific assertions
        #expect(validFix.coordinate.latitude == 37.7749)
        #expect(validFix.coordinate.longitude == -122.4194)
        #expect(validFix.horizontalAccuracyMeters == 5.0)
        #expect(validFix.batteryFraction == 0.85)
    }

    // MARK: - JSON Round-Trip Testing Example

    @Test("Example: LocationFix survives JSON encoding/decoding")
    func testLocationFixJSONRoundTrip() async throws {
        // ARRANGE: Create test location
        let original = TestDataFactory.createLocationFix(
            latitude: 37.7749,
            longitude: -122.4194,
            sequence: 123
        )

        // ACT: Encode and decode
        let roundTripped = try JSONTestHelpers.verifyRoundTrip(original)

        // ASSERT: Values match
        #expect(roundTripped.coordinate.latitude == original.coordinate.latitude)
        #expect(roundTripped.coordinate.longitude == original.coordinate.longitude)
        #expect(roundTripped.sequence == original.sequence)
        #expect(roundTripped.source == original.source)
    }

    // MARK: - Mock CLLocationManager Example
    // Platform-specific tests for iOS/watchOS only - see dedicated test files

    // MARK: - Async Testing Example

    @Test("Example: Wait for async condition to be true")
    @MainActor
    func testAsyncConditionWaiting() async throws {
        // ARRANGE: Create flag that will change
        var conditionMet = false

        // Start async task that sets flag after delay
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            conditionMet = true
        }

        // ACT & ASSERT: Wait for condition
        try await AsyncTestHelpers.waitForCondition(timeout: 1.0) {
            conditionMet
        }

        #expect(conditionMet)
    }

    // MARK: - Distance Calculation Example

    @Test("Example: Calculate distance between two locations")
    func testDistanceCalculation() async throws {
        // ARRANGE: Create two locations ~111km apart (1 degree latitude)
        let location1 = TestDataFactory.createCLLocation(
            latitude: 37.0,
            longitude: -122.0
        )

        let location2 = TestDataFactory.createCLLocation(
            latitude: 38.0,
            longitude: -122.0
        )

        // ACT: Calculate distance
        let distance = location1.distance(from: location2)

        // ASSERT: Verify distance is approximately 111km (1 degree latitude)
        // Note: Actual distance is ~111,195 meters at this latitude
        LocationAssertions.assertDistanceWithin(
            distance,
            expected: 111_195,
            tolerance: 1000 // ±1km tolerance
        )
    }

    // MARK: - Location Trail Testing Example

    @Test("Example: Create and validate location trail")
    func testLocationTrailCreation() async throws {
        // ARRANGE: Create trail of 10 locations
        let trail = TestDataFactory.createLocationTrail(
            count: 10,
            startLatitude: 37.7749,
            startLongitude: -122.4194,
            latitudeStep: 0.001,
            longitudeStep: 0.001
        )

        // ACT & ASSERT: Verify trail properties
        #expect(trail.count == 10)
        #expect(trail.first?.sequence == 1)
        #expect(trail.last?.sequence == 10)

        // Verify each location is valid
        for fix in trail {
            LocationAssertions.assertValidLocationFix(fix)
        }

        // Verify locations form a diagonal path
        #expect(trail[0].coordinate.latitude == 37.7749)
        #expect(trail[9].coordinate.latitude == 37.7749 + (9 * 0.001))
    }

    // MARK: - Error Injection Example
    // Platform-specific mock error tests - see platform-specific test files
}

// MARK: - Test Suite Documentation

/*
 This example test file demonstrates all the testing patterns used in PetTracker:

 ## Mock Injection Pattern
 - Create mocks with controllable state
 - Inject mocks into services via initializer or property
 - Capture method calls and configurations
 - Simulate callbacks and delegate methods

 ## Test Data Factory Pattern
 - Use TestDataFactory for consistent test data
 - Create realistic GPS coordinates
 - Generate location trails for path testing
 - Build complex scenarios with minimal code

 ## Assertion Helpers
 - LocationAssertions for GPS-specific validations
 - Custom tolerance-based comparisons
 - Semantic assertions (assertValidLocationFix)
 - Clear error messages on failure

 ## Async Testing
 - Use async/await in test functions
 - AsyncTestHelpers for waiting on conditions
 - Task.sleep for simulating delays
 - Proper MainActor isolation

 ## JSON Testing
 - Round-trip encoding/decoding verification
 - Dictionary conversion helpers
 - Codable conformance validation
 - WatchConnectivity message format testing

 ## Test Organization
 - One test suite per service/model
 - Descriptive test names (behavior, not implementation)
 - ARRANGE-ACT-ASSERT comments
 - @MainActor where needed for UI components

 ## Running Tests
 ```bash
 # All tests
 swift test

 # Specific suite
 swift test --filter ExampleServiceTests

 # Specific test
 swift test --filter testLocationFixValidation

 # With coverage
 swift test --enable-code-coverage
 ```
 */
