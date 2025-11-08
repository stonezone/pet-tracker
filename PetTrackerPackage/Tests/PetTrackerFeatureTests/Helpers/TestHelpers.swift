import Foundation
import CoreLocation
import Testing
@testable import PetTrackerFeature

// MARK: - Test Data Factory

/// Factory for creating test data with sensible defaults
public enum TestDataFactory {

    // MARK: - LocationFix Factory

    /// Creates a test LocationFix with sensible defaults
    public static func createLocationFix(
        timestamp: Date = Date(),
        source: LocationFix.Source = .watchOS,
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        altitude: Double? = 10.0,
        horizontalAccuracy: Double = 5.0,
        verticalAccuracy: Double = 10.0,
        speed: Double = 0.5,
        course: Double = 180.0,
        heading: Double? = nil,
        batteryLevel: Double = 0.85,
        sequence: Int = 1
    ) -> LocationFix {
        return LocationFix(
            timestamp: timestamp,
            source: source,
            coordinate: LocationFix.Coordinate(latitude: latitude, longitude: longitude),
            altitudeMeters: altitude,
            horizontalAccuracyMeters: horizontalAccuracy,
            verticalAccuracyMeters: verticalAccuracy,
            speedMetersPerSecond: speed,
            courseDegrees: course,
            headingDegrees: heading,
            batteryFraction: batteryLevel,
            sequence: sequence
        )
    }

    /// Creates a sequence of LocationFix objects for trail testing
    public static func createLocationTrail(
        count: Int,
        startLatitude: Double = 37.7749,
        startLongitude: Double = -122.4194,
        latitudeStep: Double = 0.001,
        longitudeStep: Double = 0.001,
        startSequence: Int = 1
    ) -> [LocationFix] {
        var trail: [LocationFix] = []
        for index in 0..<count {
            let fix = createLocationFix(
                latitude: startLatitude + (Double(index) * latitudeStep),
                longitude: startLongitude + (Double(index) * longitudeStep),
                sequence: startSequence + index
            )
            trail.append(fix)
        }
        return trail
    }

    // MARK: - CLLocation Factory

    /// Creates a test CLLocation with sensible defaults
    public static func createCLLocation(
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        altitude: Double = 10.0,
        horizontalAccuracy: Double = 5.0,
        verticalAccuracy: Double = 10.0,
        course: Double = -1,
        speed: Double = 0,
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

// MARK: - Assertion Helpers

/// Custom assertions for location-related tests
public enum LocationAssertions {

    /// Asserts that two coordinates are approximately equal within tolerance
    public static func assertCoordinatesEqual(
        _ actual: (latitude: Double, longitude: Double),
        _ expected: (latitude: Double, longitude: Double),
        tolerance: Double = 0.000001,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            abs(actual.latitude - expected.latitude) < tolerance,
            "Latitude mismatch: \(actual.latitude) vs \(expected.latitude)",
            sourceLocation: sourceLocation
        )
        #expect(
            abs(actual.longitude - expected.longitude) < tolerance,
            "Longitude mismatch: \(actual.longitude) vs \(expected.longitude)",
            sourceLocation: sourceLocation
        )
    }

    /// Asserts that a distance is within expected range
    public static func assertDistanceWithin(
        _ distance: Double,
        expected: Double,
        tolerance: Double = 1.0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            abs(distance - expected) <= tolerance,
            "Distance \(distance)m not within \(tolerance)m of expected \(expected)m",
            sourceLocation: sourceLocation
        )
    }

    /// Asserts that a LocationFix has valid GPS data
    public static func assertValidLocationFix(
        _ fix: LocationFix,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        // Latitude must be in valid range
        #expect(
            fix.coordinate.latitude >= -90 && fix.coordinate.latitude <= 90,
            "Invalid latitude: \(fix.coordinate.latitude)",
            sourceLocation: sourceLocation
        )

        // Longitude must be in valid range
        #expect(
            fix.coordinate.longitude >= -180 && fix.coordinate.longitude <= 180,
            "Invalid longitude: \(fix.coordinate.longitude)",
            sourceLocation: sourceLocation
        )

        // Horizontal accuracy must be positive
        #expect(
            fix.horizontalAccuracyMeters >= 0,
            "Invalid horizontal accuracy: \(fix.horizontalAccuracyMeters)",
            sourceLocation: sourceLocation
        )

        // Battery level must be in valid range
        #expect(
            fix.batteryFraction >= 0 && fix.batteryFraction <= 1,
            "Invalid battery level: \(fix.batteryFraction)",
            sourceLocation: sourceLocation
        )
    }
}

// MARK: - Async Test Helpers

/// Helpers for async testing patterns
public enum AsyncTestHelpers {

    /// Waits for a condition to be true within timeout
    @MainActor
    public static func waitForCondition(
        timeout: TimeInterval = 1.0,
        pollingInterval: TimeInterval = 0.1,
        condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition() {
            guard Date() < deadline else {
                throw TimeoutError.conditionNotMet
            }

            try await Task.sleep(for: .seconds(pollingInterval))
        }
    }

    /// Waits for a value to change
    @MainActor
    public static func waitForChange<T: Equatable>(
        timeout: TimeInterval = 1.0,
        pollingInterval: TimeInterval = 0.1,
        getValue: () -> T
    ) async throws -> T {
        let initialValue = getValue()
        let deadline = Date().addingTimeInterval(timeout)

        while getValue() == initialValue {
            guard Date() < deadline else {
                throw TimeoutError.valueDidNotChange
            }

            try await Task.sleep(for: .seconds(pollingInterval))
        }

        return getValue()
    }

    /// Collects all values emitted during a time period
    @MainActor
    public static func collectValues<T>(
        duration: TimeInterval = 1.0,
        getValue: () -> T?
    ) async -> [T] {
        var values: [T] = []
        let deadline = Date().addingTimeInterval(duration)

        while Date() < deadline {
            if let value = getValue() {
                values.append(value)
            }

            try? await Task.sleep(for: .seconds(0.1))
        }

        return values
    }
}

// MARK: - Mock Test Errors

public enum TimeoutError: Error, LocalizedError {
    case conditionNotMet
    case valueDidNotChange

    public var errorDescription: String? {
        switch self {
        case .conditionNotMet:
            return "Test timeout: condition not met"
        case .valueDidNotChange:
            return "Test timeout: value did not change"
        }
    }
}

// MARK: - JSON Test Helpers

/// Helpers for JSON encoding/decoding tests
public enum JSONTestHelpers {

    /// Encodes and decodes a value, verifying round-trip equality
    public static func verifyRoundTrip<T: Codable & Equatable>(
        _ value: T
    ) throws -> T {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(value)
        let decoded = try decoder.decode(T.self, from: encoded)

        return decoded
    }

    /// Converts Codable to [String: Any] dictionary
    public static func toDictionary<T: Encodable>(
        _ value: T
    ) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return dict ?? [:]
    }

    /// Converts [String: Any] dictionary to Codable
    public static func fromDictionary<T: Decodable>(
        _ dict: [String: Any],
        type: T.Type
    ) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
