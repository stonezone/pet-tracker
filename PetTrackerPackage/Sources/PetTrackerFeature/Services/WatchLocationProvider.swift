import Foundation
#if os(watchOS)
import CoreLocation
@preconcurrency import WatchConnectivity
@preconcurrency import HealthKit
import WatchKit
import Observation

/// Provides GPS location tracking on Apple Watch and transmits to paired iPhone
///
/// This is the Watch-side component that:
/// - Captures GPS fixes using CLLocationManager with HealthKit workout session
/// - Monitors device battery level
/// - Transmits location data to iPhone via triple-path WatchConnectivity
/// - Manages workout session lifecycle for extended GPS runtime
///
/// ## Triple-Path Transmission Strategy
/// Uses three complementary WatchConnectivity delivery mechanisms:
/// 1. **Application Context**: Background, latest-only, ~2Hz max (0.5s throttle)
/// 2. **Interactive Messages**: Foreground, immediate, requires reachability
/// 3. **File Transfer**: Background, guaranteed delivery, automatic retry
///
/// ## Usage
/// ```swift
/// let provider = WatchLocationProvider()
/// await provider.startTracking()
/// // GPS data automatically transmitted to iPhone
/// await provider.stopTracking()
/// ```
@MainActor
@Observable
public final class WatchLocationProvider: NSObject {

    // MARK: - Published State

    /// Current tracking status
    public private(set) var isTracking: Bool = false

    /// Latest captured location fix
    public private(set) var latestLocation: LocationFix?

    /// Current battery level (0.0-1.0)
    public private(set) var batteryLevel: Double = 1.0

    /// Whether iPhone is currently reachable
    public private(set) var isPhoneReachable: Bool = false

    /// Last error encountered
    public private(set) var lastError: (any Error)?

    /// Number of location fixes sent
    public private(set) var fixesSent: Int = 0

    // MARK: - Private Properties

    private let locationManager: CLLocationManager
    private let session: WCSession
    private let healthStore: HKHealthStore
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    private var sequenceNumber: Int = 0
    private var lastContextUpdate: Date = .distantPast
    private var lastAccuracy: Double = 0

    /// Throttle interval for application context updates
    private let contextThrottleInterval: TimeInterval = 0.5

    /// Accuracy change threshold to bypass throttle (meters)
    private let accuracyBypassThreshold: Double = 5.0

    // MARK: - Initialization

    public override init() {
        self.locationManager = CLLocationManager()
        self.session = WCSession.default
        self.healthStore = HKHealthStore()

        super.init()

        setupLocationManager()
        setupWatchConnectivity()
        setupBatteryMonitoring()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone // No throttling
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = .other // Maximum update frequency
    }

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            lastError = WatchConnectivityError.notSupported
            return
        }

        session.delegate = self
        session.activate()
    }

    private func setupBatteryMonitoring() {
        // Enable battery monitoring
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true

        // Update battery level
        updateBatteryLevel()

        // Monitor battery level changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WKInterfaceDeviceBatteryLevelDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBatteryLevel()
        }
    }

    private func updateBatteryLevel() {
        let device = WKInterfaceDevice.current()
        batteryLevel = Double(device.batteryLevel)
    }

    // MARK: - Public API

    /// Starts GPS tracking with HealthKit workout session
    public func startTracking() async {
        guard !isTracking else { return }

        // Request location permission if needed
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            lastError = LocationError.permissionDenied
            return
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }

        // Start workout session for extended GPS runtime
        do {
            try await startWorkoutSession()
        } catch {
            lastError = error
            return
        }

        // Start location updates
        locationManager.startUpdatingLocation()
        isTracking = true
    }

    /// Stops GPS tracking and ends workout session
    public func stopTracking() async {
        guard isTracking else { return }

        locationManager.stopUpdatingLocation()
        await stopWorkoutSession()
        isTracking = false
    }

    // MARK: - HealthKit Workout Session

    private func startWorkoutSession() async throws {
        // Request HealthKit authorization
        let workoutType = HKObjectType.workoutType()
        let typesToShare: Set = [workoutType]

        try await healthStore.requestAuthorization(toShare: typesToShare, read: [])

        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other // Provides most frequent GPS updates
        configuration.locationType = .outdoor

        // Create workout session
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            self.workoutSession = session
            self.workoutBuilder = builder

            // Start the session and builder
            session.startActivity(with: Date())
            try await builder.beginCollection(at: Date())

        } catch {
            throw error
        }
    }

    private func stopWorkoutSession() async {
        guard let session = workoutSession,
              let builder = workoutBuilder else {
            return
        }

        // End the workout
        session.end()

        do {
            try await builder.endCollection(at: Date())
            _ = try await builder.finishWorkout()
        } catch {
            lastError = error
        }

        workoutSession = nil
        workoutBuilder = nil
    }

    // MARK: - Triple-Path Messaging

    /// Sends location via all three delivery paths
    private func sendLocation(_ location: CLLocation) {
        sequenceNumber += 1

        // Create LocationFix
        let fix = LocationFix(
            from: location,
            source: .watchOS,
            batteryLevel: batteryLevel,
            sequence: sequenceNumber
        )

        latestLocation = fix
        fixesSent += 1

        // Path 1: Application Context (throttled, background)
        sendViaApplicationContext(fix)

        // Path 2: Interactive Message (immediate, foreground)
        if session.isReachable {
            sendViaInteractiveMessage(fix)
        }

        // Path 3: File Transfer (guaranteed, background)
        // Only send via file transfer if phone not reachable
        if !session.isReachable {
            sendViaFileTransfer(fix)
        }
    }

    /// Path 1: Application Context (0.5s throttle with accuracy bypass)
    private func sendViaApplicationContext(_ fix: LocationFix) {
        // Don't send if session not activated
        guard session.activationState == .activated else { return }

        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastContextUpdate)
        let accuracyChange = abs(fix.horizontalAccuracyMeters - lastAccuracy)

        // Throttle unless accuracy changed significantly
        guard timeSinceLastUpdate > contextThrottleInterval ||
              accuracyChange > accuracyBypassThreshold else {
            return
        }

        do {
            let jsonData = try JSONEncoder().encode(fix)
            guard let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  !dict.isEmpty else {
                return
            }

            try session.updateApplicationContext(dict)
            lastContextUpdate = now
            lastAccuracy = fix.horizontalAccuracyMeters

        } catch {
            lastError = error
            print("WatchLocationProvider: Error sending application context: \(error)")
        }
    }

    /// Path 2: Interactive Messages (immediate, requires reachability)
    private func sendViaInteractiveMessage(_ fix: LocationFix) {
        guard session.activationState == .activated,
              session.isReachable else { return }

        do {
            let jsonData = try JSONEncoder().encode(fix)
            guard let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  !dict.isEmpty else {
                return
            }

            session.sendMessage(dict, replyHandler: nil) { error in
                // Fall back to file transfer on failure
                Task { @MainActor in
                    self.lastError = error
                    print("WatchLocationProvider: Interactive message failed: \(error)")
                    self.sendViaFileTransfer(fix)
                }
            }

        } catch {
            lastError = error
            print("WatchLocationProvider: Error encoding interactive message: \(error)")
        }
    }

    /// Path 3: File Transfer (guaranteed delivery with retry)
    private func sendViaFileTransfer(_ fix: LocationFix) {
        // Don't send if session not activated
        guard session.activationState == .activated else { return }

        do {
            let jsonData = try JSONEncoder().encode(fix)

            // Write to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("json")

            try jsonData.write(to: tempURL)

            // Transfer file
            session.transferFile(tempURL, metadata: ["type": "location", "sequence": fix.sequence])

        } catch {
            lastError = error
        }
    }

    // MARK: - Error Types

    public enum LocationError: LocalizedError {
        case permissionDenied
        case healthKitNotAvailable

        public var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Location permission denied"
            case .healthKitNotAvailable:
                return "HealthKit is not available"
            }
        }
    }

    public enum WatchConnectivityError: LocalizedError {
        case notSupported
        case sessionNotActivated

        public var errorDescription: String? {
            switch self {
            case .notSupported:
                return "WatchConnectivity not supported"
            case .sessionNotActivated:
                return "WatchConnectivity session not activated"
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WatchLocationProvider: CLLocationManagerDelegate {

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.sendLocation(location)
        }
    }

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: any Error
    ) {
        Task { @MainActor in
            self.lastError = error
        }
    }

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        Task { @MainActor in
            if status == .denied || status == .restricted {
                self.lastError = LocationError.permissionDenied
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchLocationProvider: WCSessionDelegate {

    nonisolated public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        print("WatchLocationProvider: Session activated with state: \(activationState.rawValue), reachable: \(session.isReachable)")
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            if let error = error {
                self.lastError = error
                print("WatchLocationProvider: Session activation error: \(error)")
            }
        }
    }

    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
        }
    }
    
    // Note: sessionDidBecomeInactive and sessionDidDeactivate are iOS-only
    // Not needed on watchOS
}

// MARK: - WKInterfaceDevice Extension

extension WKInterfaceDevice {
    // Battery monitoring is built into WKInterfaceDevice
    // This extension is just for documentation
}

#endif
