import Foundation
import CoreLocation
import WatchConnectivity
import Observation

/// Manages pet location tracking by receiving GPS data from Apple Watch
///
/// This is the central coordinator for the iOS app that:
/// - Receives location fixes from Watch via WatchConnectivity
/// - Tracks owner's location using iPhone GPS
/// - Calculates distance between pet and owner
/// - Maintains historical trail of pet locations
/// - Manages WatchConnectivity session lifecycle
///
/// ## Architecture
/// - **Pattern**: @Observable for reactive SwiftUI integration
/// - **Thread Safety**: All UI-related properties are @MainActor isolated
/// - **Delegate**: Implements WCSessionDelegate for receiving Watch messages
///
/// ## Usage
/// ```swift
/// @State private var locationManager = PetLocationManager()
///
/// var body: some View {
///     VStack {
///         if let distance = locationManager.distanceFromOwner {
///             Text("Pet is \(Int(distance))m away")
///         }
///     }
///     .task {
///         await locationManager.startTracking()
///     }
/// }
/// ```
@MainActor
@Observable
public final class PetLocationManager: NSObject {

    // MARK: - Published State

    /// Latest location fix received from pet's Apple Watch
    public private(set) var latestPetLocation: LocationFix?

    /// Historical trail of pet locations (last 100 fixes)
    public private(set) var locationHistory: [LocationFix] = []

    /// Owner's current location (from iPhone GPS)
    public private(set) var ownerLocation: CLLocation?

    /// Calculated distance from owner to pet in meters (nil if either location unavailable)
    public var distanceFromOwner: Double? {
        guard let petFix = latestPetLocation,
              let owner = ownerLocation else {
            return nil
        }
        return owner.distance(from: petFix.clLocation)
    }

    /// Pet's battery level as percentage (0-100)
    public var petBatteryLevel: Int? {
        latestPetLocation?.batteryPercentage
    }

    /// GPS horizontal accuracy in meters
    public var accuracyMeters: Double? {
        latestPetLocation?.horizontalAccuracyMeters
    }

    /// Time since last location update
    public var timeSinceLastUpdate: TimeInterval? {
        latestPetLocation?.age
    }

    /// Whether Watch is currently reachable via WatchConnectivity
    public private(set) var isWatchReachable: Bool = false

    /// Whether WatchConnectivity session is activated
    public private(set) var isSessionActivated: Bool = false

    /// Last error encountered
    public private(set) var lastError: Error?

    /// Connection status message for UI display
    public var connectionStatus: String {
        if !isSessionActivated {
            return "Connecting to Watch..."
        } else if !isWatchReachable {
            return "Watch not reachable"
        } else {
            return "Connected"
        }
    }

    // MARK: - Private Properties

    private let locationManager: CLLocationManager
    private let session: WCSession
    private var sequenceNumber: Int = 0

    /// Maximum number of location fixes to keep in history
    private let maxHistorySize = 100

    // MARK: - Initialization

    /// Creates a new pet location manager
    public override init() {
        self.locationManager = CLLocationManager()
        self.session = WCSession.default

        super.init()

        setupLocationManager()
        setupWatchConnectivity()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            lastError = WatchConnectivityError.notSupported
            return
        }

        session.delegate = self
        session.activate()
    }

    // MARK: - Public API

    /// Starts tracking both pet (via Watch) and owner (via iPhone GPS)
    public func startTracking() async {
        // Request location permissions if needed
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            lastError = LocationError.permissionDenied
            return
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }

        // WatchConnectivity is already set up in init
        // Just verify session is activated
        guard session.activationState == .activated else {
            lastError = WatchConnectivityError.sessionNotActivated
            return
        }
    }

    /// Stops tracking
    public func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    /// Clears location history
    public func clearHistory() {
        locationHistory.removeAll()
    }

    // MARK: - Private Helpers

    private func handleReceivedLocationFix(_ fix: LocationFix) {
        // Update latest location
        latestPetLocation = fix

        // Add to history
        locationHistory.append(fix)

        // Trim history if needed
        if locationHistory.count > maxHistorySize {
            locationHistory.removeFirst(locationHistory.count - maxHistorySize)
        }

        // Update sequence number
        sequenceNumber = max(sequenceNumber, fix.sequence)
    }

    // MARK: - Error Types

    public enum LocationError: LocalizedError {
        case permissionDenied

        public var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission denied. Please enable location access in Settings."
            }
        }
    }

    public enum WatchConnectivityError: LocalizedError {
        case notSupported
        case sessionNotActivated

        public var errorDescription: String? {
            switch self {
            case .notSupported:
                return "WatchConnectivity is not supported on this device."
            case .sessionNotActivated:
                return "WatchConnectivity session is not activated."
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension PetLocationManager: CLLocationManagerDelegate {

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.ownerLocation = location
        }
    }

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.lastError = error
        }
    }

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.lastError = LocationError.permissionDenied
            default:
                break
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension PetLocationManager: WCSessionDelegate {

    nonisolated public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isSessionActivated = (activationState == .activated)
            if let error = error {
                self.lastError = error
            }
        }
    }

    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.isSessionActivated = false
        }
    }

    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.isSessionActivated = false
        }
        session.activate()
    }

    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    // MARK: - Message Reception (Triple-Path)

    /// Receives interactive messages (foreground, immediate)
    nonisolated public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        handleReceivedMessage(message)
    }

    /// Receives interactive messages with reply handler
    nonisolated public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleReceivedMessage(message)
        replyHandler(["status": "received"])
    }

    /// Receives application context updates (background, latest-only)
    nonisolated public func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        handleReceivedMessage(applicationContext)
    }

    /// Receives file transfers (background, guaranteed delivery)
    nonisolated public func session(
        _ session: WCSession,
        didReceive file: WCSessionFile
    ) {
        do {
            let data = try Data(contentsOf: file.fileURL)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                handleReceivedMessage(json)
            }
        } catch {
            Task { @MainActor in
                self.lastError = error
            }
        }
    }

    /// Common handler for all message types
    private func handleReceivedMessage(_ message: [String: Any]) {
        do {
            // Convert dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: message)

            // Decode LocationFix
            let fix = try JSONDecoder().decode(LocationFix.self, from: jsonData)

            // Update on main thread
            Task { @MainActor in
                self.handleReceivedLocationFix(fix)
            }
        } catch {
            Task { @MainActor in
                self.lastError = error
            }
        }
    }
}
