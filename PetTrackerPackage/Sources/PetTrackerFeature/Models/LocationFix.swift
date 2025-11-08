import Foundation
import CoreLocation

/// Represents a single GPS location fix with comprehensive metadata
///
/// This is the core domain model for location data, used across iOS and watchOS platforms.
/// It captures all relevant GPS information including position, accuracy, motion data, and device metadata.
///
/// ## Design Principles
/// - **Value Type**: Immutable struct for thread-safety
/// - **Sendable**: Safe to pass across concurrency boundaries
/// - **Codable**: Efficient JSON serialization for WatchConnectivity transmission
/// - **Platform-Agnostic**: Works on both iOS and watchOS
///
/// ## JSON Encoding
/// Uses compact field names to minimize payload size over WatchConnectivity:
/// - `ts_unix_ms`: Timestamp in Unix milliseconds
/// - `lat`/`lon`: Coordinates in decimal degrees
/// - `h_accuracy_m`: Horizontal accuracy in meters
/// - `battery_pct`: Battery level as percentage (0-100)
///
/// ## Usage
/// ```swift
/// // Create from CLLocation
/// let fix = LocationFix(from: clLocation, source: .watchOS, sequence: 42)
///
/// // Encode for transmission
/// let json = try JSONEncoder().encode(fix)
///
/// // Decode from received data
/// let received = try JSONDecoder().decode(LocationFix.self, from: json)
/// ```
public struct LocationFix: Codable, Equatable, Sendable, Identifiable {

    // MARK: - Core Properties

    /// Unique identifier for this location fix
    public let id: UUID

    /// Timestamp when this location fix was captured
    public let timestamp: Date

    /// Source device that captured this location
    public let source: Source

    /// Geographic coordinate (latitude, longitude)
    public let coordinate: Coordinate

    /// Altitude above mean sea level in meters (nil if unavailable)
    public let altitudeMeters: Double?

    // MARK: - Accuracy Metrics

    /// Horizontal accuracy (radius of uncertainty) in meters
    ///
    /// Lower values indicate more precise location. Typical values:
    /// - < 5m: Excellent (Best accuracy)
    /// - 5-10m: Good
    /// - 10-50m: Fair
    /// - > 50m: Poor
    public let horizontalAccuracyMeters: Double

    /// Vertical accuracy (altitude uncertainty) in meters
    ///
    /// Negative values indicate invalid altitude data.
    public let verticalAccuracyMeters: Double

    // MARK: - Motion Data

    /// Instantaneous speed in meters per second
    ///
    /// Negative value indicates invalid speed data.
    public let speedMetersPerSecond: Double

    /// Course (direction of travel) in degrees from true north (0-360)
    ///
    /// - 0° = North
    /// - 90° = East
    /// - 180° = South
    /// - 270° = West
    ///
    /// Negative value indicates invalid course data.
    public let courseDegrees: Double

    /// Device heading in degrees from true north (0-360)
    ///
    /// **Note**: Apple Watch does not have a magnetometer, so this is nil for watchOS sources.
    /// Only available on iPhone with compass.
    public let headingDegrees: Double?

    // MARK: - Device Metadata

    /// Device battery level as fraction (0.0 - 1.0)
    ///
    /// - 1.0 = 100% charged
    /// - 0.5 = 50% charged
    /// - 0.0 = Empty
    public let batteryFraction: Double

    /// Monotonically increasing sequence number for ordering
    ///
    /// Used to detect dropped messages and ensure proper ordering when messages arrive out-of-order.
    public let sequence: Int

    // MARK: - Initialization

    /// Creates a location fix with all parameters
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - timestamp: When the fix was captured
    ///   - source: Device that captured the location
    ///   - coordinate: Geographic position
    ///   - altitudeMeters: Altitude above sea level (optional)
    ///   - horizontalAccuracyMeters: Position uncertainty radius
    ///   - verticalAccuracyMeters: Altitude uncertainty
    ///   - speedMetersPerSecond: Instantaneous speed
    ///   - courseDegrees: Direction of travel (0-360)
    ///   - headingDegrees: Device heading (nil for Watch)
    ///   - batteryFraction: Battery level (0.0-1.0)
    ///   - sequence: Monotonic sequence number
    public init(
        id: UUID = UUID(),
        timestamp: Date,
        source: Source,
        coordinate: Coordinate,
        altitudeMeters: Double?,
        horizontalAccuracyMeters: Double,
        verticalAccuracyMeters: Double,
        speedMetersPerSecond: Double,
        courseDegrees: Double,
        headingDegrees: Double?,
        batteryFraction: Double,
        sequence: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.coordinate = coordinate
        self.altitudeMeters = altitudeMeters
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.speedMetersPerSecond = speedMetersPerSecond
        self.courseDegrees = courseDegrees
        self.headingDegrees = headingDegrees
        self.batteryFraction = batteryFraction
        self.sequence = sequence
    }

    /// Creates a location fix from a CoreLocation CLLocation
    ///
    /// - Parameters:
    ///   - location: The CLLocation to convert
    ///   - source: Which device captured this location
    ///   - batteryLevel: Current device battery level (0.0-1.0)
    ///   - sequence: Sequence number for ordering
    ///   - heading: Optional device heading (iPhone only)
    public init(
        from location: CLLocation,
        source: Source,
        batteryLevel: Double,
        sequence: Int,
        heading: CLHeading? = nil
    ) {
        self.init(
            id: UUID(),
            timestamp: location.timestamp,
            source: source,
            coordinate: Coordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            altitudeMeters: location.altitude,
            horizontalAccuracyMeters: location.horizontalAccuracy,
            verticalAccuracyMeters: location.verticalAccuracy,
            speedMetersPerSecond: location.speed,
            courseDegrees: location.course,
            headingDegrees: heading?.trueHeading,
            batteryFraction: batteryLevel,
            sequence: sequence
        )
    }

    // MARK: - Nested Types

    /// Source device that captured the location
    public enum Source: String, Codable, Sendable {
        /// Captured on Apple Watch (pet's device)
        case watchOS

        /// Captured on iPhone (owner's device)
        case iOS
    }

    /// Geographic coordinate with latitude and longitude
    public struct Coordinate: Codable, Equatable, Sendable {
        /// Latitude in decimal degrees (-90 to +90)
        ///
        /// - Positive: North of equator
        /// - Negative: South of equator
        public let latitude: Double

        /// Longitude in decimal degrees (-180 to +180)
        ///
        /// - Positive: East of prime meridian
        /// - Negative: West of prime meridian
        public let longitude: Double

        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }

        /// Validates coordinate is within valid ranges
        public var isValid: Bool {
            return latitude >= -90 && latitude <= 90 &&
                   longitude >= -180 && longitude <= 180
        }

        /// Converts to CLLocationCoordinate2D for use with MapKit
        public var clLocationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    // MARK: - Coding Keys

    /// Compact JSON field names to minimize transmission size
    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp = "ts_unix_ms"
        case source
        case coordinate
        case altitudeMeters = "alt_m"
        case horizontalAccuracyMeters = "h_accuracy_m"
        case verticalAccuracyMeters = "v_accuracy_m"
        case speedMetersPerSecond = "speed_mps"
        case courseDegrees = "course_deg"
        case headingDegrees = "heading_deg"
        case batteryFraction = "battery_pct"
        case sequence = "seq"
    }

    // MARK: - Custom Encoding/Decoding

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)

        // Decode timestamp from Unix milliseconds
        let timestampMs = try container.decode(Double.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampMs / 1000.0)

        source = try container.decode(Source.self, forKey: .source)
        coordinate = try container.decode(Coordinate.self, forKey: .coordinate)
        altitudeMeters = try container.decodeIfPresent(Double.self, forKey: .altitudeMeters)
        horizontalAccuracyMeters = try container.decode(Double.self, forKey: .horizontalAccuracyMeters)
        verticalAccuracyMeters = try container.decode(Double.self, forKey: .verticalAccuracyMeters)
        speedMetersPerSecond = try container.decode(Double.self, forKey: .speedMetersPerSecond)
        courseDegrees = try container.decode(Double.self, forKey: .courseDegrees)
        headingDegrees = try container.decodeIfPresent(Double.self, forKey: .headingDegrees)

        // Decode battery as fraction (stored as percentage in JSON)
        let batteryPct = try container.decode(Double.self, forKey: .batteryFraction)
        batteryFraction = batteryPct / 100.0

        sequence = try container.decode(Int.self, forKey: .sequence)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)

        // Encode timestamp as Unix milliseconds
        let timestampMs = timestamp.timeIntervalSince1970 * 1000.0
        try container.encode(timestampMs, forKey: .timestamp)

        try container.encode(source, forKey: .source)
        try container.encode(coordinate, forKey: .coordinate)
        try container.encodeIfPresent(altitudeMeters, forKey: .altitudeMeters)
        try container.encode(horizontalAccuracyMeters, forKey: .horizontalAccuracyMeters)
        try container.encode(verticalAccuracyMeters, forKey: .verticalAccuracyMeters)
        try container.encode(speedMetersPerSecond, forKey: .speedMetersPerSecond)
        try container.encode(courseDegrees, forKey: .courseDegrees)
        try container.encodeIfPresent(headingDegrees, forKey: .headingDegrees)

        // Encode battery as percentage
        let batteryPct = batteryFraction * 100.0
        try container.encode(batteryPct, forKey: .batteryFraction)

        try container.encode(sequence, forKey: .sequence)
    }

    // MARK: - Convenience Properties

    /// Battery level as percentage (0-100)
    public var batteryPercentage: Int {
        return Int(batteryFraction * 100)
    }

    /// Age of this location fix (time since timestamp)
    public var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }

    /// Whether this location fix has valid accuracy
    public var hasValidAccuracy: Bool {
        return horizontalAccuracyMeters >= 0
    }

    /// Whether this location fix has valid altitude
    public var hasValidAltitude: Bool {
        return altitudeMeters != nil && verticalAccuracyMeters >= 0
    }

    /// Whether this location fix has valid speed
    public var hasValidSpeed: Bool {
        return speedMetersPerSecond >= 0
    }

    /// Whether this location fix has valid course
    public var hasValidCourse: Bool {
        return courseDegrees >= 0
    }

    /// Converts to CLLocation for use with MapKit and CoreLocation APIs
    public var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate.clLocationCoordinate,
            altitude: altitudeMeters ?? 0,
            horizontalAccuracy: horizontalAccuracyMeters,
            verticalAccuracy: verticalAccuracyMeters,
            course: courseDegrees,
            speed: speedMetersPerSecond,
            timestamp: timestamp
        )
    }
}

// MARK: - Test Fixtures

#if DEBUG
extension LocationFix {
    /// Sample location fix for testing (San Francisco coordinates)
    public static func sample(sequence: Int = 1) -> LocationFix {
        LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
            altitudeMeters: 10.0,
            horizontalAccuracyMeters: 5.0,
            verticalAccuracyMeters: 10.0,
            speedMetersPerSecond: 0.5,
            courseDegrees: 180.0,
            headingDegrees: nil,
            batteryFraction: 0.85,
            sequence: sequence
        )
    }

    /// Sample location fix with poor accuracy
    public static func samplePoorAccuracy(sequence: Int = 1) -> LocationFix {
        LocationFix(
            timestamp: Date(),
            source: .watchOS,
            coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
            altitudeMeters: nil,
            horizontalAccuracyMeters: 65.0,
            verticalAccuracyMeters: -1.0,
            speedMetersPerSecond: -1.0,
            courseDegrees: -1.0,
            headingDegrees: nil,
            batteryFraction: 0.20,
            sequence: sequence
        )
    }
}
#endif
