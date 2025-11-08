import Foundation
import CoreLocation
@testable import PetTrackerFeature

/// Mock Core Location manager for testing GPS functionality
///
/// Provides full control over location updates including:
/// - Authorization status simulation
/// - Location update injection
/// - Error injection
/// - Configuration capture
/// - Delegate callback triggering
///
/// ## Usage
/// ```swift
/// let mockManager = MockCLLocationManager()
/// mockManager.mockAuthorizationStatus = .authorizedAlways
///
/// // Simulate location update
/// let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
/// mockManager.simulateLocationUpdate([location])
///
/// // Verify configuration
/// #expect(mockManager.startUpdatingLocationCalled)
/// ```
@MainActor
public final class MockCLLocationManager: CLLocationManager, @unchecked Sendable {

    // MARK: - Captured Configuration

    /// Whether startUpdatingLocation was called
    public var startUpdatingLocationCalled = false

    /// Whether stopUpdatingLocation was called
    public var stopUpdatingLocationCalled = false

    /// Whether requestWhenInUseAuthorization was called
    public var requestWhenInUseAuthorizationCalled = false

    /// Whether requestAlwaysAuthorization was called
    public var requestAlwaysAuthorizationCalled = false

    /// Captured desired accuracy setting
    public var capturedDesiredAccuracy: CLLocationAccuracy?

    /// Captured distance filter setting
    public var capturedDistanceFilter: CLLocationDistance?

    /// Captured background updates setting
    public var capturedAllowsBackgroundLocationUpdates: Bool?

    /// Captured activity type setting
    public var capturedActivityType: CLActivityType?

    // MARK: - Controllable State

    /// Authorization status to return (default: .notDetermined)
    public var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Location to return (default: nil)
    public var mockLocation: CLLocation?

    /// Error to inject when simulating failures
    public var errorToInject: Error?

    /// Simulated delay before triggering location updates
    public var updateDelay: TimeInterval = 0

    // MARK: - CLLocationManager Overrides

    public override var authorizationStatus: CLAuthorizationStatus {
        return mockAuthorizationStatus
    }

    public override var location: CLLocation? {
        return mockLocation
    }

    public override var desiredAccuracy: CLLocationAccuracy {
        get { capturedDesiredAccuracy ?? kCLLocationAccuracyBest }
        set { capturedDesiredAccuracy = newValue }
    }

    public override var distanceFilter: CLLocationDistance {
        get { capturedDistanceFilter ?? kCLDistanceFilterNone }
        set { capturedDistanceFilter = newValue }
    }

    public override var allowsBackgroundLocationUpdates: Bool {
        get { capturedAllowsBackgroundLocationUpdates ?? false }
        set { capturedAllowsBackgroundLocationUpdates = newValue }
    }

    public override var activityType: CLActivityType {
        get { capturedActivityType ?? .other }
        set { capturedActivityType = newValue }
    }

    // MARK: - Location Updates

    public override func startUpdatingLocation() {
        startUpdatingLocationCalled = true

        // Simulate location update if delay configured
        if updateDelay > 0, let location = mockLocation {
            let delay = updateDelay
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                simulateLocationUpdate([location])
            }
        }
    }

    public override func stopUpdatingLocation() {
        stopUpdatingLocationCalled = true
    }

    // MARK: - Authorization

    nonisolated public override func requestWhenInUseAuthorization() {
        Task { @MainActor in
            requestWhenInUseAuthorizationCalled = true

            // Change status to authorized (platform-specific)
            #if os(macOS)
            mockAuthorizationStatus = .authorizedAlways
            #else
            mockAuthorizationStatus = .authorizedWhenInUse
            #endif
            delegate?.locationManagerDidChangeAuthorization?(self)
        }
    }

    nonisolated public override func requestAlwaysAuthorization() {
        Task { @MainActor in
            requestAlwaysAuthorizationCalled = true
            mockAuthorizationStatus = .authorizedAlways
            delegate?.locationManagerDidChangeAuthorization?(self)
        }
    }

    // MARK: - Test Helpers

    /// Simulates receiving location updates
    public func simulateLocationUpdate(_ locations: [CLLocation]) {
        delegate?.locationManager?(self, didUpdateLocations: locations)
    }

    /// Simulates location error
    public func simulateLocationError(_ error: Error) {
        delegate?.locationManager?(self, didFailWithError: error)
    }

    /// Simulates authorization change
    public func simulateAuthorizationChange(_ status: CLAuthorizationStatus) {
        mockAuthorizationStatus = status
        delegate?.locationManagerDidChangeAuthorization?(self)
    }

    /// Resets all captured state
    public func reset() {
        startUpdatingLocationCalled = false
        stopUpdatingLocationCalled = false
        requestWhenInUseAuthorizationCalled = false
        requestAlwaysAuthorizationCalled = false
        capturedDesiredAccuracy = nil
        capturedDistanceFilter = nil
        capturedAllowsBackgroundLocationUpdates = nil
        capturedActivityType = nil
        errorToInject = nil
        updateDelay = 0
        mockAuthorizationStatus = .notDetermined
        mockLocation = nil
    }
}

// MARK: - Mock Errors

public enum MockLocationError: Error, LocalizedError {
    case denied
    case locationUnknown
    case timeout

    public var errorDescription: String? {
        switch self {
        case .denied:
            return "Location permission denied"
        case .locationUnknown:
            return "Location unknown"
        case .timeout:
            return "Location request timeout"
        }
    }
}

// MARK: - Test Helpers

extension CLLocation {
    /// Creates a test location with sensible defaults
    public static func testLocation(
        latitude: CLLocationDegrees = 37.7749,
        longitude: CLLocationDegrees = -122.4194,
        altitude: CLLocationDistance = 10.0,
        horizontalAccuracy: CLLocationAccuracy = 5.0,
        verticalAccuracy: CLLocationAccuracy = 10.0,
        course: CLLocationDirection = -1,
        speed: CLLocationSpeed = 0,
        timestamp: Date = Date()
    ) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
    }
}
