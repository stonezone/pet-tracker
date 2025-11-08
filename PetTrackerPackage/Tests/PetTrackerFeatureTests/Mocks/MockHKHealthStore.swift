import Foundation
#if os(iOS) || os(watchOS)
@preconcurrency import HealthKit
#if os(watchOS)
import WatchKit
#endif
#endif
@testable import PetTrackerFeature

#if os(iOS) || os(watchOS)
/// Mock HealthKit store for testing workout sessions
///
/// Provides full control over HealthKit behavior including:
/// - Authorization simulation
/// - Workout session creation
/// - Data collection capture
/// - Error injection
///
/// ## Usage
/// ```swift
/// let mockStore = MockHKHealthStore()
/// mockStore.shouldAuthorize = true
///
/// // Request authorization
/// try await mockStore.requestAuthorization(toShare: [.workoutType()], read: [])
///
/// // Verify authorization was requested
/// #expect(mockStore.authorizationRequestCount == 1)
/// ```
public final class MockHKHealthStore: HKHealthStore {

    // MARK: - Captured State

    /// Number of authorization requests made
    public var authorizationRequestCount = 0

    /// Types requested to share
    public var capturedTypesToShare: Set<HKSampleType> = []

    /// Types requested to read
    public var capturedTypesToRead: Set<HKObjectType> = []

    /// Workout sessions created
    public var createdWorkoutSessions: [HKWorkoutSession] = []

    // MARK: - Controllable State

    /// Whether authorization should succeed (default: true)
    public var shouldAuthorize = true

    /// Error to inject during authorization
    public var authorizationError: Error?

    /// Whether HealthKit is available (default: true)
    public var mockIsHealthDataAvailable = true

    /// Simulated delay before authorization completes
    public var authorizationDelay: TimeInterval = 0

    // MARK: - HealthKit Overrides

    public override class func isHealthDataAvailable() -> Bool {
        // Cannot override class method in mock, use instance method instead
        return true
    }

    public override func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?
    ) async throws {
        authorizationRequestCount += 1

        if let types = typesToShare {
            capturedTypesToShare.formUnion(types)
        }

        if let types = typesToRead {
            capturedTypesToRead.formUnion(types)
        }

        // Simulate delay if configured
        if authorizationDelay > 0 {
            try await Task.sleep(for: .seconds(authorizationDelay))
        }

        // Throw error if configured
        if let error = authorizationError {
            throw error
        }

        // Check if authorization should succeed
        if !shouldAuthorize {
            throw MockHealthKitError.authorizationDenied
        }
    }

    // MARK: - Test Helpers

    /// Creates a mock workout session
    public func createMockWorkoutSession(
        activityType: HKWorkoutActivityType = .other,
        locationType: HKWorkoutSessionLocationType = .outdoor
    ) -> MockHKWorkoutSession {
        let session = MockHKWorkoutSession(
            activityType: activityType,
            locationType: locationType
        )
        return session
    }

    /// Resets all captured state
    public func reset() {
        authorizationRequestCount = 0
        capturedTypesToShare.removeAll()
        capturedTypesToRead.removeAll()
        createdWorkoutSessions.removeAll()
        shouldAuthorize = true
        authorizationError = nil
        authorizationDelay = 0
        mockIsHealthDataAvailable = true
    }
}

// MARK: - Mock Workout Session

/// Mock HealthKit workout session for testing
public final class MockHKWorkoutSession: HKWorkoutSession {

    // MARK: - Captured State

    /// Whether startActivity was called
    public var startActivityCalled = false

    /// Whether end was called
    public var endCalled = false

    /// Timestamp when activity started
    public var activityStartDate: Date?

    // MARK: - Controllable State

    /// Current session state
    public var mockState: HKWorkoutSessionState = .notStarted

    /// Activity type for this session
    public var mockActivityType: HKWorkoutActivityType

    /// Location type for this session
    public var mockLocationType: HKWorkoutSessionLocationType

    /// Associated workout builder
    public var mockWorkoutBuilder: MockHKLiveWorkoutBuilder?

    // MARK: - Initialization

    public init(
        activityType: HKWorkoutActivityType = .other,
        locationType: HKWorkoutSessionLocationType = .outdoor
    ) {
        self.mockActivityType = activityType
        self.mockLocationType = locationType

        // Create associated builder
        self.mockWorkoutBuilder = MockHKLiveWorkoutBuilder()

        // Cannot call super.init without proper configuration
        // This is a limitation of mocking HKWorkoutSession
        // In practice, use protocol abstraction instead
    }

    // MARK: - Session Control

    public override func startActivity(with date: Date?) {
        startActivityCalled = true
        activityStartDate = date ?? Date()
        mockState = .running
    }

    public override func end() {
        endCalled = true
        mockState = .ended
    }

    public override var state: HKWorkoutSessionState {
        return mockState
    }

    public override var activityType: HKWorkoutActivityType {
        return mockActivityType
    }

    public override var locationType: HKWorkoutSessionLocationType {
        return mockLocationType
    }

    public override func associatedWorkoutBuilder() -> HKLiveWorkoutBuilder {
        return mockWorkoutBuilder ?? MockHKLiveWorkoutBuilder()
    }

    /// Resets captured state
    public func reset() {
        startActivityCalled = false
        endCalled = false
        activityStartDate = nil
        mockState = .notStarted
    }
}

// MARK: - Mock Workout Builder

/// Mock HealthKit live workout builder for testing
public final class MockHKLiveWorkoutBuilder: HKLiveWorkoutBuilder {

    // MARK: - Captured State

    /// Whether beginCollection was called
    public var beginCollectionCalled = false

    /// Whether endCollection was called
    public var endCollectionCalled = false

    /// Whether finishWorkout was called
    public var finishWorkoutCalled = false

    /// Date when collection began
    public var collectionStartDate: Date?

    /// Date when collection ended
    public var collectionEndDate: Date?

    // MARK: - Controllable State

    /// Error to inject during operations
    public var errorToInject: Error?

    /// Mock workout to return from finishWorkout
    public var mockFinishedWorkout: HKWorkout?

    /// Simulated delay before operations complete
    public var operationDelay: TimeInterval = 0

    // MARK: - Builder Operations

    public override func beginCollection(at date: Date) async throws {
        beginCollectionCalled = true
        collectionStartDate = date

        if operationDelay > 0 {
            try await Task.sleep(for: .seconds(operationDelay))
        }

        if let error = errorToInject {
            throw error
        }
    }

    public override func endCollection(at date: Date) async throws {
        endCollectionCalled = true
        collectionEndDate = date

        if operationDelay > 0 {
            try await Task.sleep(for: .seconds(operationDelay))
        }

        if let error = errorToInject {
            throw error
        }
    }

    public override func finishWorkout() async throws -> HKWorkout {
        finishWorkoutCalled = true

        if operationDelay > 0 {
            try await Task.sleep(for: .seconds(operationDelay))
        }

        if let error = errorToInject {
            throw error
        }

        // Return mock workout or create default
        if let workout = mockFinishedWorkout {
            return workout
        }

        // Create minimal mock workout
        // Note: HKWorkout requires specific initialization
        return HKWorkout(
            activityType: .other,
            start: collectionStartDate ?? Date(),
            end: collectionEndDate ?? Date()
        )
    }

    /// Resets captured state
    public func reset() {
        beginCollectionCalled = false
        endCollectionCalled = false
        finishWorkoutCalled = false
        collectionStartDate = nil
        collectionEndDate = nil
        errorToInject = nil
        operationDelay = 0
    }
}

// MARK: - Mock Errors

public enum MockHealthKitError: Error, LocalizedError {
    case authorizationDenied
    case healthKitUnavailable
    case workoutSessionFailed

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "HealthKit authorization denied"
        case .healthKitUnavailable:
            return "HealthKit is not available"
        case .workoutSessionFailed:
            return "Workout session failed to start"
        }
    }
}
#endif
