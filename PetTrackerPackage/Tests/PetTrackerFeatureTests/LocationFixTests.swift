import Testing
import Foundation
import CoreLocation
@testable import PetTrackerFeature

/// Comprehensive test suite for LocationFix data model
///
/// Tests cover:
/// - Initialization from CLLocation
/// - JSON encoding/decoding (Codable conformance)
/// - Equality comparison
/// - Convenience properties
/// - Edge cases (invalid data, missing optionals)
@Suite("LocationFix Tests")
struct LocationFixTests {

    // MARK: - Initialization Tests

    @Test("LocationFix initializes with all parameters")
    func testFullInitialization() async throws {
        let timestamp = Date()
        let fix = LocationFix(
            timestamp: timestamp,
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

        #expect(fix.timestamp == timestamp)
        #expect(fix.source == .watchOS)
        #expect(fix.coordinate.latitude == 37.7749)
        #expect(fix.coordinate.longitude == -122.4194)
        #expect(fix.altitudeMeters == 10.0)
        #expect(fix.horizontalAccuracyMeters == 5.0)
        #expect(fix.verticalAccuracyMeters == 10.0)
        #expect(fix.speedMetersPerSecond == 0.5)
        #expect(fix.courseDegrees == 180.0)
        #expect(fix.headingDegrees == nil)
        #expect(fix.batteryFraction == 0.85)
        #expect(fix.sequence == 12345)
    }

    @Test("LocationFix initializes from CLLocation")
    func testCLLocationInitialization() async throws {
        let clLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 10.0,
            course: 180.0,
            speed: 0.5,
            timestamp: Date()
        )

        let fix = LocationFix(
            from: clLocation,
            source: .watchOS,
            batteryLevel: 0.75,
            sequence: 1
        )

        #expect(fix.coordinate.latitude == 37.7749)
        #expect(fix.coordinate.longitude == -122.4194)
        #expect(fix.altitudeMeters == 10.0)
        #expect(fix.horizontalAccuracyMeters == 5.0)
        #expect(fix.verticalAccuracyMeters == 10.0)
        #expect(fix.speedMetersPerSecond == 0.5)
        #expect(fix.courseDegrees == 180.0)
        #expect(fix.batteryFraction == 0.75)
        #expect(fix.sequence == 1)
    }

    // MARK: - Encoding/Decoding Tests

    @Test("LocationFix encodes and decodes correctly")
    func testEncodingDecoding() async throws {
        let original = LocationFix(
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

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(LocationFix.self, from: encoded)

        #expect(decoded == original)
    }

    @Test("LocationFix encodes with compact field names")
    func testCompactFieldNames() async throws {
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

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(fix)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Verify compact field names are used
        #expect(jsonString.contains("ts_unix_ms"))
        #expect(jsonString.contains("h_accuracy_m"))
        #expect(jsonString.contains("battery_pct"))
        #expect(jsonString.contains("seq"))

        // Verify full names are NOT used
        #expect(!jsonString.contains("timestamp"))
        #expect(!jsonString.contains("horizontalAccuracyMeters"))
        #expect(!jsonString.contains("batteryFraction"))
        #expect(!jsonString.contains("sequence"))
    }

    @Test("LocationFix encodes timestamp as Unix milliseconds")
    func testTimestampEncoding() async throws {
        let timestamp = Date(timeIntervalSince1970: 1234567890.123)
        let fix = LocationFix(
            timestamp: timestamp,
            source: .watchOS,
            coordinate: .init(latitude: 37.7749, longitude: -122.4194),
            altitudeMeters: nil,
            horizontalAccuracyMeters: 5.0,
            verticalAccuracyMeters: 0.0,
            speedMetersPerSecond: 0.0,
            courseDegrees: 0.0,
            headingDegrees: nil,
            batteryFraction: 1.0,
            sequence: 1
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(fix)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        let tsMs = json["ts_unix_ms"] as! Double
        let expectedMs = timestamp.timeIntervalSince1970 * 1000.0

        #expect(abs(tsMs - expectedMs) < 0.1)
    }

    @Test("LocationFix encodes battery as percentage")
    func testBatteryEncoding() async throws {
        let fix = LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: .init(latitude: 37.7749, longitude: -122.4194),
            altitudeMeters: nil,
            horizontalAccuracyMeters: 5.0,
            verticalAccuracyMeters: 0.0,
            speedMetersPerSecond: 0.0,
            courseDegrees: 0.0,
            headingDegrees: nil,
            batteryFraction: 0.75, // 75%
            sequence: 1
        )

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(fix)
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        let batteryPct = json["battery_pct"] as! Double
        #expect(batteryPct == 75.0)
    }

    // MARK: - Equality Tests

    @Test("LocationFix equality compares all fields")
    func testEquality() async throws {
        let timestamp = Date()
        let fix1 = LocationFix(
            timestamp: timestamp,
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

        let fix2 = LocationFix(
            timestamp: timestamp,
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

        // Same ID = equal
        let fix1Copy = LocationFix(
            id: fix1.id,
            timestamp: timestamp,
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

        #expect(fix1 == fix1Copy)
        #expect(fix1 != fix2) // Different IDs
    }

    // MARK: - Convenience Property Tests

    @Test("Battery percentage converts correctly")
    func testBatteryPercentage() async throws {
        let fix = LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: .init(latitude: 0, longitude: 0),
            altitudeMeters: nil,
            horizontalAccuracyMeters: 0,
            verticalAccuracyMeters: 0,
            speedMetersPerSecond: 0,
            courseDegrees: 0,
            headingDegrees: nil,
            batteryFraction: 0.73,
            sequence: 1
        )

        #expect(fix.batteryPercentage == 73)
    }

    @Test("Valid accuracy check works correctly")
    func testValidAccuracy() async throws {
        let validFix = LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: .init(latitude: 0, longitude: 0),
            altitudeMeters: nil,
            horizontalAccuracyMeters: 5.0,
            verticalAccuracyMeters: 0,
            speedMetersPerSecond: 0,
            courseDegrees: 0,
            headingDegrees: nil,
            batteryFraction: 1.0,
            sequence: 1
        )

        let invalidFix = LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: .init(latitude: 0, longitude: 0),
            altitudeMeters: nil,
            horizontalAccuracyMeters: -1.0, // Invalid
            verticalAccuracyMeters: 0,
            speedMetersPerSecond: 0,
            courseDegrees: 0,
            headingDegrees: nil,
            batteryFraction: 1.0,
            sequence: 1
        )

        #expect(validFix.hasValidAccuracy == true)
        #expect(invalidFix.hasValidAccuracy == false)
    }

    @Test("Coordinate validation works correctly")
    func testCoordinateValidation() async throws {
        let validCoord = LocationFix.Coordinate(latitude: 37.7749, longitude: -122.4194)
        let invalidLat = LocationFix.Coordinate(latitude: 91.0, longitude: 0.0)
        let invalidLon = LocationFix.Coordinate(latitude: 0.0, longitude: 181.0)

        #expect(validCoord.isValid == true)
        #expect(invalidLat.isValid == false)
        #expect(invalidLon.isValid == false)
    }

    @Test("CLLocation conversion preserves data")
    func testCLLocationConversion() async throws {
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
            sequence: 1
        )

        let clLocation = fix.clLocation

        #expect(clLocation.coordinate.latitude == 37.7749)
        #expect(clLocation.coordinate.longitude == -122.4194)
        #expect(clLocation.altitude == 10.0)
        #expect(clLocation.horizontalAccuracy == 5.0)
        #expect(clLocation.verticalAccuracy == 10.0)
        #expect(clLocation.speed == 0.5)
        #expect(clLocation.course == 180.0)
    }

    // MARK: - Edge Case Tests

    @Test("LocationFix handles nil altitude")
    func testNilAltitude() async throws {
        let fix = LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: .init(latitude: 37.7749, longitude: -122.4194),
            altitudeMeters: nil,
            horizontalAccuracyMeters: 5.0,
            verticalAccuracyMeters: -1.0,
            speedMetersPerSecond: 0,
            courseDegrees: 0,
            headingDegrees: nil,
            batteryFraction: 1.0,
            sequence: 1
        )

        #expect(fix.altitudeMeters == nil)
        #expect(fix.hasValidAltitude == false)

        // Encode/decode should preserve nil
        let encoded = try JSONEncoder().encode(fix)
        let decoded = try JSONDecoder().decode(LocationFix.self, from: encoded)
        #expect(decoded.altitudeMeters == nil)
    }

    @Test("LocationFix handles invalid motion data")
    func testInvalidMotionData() async throws {
        let fix = LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: .init(latitude: 37.7749, longitude: -122.4194),
            altitudeMeters: nil,
            horizontalAccuracyMeters: 5.0,
            verticalAccuracyMeters: -1.0,
            speedMetersPerSecond: -1.0, // Invalid
            courseDegrees: -1.0, // Invalid
            headingDegrees: nil,
            batteryFraction: 1.0,
            sequence: 1
        )

        #expect(fix.hasValidSpeed == false)
        #expect(fix.hasValidCourse == false)
    }

    @Test("LocationFix sample fixtures work correctly")
    func testSampleFixtures() async throws {
        let sample = LocationFix.sample()
        #expect(sample.source == .watchOS)
        #expect(sample.coordinate.isValid)
        #expect(sample.hasValidAccuracy)

        let poorAccuracy = LocationFix.samplePoorAccuracy()
        #expect(poorAccuracy.horizontalAccuracyMeters > 50)
        #expect(poorAccuracy.batteryPercentage == 20)
    }
}
