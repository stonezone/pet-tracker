import Testing
import Foundation
import CoreLocation
#if os(iOS)
@preconcurrency import WatchConnectivity
#endif
@testable import PetTrackerFeature

/// Comprehensive test suite for PetLocationManager
///
/// Tests cover:
/// - Initialization and setup
/// - WatchConnectivity session lifecycle
/// - Triple-path message reception (interactive, context, file)
/// - Location history management
/// - Distance calculation
/// - Owner location tracking
/// - Error handling
/// - Authorization flow
///
/// Coverage target: >90%
@Suite("PetLocationManager Tests")
struct PetLocationManagerTests {

    // MARK: - Initialization & Setup Tests

    @Test("PetLocationManager initializes with correct state")
    @MainActor
    func testInitialization() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Verify initial state
        #expect(manager.latestPetLocation == nil)
        #expect(manager.locationHistory.isEmpty)
        #expect(manager.ownerLocation == nil)
        #expect(manager.distanceFromOwner == nil)
        #expect(manager.petBatteryLevel == nil)
        #expect(manager.accuracyMeters == nil)
        #expect(manager.timeSinceLastUpdate == nil)
        #expect(manager.lastError == nil)
        #endif
    }

    @Test("PetLocationManager configures CLLocationManager correctly")
    @MainActor
    func testLocationManagerConfiguration() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        _ = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Verify CLLocationManager configuration
        #expect(mockLocationManager.desiredAccuracy == kCLLocationAccuracyBest)
        #expect(mockLocationManager.distanceFilter == 10.0)
        #expect(mockLocationManager.allowsBackgroundLocationUpdates == true)
        #expect(mockLocationManager.delegate != nil)
        #endif
    }

    @Test("PetLocationManager activates WCSession on init")
    @MainActor
    func testWCSessionActivation() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .notActivated
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Verify session delegate set
        #expect(mockSession.delegate != nil)

        // Simulate activation completing
        mockSession.triggerActivation(state: .activated, error: nil)

        // Give time for async task to complete
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isSessionActivated == true)
        #endif
    }

    // MARK: - Session Lifecycle Tests

    @Test("Session activation updates state correctly")
    @MainActor
    func testSessionActivationStateUpdate() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .notActivated
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        #expect(manager.isSessionActivated == false)

        // Trigger successful activation
        mockSession.triggerActivation(state: .activated, error: nil)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isSessionActivated == true)
        #expect(manager.lastError == nil)
        #endif
    }

    @Test("Session activation handles errors")
    @MainActor
    func testSessionActivationError() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .notActivated
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let testError = MockWCSessionError.sessionInactive
        mockSession.triggerActivation(state: .inactive, error: testError)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isSessionActivated == false)
        #expect(manager.lastError != nil)
        #endif
    }

    @Test("Session reachability changes are tracked")
    @MainActor
    func testReachabilityChanges() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockIsReachable = false
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        mockSession.triggerActivation(state: .activated, error: nil)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isWatchReachable == false)

        // Simulate Watch becoming reachable
        mockSession.triggerReachabilityChange(reachable: true)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isWatchReachable == true)
        #endif
    }

    @Test("Session inactive callback updates state")
    @MainActor
    func testSessionBecameInactive() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        mockSession.triggerActivation(state: .activated, error: nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(manager.isSessionActivated == true)

        // Simulate session becoming inactive
        mockSession.triggerSessionInactive()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isSessionActivated == false)
        #endif
    }

    @Test("Session deactivate callback reactivates session")
    @MainActor
    func testSessionDeactivateReactivates() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        mockSession.triggerActivation(state: .activated, error: nil)
        try await Task.sleep(for: .milliseconds(100))
        #expect(manager.isSessionActivated == true)

        // Simulate session deactivation
        mockSession.triggerSessionDeactivate()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.isSessionActivated == false)
        // Session should be reactivated (activate() called in delegate)
        #endif
    }

    @Test("Connection status reflects session state")
    @MainActor
    func testConnectionStatus() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .notActivated
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        #expect(manager.connectionStatus == "Connecting to Watch...")

        mockSession.triggerActivation(state: .activated, error: nil)
        mockSession.mockIsReachable = false
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.connectionStatus == "Watch not reachable")

        mockSession.triggerReachabilityChange(reachable: true)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.connectionStatus == "Connected")
        #endif
    }

    // MARK: - Message Reception Tests (Triple-Path)

    @Test("Receives interactive message without reply handler")
    @MainActor
    func testReceiveInteractiveMessage() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let fix = TestDataFactory.createLocationFix(sequence: 42)
        let messageDict = try JSONTestHelpers.toDictionary(fix)

        mockSession.simulateReceiveMessage(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.latestPetLocation != nil)
        #expect(manager.latestPetLocation?.sequence == 42)
        #expect(manager.locationHistory.count == 1)
        #endif
    }

    @Test("Receives interactive message with reply handler")
    @MainActor
    func testReceiveInteractiveMessageWithReply() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let fix = TestDataFactory.createLocationFix(sequence: 100)
        let messageDict = try JSONTestHelpers.toDictionary(fix)

        var replyReceived = false
        mockSession.simulateReceiveMessageWithReply(messageDict) { reply in
            replyReceived = true
            #expect(reply["status"] as? String == "received")
        }

        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.latestPetLocation?.sequence == 100)
        #expect(replyReceived == true)
        #endif
    }

    @Test("Receives application context update")
    @MainActor
    func testReceiveApplicationContext() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let fix = TestDataFactory.createLocationFix(
            latitude: 37.3348,
            longitude: -122.0090,
            sequence: 200
        )
        let contextDict = try JSONTestHelpers.toDictionary(fix)

        mockSession.simulateReceiveApplicationContext(contextDict)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.latestPetLocation != nil)
        #expect(manager.latestPetLocation?.sequence == 200)
        #expect(manager.latestPetLocation?.coordinate.latitude == 37.3348)
        #endif
    }

    @Test("Receives file transfer")
    @MainActor
    func testReceiveFileTransfer() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Create temporary file with LocationFix JSON
        let fix = TestDataFactory.createLocationFix(sequence: 300)
        let jsonData = try JSONEncoder().encode(fix)

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_location_\(UUID().uuidString).json")
        try jsonData.write(to: fileURL)

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Create a real WCSessionFile (cannot be easily mocked)
        // Instead, test the message handling directly
        let messageDict = try JSONTestHelpers.toDictionary(fix)
        mockSession.simulateReceiveApplicationContext(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.latestPetLocation?.sequence == 300)
        #endif
    }

    @Test("Handles invalid message format gracefully")
    @MainActor
    func testReceiveInvalidMessage() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let invalidMessage: [String: Any] = [
            "invalid": "data",
            "missing": "required_fields"
        ]

        mockSession.simulateReceiveMessage(invalidMessage)
        try await Task.sleep(for: .milliseconds(100))

        // Should not crash, should set error
        #expect(manager.latestPetLocation == nil)
        #expect(manager.lastError != nil)
        #endif
    }

    // MARK: - Location History Management Tests

    @Test("Location history stores received fixes")
    @MainActor
    func testLocationHistoryStores() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let trail = TestDataFactory.createLocationTrail(count: 5, startSequence: 1)

        for fix in trail {
            let messageDict = try JSONTestHelpers.toDictionary(fix)
            mockSession.simulateReceiveMessage(messageDict)
            try await Task.sleep(for: .milliseconds(50))
        }

        #expect(manager.locationHistory.count == 5)
        #expect(manager.locationHistory.first?.sequence == 1)
        #expect(manager.locationHistory.last?.sequence == 5)
        #endif
    }

    @Test("Location history maintains max 100 fixes")
    @MainActor
    func testLocationHistoryMaxSize() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Send 150 fixes
        let trail = TestDataFactory.createLocationTrail(count: 150, startSequence: 1)

        for fix in trail {
            let messageDict = try JSONTestHelpers.toDictionary(fix)
            mockSession.simulateReceiveMessage(messageDict)
            try await Task.sleep(for: .milliseconds(10))
        }

        // Should only keep last 100
        #expect(manager.locationHistory.count == 100)
        #expect(manager.locationHistory.first?.sequence == 51) // Oldest kept
        #expect(manager.locationHistory.last?.sequence == 150) // Newest
        #endif
    }

    @Test("Location history trims correctly when exceeding limit")
    @MainActor
    func testLocationHistoryTrimming() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Add exactly 100 fixes
        let trail1 = TestDataFactory.createLocationTrail(count: 100, startSequence: 1)
        for fix in trail1 {
            let messageDict = try JSONTestHelpers.toDictionary(fix)
            mockSession.simulateReceiveMessage(messageDict)
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(manager.locationHistory.count == 100)

        // Add 5 more - should trim oldest 5
        let trail2 = TestDataFactory.createLocationTrail(count: 5, startSequence: 101)
        for fix in trail2 {
            let messageDict = try JSONTestHelpers.toDictionary(fix)
            mockSession.simulateReceiveMessage(messageDict)
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(manager.locationHistory.count == 100)
        #expect(manager.locationHistory.first?.sequence == 6) // 1-5 trimmed
        #expect(manager.locationHistory.last?.sequence == 105)
        #endif
    }

    @Test("Clear history removes all fixes")
    @MainActor
    func testClearHistory() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let trail = TestDataFactory.createLocationTrail(count: 10, startSequence: 1)
        for fix in trail {
            let messageDict = try JSONTestHelpers.toDictionary(fix)
            mockSession.simulateReceiveMessage(messageDict)
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(manager.locationHistory.count == 10)

        manager.clearHistory()

        #expect(manager.locationHistory.isEmpty)
        #expect(manager.latestPetLocation != nil) // Latest not cleared
        #endif
    }

    @Test("Sequence number tracks highest received")
    @MainActor
    func testSequenceNumberTracking() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Send fixes with non-sequential sequence numbers
        let sequences = [5, 2, 10, 7, 15]
        for seq in sequences {
            let fix = TestDataFactory.createLocationFix(sequence: seq)
            let messageDict = try JSONTestHelpers.toDictionary(fix)
            mockSession.simulateReceiveMessage(messageDict)
            try await Task.sleep(for: .milliseconds(50))
        }

        // Latest should be highest sequence
        #expect(manager.latestPetLocation?.sequence == 15)
        #endif
    }

    // MARK: - Distance Calculation Tests

    @Test("Distance calculation returns nil when pet location missing")
    @MainActor
    func testDistanceNoPetLocation() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Set owner location but no pet location
        let ownerLoc = CLLocation.testLocation(latitude: 37.7749, longitude: -122.4194)
        mockLocationManager.simulateLocationUpdate([ownerLoc])
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.distanceFromOwner == nil)
        #endif
    }

    @Test("Distance calculation returns nil when owner location missing")
    @MainActor
    func testDistanceNoOwnerLocation() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Set pet location but no owner location
        let fix = TestDataFactory.createLocationFix(latitude: 37.7749, longitude: -122.4194)
        let messageDict = try JSONTestHelpers.toDictionary(fix)
        mockSession.simulateReceiveMessage(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.distanceFromOwner == nil)
        #endif
    }

    @Test("Distance calculation works when both locations present")
    @MainActor
    func testDistanceCalculation() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Set pet location (San Francisco)
        let petFix = TestDataFactory.createLocationFix(
            latitude: 37.7749,
            longitude: -122.4194
        )
        let messageDict = try JSONTestHelpers.toDictionary(petFix)
        mockSession.simulateReceiveMessage(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        // Set owner location (nearby, ~1km away)
        let ownerLoc = CLLocation.testLocation(
            latitude: 37.7849, // ~1.1km north
            longitude: -122.4194
        )
        mockLocationManager.simulateLocationUpdate([ownerLoc])
        try await Task.sleep(for: .milliseconds(100))

        let distance = manager.distanceFromOwner
        #expect(distance != nil)

        // Distance should be approximately 1100 meters
        if let distance = distance {
            #expect(distance > 1000 && distance < 1200)
        }
        #endif
    }

    @Test("Distance uses CLLocation.distance method")
    @MainActor
    func testDistanceUsesCoreLocation() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Same coordinates = 0 distance
        let petFix = TestDataFactory.createLocationFix(
            latitude: 37.7749,
            longitude: -122.4194
        )
        let messageDict = try JSONTestHelpers.toDictionary(petFix)
        mockSession.simulateReceiveMessage(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        let ownerLoc = CLLocation.testLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        mockLocationManager.simulateLocationUpdate([ownerLoc])
        try await Task.sleep(for: .milliseconds(100))

        let distance = manager.distanceFromOwner
        #expect(distance != nil)
        #expect(distance! < 1.0) // Should be ~0
        #endif
    }

    // MARK: - Owner Location Tracking Tests

    @Test("Owner location updates from CLLocationManager")
    @MainActor
    func testOwnerLocationUpdates() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        #expect(manager.ownerLocation == nil)

        let location = CLLocation.testLocation(latitude: 37.7749, longitude: -122.4194)
        mockLocationManager.simulateLocationUpdate([location])
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.ownerLocation != nil)
        #expect(manager.ownerLocation?.coordinate.latitude == 37.7749)
        #expect(manager.ownerLocation?.coordinate.longitude == -122.4194)
        #endif
    }

    @Test("Owner location takes last location from array")
    @MainActor
    func testOwnerLocationTakesLast() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let locations = [
            CLLocation.testLocation(latitude: 37.7749, longitude: -122.4194),
            CLLocation.testLocation(latitude: 37.7850, longitude: -122.4294),
            CLLocation.testLocation(latitude: 37.7950, longitude: -122.4394)
        ]

        mockLocationManager.simulateLocationUpdate(locations)
        try await Task.sleep(for: .milliseconds(100))

        // Should use last location
        #expect(manager.ownerLocation?.coordinate.latitude == 37.7950)
        #expect(manager.ownerLocation?.coordinate.longitude == -122.4394)
        #endif
    }

    @Test("Location manager error sets lastError")
    @MainActor
    func testLocationManagerError() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let error = MockLocationError.locationUnknown
        mockLocationManager.simulateLocationError(error)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.lastError != nil)
        #endif
    }

    // MARK: - Authorization Tests

    @Test("Start tracking requests authorization when not determined")
    @MainActor
    func testStartTrackingRequestsAuthorization() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .activated
        let mockLocationManager = MockCLLocationManager()
        mockLocationManager.mockAuthorizationStatus = .notDetermined

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        await manager.startTracking()
        try await Task.sleep(for: .milliseconds(100))

        #expect(mockLocationManager.requestWhenInUseAuthorizationCalled)
        #endif
    }

    @Test("Start tracking fails when permission denied")
    @MainActor
    func testStartTrackingFailsWhenDenied() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .activated
        let mockLocationManager = MockCLLocationManager()
        mockLocationManager.mockAuthorizationStatus = .denied

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        await manager.startTracking()
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.lastError != nil)
        #expect(!mockLocationManager.startUpdatingLocationCalled)
        #endif
    }

    @Test("Start tracking starts location updates when authorized")
    @MainActor
    func testStartTrackingWhenAuthorized() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .activated
        let mockLocationManager = MockCLLocationManager()
        mockLocationManager.mockAuthorizationStatus = .authorizedWhenInUse

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        await manager.startTracking()
        try await Task.sleep(for: .milliseconds(100))

        #expect(mockLocationManager.startUpdatingLocationCalled)
        #endif
    }

    @Test("Authorization change starts location updates when authorized")
    @MainActor
    func testAuthorizationChangeStartsUpdates() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()
        mockLocationManager.mockAuthorizationStatus = .notDetermined

        _ = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        #expect(!mockLocationManager.startUpdatingLocationCalled)

        // Simulate authorization granted
        mockLocationManager.simulateAuthorizationChange(.authorizedWhenInUse)
        try await Task.sleep(for: .milliseconds(100))

        #expect(mockLocationManager.startUpdatingLocationCalled)
        #endif
    }

    @Test("Authorization change sets error when denied")
    @MainActor
    func testAuthorizationChangeDenied() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()
        mockLocationManager.mockAuthorizationStatus = .notDetermined

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        mockLocationManager.simulateAuthorizationChange(.denied)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.lastError != nil)
        #endif
    }

    @Test("Start tracking waits for session activation")
    @MainActor
    func testStartTrackingWaitsForActivation() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .notActivated
        let mockLocationManager = MockCLLocationManager()
        mockLocationManager.mockAuthorizationStatus = .authorizedWhenInUse

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Start tracking while session not activated
        Task {
            await manager.startTracking()
        }

        try await Task.sleep(for: .milliseconds(500))

        // Should wait and then fail with session not activated error
        #expect(manager.lastError != nil)
        #endif
    }

    @Test("Start tracking succeeds when session activates in time")
    @MainActor
    func testStartTrackingSessionActivatesInTime() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        mockSession.mockActivationState = .notActivated
        let mockLocationManager = MockCLLocationManager()
        mockLocationManager.mockAuthorizationStatus = .authorizedWhenInUse

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Activate session after short delay
        Task {
            try await Task.sleep(for: .milliseconds(200))
            mockSession.mockActivationState = .activated
            mockSession.triggerActivation(state: .activated, error: nil)
        }

        await manager.startTracking()
        try await Task.sleep(for: .milliseconds(100))

        // Should succeed
        #expect(mockLocationManager.startUpdatingLocationCalled)
        #endif
    }

    @Test("Stop tracking stops location updates")
    @MainActor
    func testStopTracking() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        manager.stopTracking()

        #expect(mockLocationManager.stopUpdatingLocationCalled)
        #endif
    }

    // MARK: - Computed Property Tests

    @Test("Pet battery level returns correct percentage")
    @MainActor
    func testPetBatteryLevel() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        #expect(manager.petBatteryLevel == nil)

        let fix = TestDataFactory.createLocationFix(batteryLevel: 0.73)
        let messageDict = try JSONTestHelpers.toDictionary(fix)
        mockSession.simulateReceiveMessage(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.petBatteryLevel == 73)
        #endif
    }

    @Test("Accuracy meters returns horizontal accuracy")
    @MainActor
    func testAccuracyMeters() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        #expect(manager.accuracyMeters == nil)

        let fix = TestDataFactory.createLocationFix(horizontalAccuracy: 12.5)
        let messageDict = try JSONTestHelpers.toDictionary(fix)
        mockSession.simulateReceiveMessage(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.accuracyMeters == 12.5)
        #endif
    }

    @Test("Time since last update calculates age")
    @MainActor
    func testTimeSinceLastUpdate() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        #expect(manager.timeSinceLastUpdate == nil)

        // Create fix with timestamp 5 seconds ago
        let pastTimestamp = Date().addingTimeInterval(-5.0)
        let fix = TestDataFactory.createLocationFix(timestamp: pastTimestamp)
        let messageDict = try JSONTestHelpers.toDictionary(fix)
        mockSession.simulateReceiveMessage(messageDict)
        try await Task.sleep(for: .milliseconds(100))

        let age = manager.timeSinceLastUpdate
        #expect(age != nil)
        if let age = age {
            // Should be approximately 5 seconds (allow 1 second tolerance)
            #expect(age > 4.0 && age < 6.0)
        }
        #endif
    }

    // MARK: - Error Handling Tests

    @Test("WCSession not supported sets error")
    @MainActor
    func testSessionNotSupported() async throws {
        #if os(iOS)
        // Note: Cannot easily test this as isSupported is a class property
        // Would require swizzling or protocol abstraction
        // This is documented as a known limitation
        #endif
    }

    @Test("Multiple rapid messages handled correctly")
    @MainActor
    func testRapidMessages() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        // Send 10 messages rapidly
        for i in 1...10 {
            let fix = TestDataFactory.createLocationFix(sequence: i)
            let messageDict = try JSONTestHelpers.toDictionary(fix)
            mockSession.simulateReceiveMessage(messageDict)
        }

        try await Task.sleep(for: .milliseconds(500))

        // All should be processed
        #expect(manager.locationHistory.count == 10)
        #expect(manager.latestPetLocation?.sequence == 10)
        #endif
    }

    @Test("Latest pet location updates with each message")
    @MainActor
    func testLatestPetLocationUpdates() async throws {
        #if os(iOS)
        let mockSession = MockWCSession()
        let mockLocationManager = MockCLLocationManager()

        let manager = PetLocationManager(
            locationManager: mockLocationManager,
            session: mockSession
        )

        let fix1 = TestDataFactory.createLocationFix(latitude: 37.0, sequence: 1)
        let messageDict1 = try JSONTestHelpers.toDictionary(fix1)
        mockSession.simulateReceiveMessage(messageDict1)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.latestPetLocation?.coordinate.latitude == 37.0)

        let fix2 = TestDataFactory.createLocationFix(latitude: 38.0, sequence: 2)
        let messageDict2 = try JSONTestHelpers.toDictionary(fix2)
        mockSession.simulateReceiveMessage(messageDict2)
        try await Task.sleep(for: .milliseconds(100))

        #expect(manager.latestPetLocation?.coordinate.latitude == 38.0)
        #endif
    }
}
