import Testing
import Foundation
@testable import PetTrackerFeature

/// Comprehensive tests for error handling and user-facing error mapping
///
/// Tests:
/// - UserFacingError mapping from internal errors
/// - Error severity classification
/// - Retry capability detection
/// - Localized error messages
/// - Recovery suggestions
@Suite("Error Handling Tests")
struct ErrorHandlingTests {

    // MARK: - Error Mapping Tests

    @Test("Maps location permission denied error to user-facing error")
    func testLocationPermissionDeniedMapping() async throws {
        // Create a mock error with the expected description pattern
        struct MockLocationError: LocalizedError {
            var errorDescription: String? { "Location permission denied. Please enable location access in Settings." }
        }

        let internalError = MockLocationError()
        let userError = UserFacingError.from(internalError)

        #expect(userError == .locationPermissionDenied)
        #expect(userError.errorDescription == "Location Access Denied")
        #expect(userError.severity == .critical)
        #expect(userError.isRetryable == false)
    }

    @Test("Maps WatchConnectivity not supported error to user-facing error")
    func testWatchNotSupportedMapping() async throws {
        struct MockConnectivityError: LocalizedError {
            var errorDescription: String? { "WatchConnectivity is not supported on this device." }
        }

        let internalError = MockConnectivityError()
        let userError = UserFacingError.from(internalError)

        #expect(userError == .watchConnectivityNotSupported)
        #expect(userError.errorDescription == "Watch Not Supported")
        #expect(userError.severity == .critical)
        #expect(userError.isRetryable == false)
    }

    @Test("Maps session not activated error to user-facing error")
    func testSessionNotActivatedMapping() async throws {
        struct MockSessionError: LocalizedError {
            var errorDescription: String? { "WatchConnectivity session is not activated." }
        }

        let internalError = MockSessionError()
        let userError = UserFacingError.from(internalError)

        #expect(userError == .watchSessionNotActivated)
        #expect(userError.errorDescription == "Watch Not Connected")
        #expect(userError.severity == .warning)
        #expect(userError.isRetryable == true)
    }

    @Test("Maps activation timeout error to user-facing error")
    func testActivationTimeoutMapping() async throws {
        struct MockTimeoutError: LocalizedError {
            var errorDescription: String? { "WatchConnectivity session activation timed out. Try restarting the app." }
        }

        let internalError = MockTimeoutError()
        let userError = UserFacingError.from(internalError)

        #expect(userError == .watchSessionActivationTimeout)
        #expect(userError.errorDescription == "Watch Connection Timeout")
        #expect(userError.severity == .warning)
        #expect(userError.isRetryable == true)
    }

    @Test("Maps DecodingError to locationDecodingFailed")
    func testDecodingErrorMapping() async throws {
        // Create a decoding error
        struct InvalidJSON: Codable {
            let value: Int
        }

        let invalidJSON = "{\"value\": \"not_a_number\"}".data(using: .utf8)!

        do {
            _ = try JSONDecoder().decode(InvalidJSON.self, from: invalidJSON)
            Issue.record("Expected decoding error")
        } catch {
            let userError = UserFacingError.from(error)
            #expect(userError == .locationDecodingFailed)
            #expect(userError.severity == .error)
            #expect(userError.isRetryable == true)
        }
    }

    @Test("Maps unknown error to generic user-facing error")
    func testUnknownErrorMapping() async throws {
        struct CustomError: Error, LocalizedError {
            var errorDescription: String? { "Custom error occurred" }
        }

        let customError = CustomError()
        let userError = UserFacingError.from(customError)

        if case .unknown(let description) = userError {
            #expect(description == "Custom error occurred")
        } else {
            Issue.record("Expected unknown error variant")
        }
    }

    // MARK: - Error Severity Tests

    @Test("Critical errors require user action")
    func testCriticalErrorSeverity() async throws {
        let criticalErrors: [UserFacingError] = [
            .locationPermissionDenied,
            .locationServicesDisabled,
            .watchConnectivityNotSupported
        ]

        for error in criticalErrors {
            #expect(error.severity == .critical)
            #expect(error.isRetryable == false)
        }
    }

    @Test("Warning errors are temporary issues")
    func testWarningErrorSeverity() async throws {
        let warningErrors: [UserFacingError] = [
            .watchSessionNotActivated,
            .watchSessionActivationTimeout,
            .watchNotReachable
        ]

        for error in warningErrors {
            #expect(error.severity == .warning)
            #expect(error.isRetryable == true)
        }
    }

    @Test("Info errors are informational")
    func testInfoErrorSeverity() async throws {
        let infoErrors: [UserFacingError] = [
            .poorGPSAccuracy,
            .staleLocationData(age: 30.0),
            .noLocationData
        ]

        for error in infoErrors {
            #expect(error.severity == .info)
        }
    }

    @Test("Error type severity is retryable when appropriate")
    func testErrorSeverityRetryable() async throws {
        let retryableErrors: [UserFacingError] = [
            .locationUpdateFailed(underlyingError: "Test"),
            .messageSendFailed(underlyingError: "Test"),
            .locationDecodingFailed,
            .unknown(description: "Test")
        ]

        for error in retryableErrors {
            #expect(error.severity == .error)
            #expect(error.isRetryable == true)
        }
    }

    // MARK: - Retry Capability Tests

    @Test("Permission errors are not retryable")
    func testPermissionErrorsNotRetryable() async throws {
        let nonRetryableErrors: [UserFacingError] = [
            .locationPermissionDenied,
            .locationServicesDisabled,
            .watchConnectivityNotSupported
        ]

        for error in nonRetryableErrors {
            #expect(error.isRetryable == false)
        }
    }

    @Test("Connection errors are retryable")
    func testConnectionErrorsRetryable() async throws {
        let retryableErrors: [UserFacingError] = [
            .watchSessionNotActivated,
            .watchSessionActivationTimeout,
            .watchNotReachable,
            .messageSendFailed(underlyingError: "Test")
        ]

        for error in retryableErrors {
            #expect(error.isRetryable == true)
        }
    }

    @Test("Poor GPS accuracy is not retryable programmatically")
    func testPoorGPSNotRetryable() async throws {
        let error = UserFacingError.poorGPSAccuracy
        #expect(error.isRetryable == false)
    }

    // MARK: - Localized Message Tests

    @Test("LocationPermissionDenied has descriptive messages")
    func testLocationPermissionDeniedMessages() async throws {
        let error = UserFacingError.locationPermissionDenied

        #expect(error.errorDescription == "Location Access Denied")
        #expect(error.failureReason?.contains("permission") == true)
        #expect(error.recoverySuggestion?.contains("Settings") == true)
        #expect(error.recoverySuggestion?.contains("Location Services") == true)
    }

    @Test("WatchNotReachable has descriptive messages")
    func testWatchNotReachableMessages() async throws {
        let error = UserFacingError.watchNotReachable

        #expect(error.errorDescription == "Watch Not Reachable")
        #expect(error.failureReason?.contains("out of range") == true)
        #expect(error.recoverySuggestion?.contains("nearby") == true)
        #expect(error.recoverySuggestion?.contains("Bluetooth") == true)
    }

    @Test("StaleLocationData includes age in message")
    func testStaleLocationDataAge() async throws {
        let age: TimeInterval = 120.0
        let error = UserFacingError.staleLocationData(age: age)

        #expect(error.errorDescription == "Outdated Location")
        #expect(error.failureReason?.contains("120") == true)
    }

    @Test("LocationUpdateFailed includes underlying error")
    func testLocationUpdateFailedUnderlyingError() async throws {
        let underlyingMessage = "GPS unavailable"
        let error = UserFacingError.locationUpdateFailed(underlyingError: underlyingMessage)

        #expect(error.errorDescription == "Location Update Failed")
        #expect(error.failureReason?.contains(underlyingMessage) == true)
    }

    @Test("MessageSendFailed includes underlying error")
    func testMessageSendFailedUnderlyingError() async throws {
        let underlyingMessage = "Connection timeout"
        let error = UserFacingError.messageSendFailed(underlyingError: underlyingMessage)

        #expect(error.errorDescription == "Communication Failed")
        #expect(error.failureReason?.contains(underlyingMessage) == true)
    }

    // MARK: - Recovery Suggestion Tests

    @Test("All errors have recovery suggestions")
    func testAllErrorsHaveRecoverySuggestions() async throws {
        let allErrors: [UserFacingError] = [
            .locationPermissionDenied,
            .locationServicesDisabled,
            .poorGPSAccuracy,
            .locationUpdateFailed(underlyingError: "Test"),
            .watchConnectivityNotSupported,
            .watchSessionNotActivated,
            .watchSessionActivationTimeout,
            .watchNotReachable,
            .messageSendFailed(underlyingError: "Test"),
            .locationDecodingFailed,
            .noLocationData,
            .staleLocationData(age: 30),
            .unknown(description: "Test")
        ]

        for error in allErrors {
            #expect(error.recoverySuggestion != nil)
            #expect(error.recoverySuggestion?.isEmpty == false)
        }
    }

    @Test("Settings-related errors suggest opening Settings")
    func testSettingsErrors() async throws {
        let settingsErrors: [UserFacingError] = [
            .locationPermissionDenied,
            .locationServicesDisabled
        ]

        for error in settingsErrors {
            #expect(error.recoverySuggestion?.contains("Settings") == true)
        }
    }

    @Test("Physical errors suggest physical actions")
    func testPhysicalErrors() async throws {
        let physicalErrors: [(error: UserFacingError, keyword: String)] = [
            (.poorGPSAccuracy, "sky"),
            (.watchNotReachable, "nearby"),
            (.staleLocationData(age: 30), "clear view")
        ]

        for (error, keyword) in physicalErrors {
            #expect(error.recoverySuggestion?.lowercased().contains(keyword.lowercased()) == true)
        }
    }

    @Test("Connection errors suggest device actions")
    func testConnectionErrors() async throws {
        let connectionErrors: [UserFacingError] = [
            .watchSessionNotActivated,
            .watchSessionActivationTimeout,
            .watchNotReachable
        ]

        for error in connectionErrors {
            let suggestion = error.recoverySuggestion?.lowercased() ?? ""
            let hasDeviceAction = suggestion.contains("restart") ||
                                 suggestion.contains("bluetooth") ||
                                 suggestion.contains("nearby")
            #expect(hasDeviceAction == true)
        }
    }

    // MARK: - Error Equality Tests

    @Test("Same error types are equal")
    func testErrorEquality() async throws {
        let error1 = UserFacingError.locationPermissionDenied
        let error2 = UserFacingError.locationPermissionDenied

        #expect(error1 == error2)
    }

    @Test("Different error types are not equal")
    func testErrorInequality() async throws {
        let error1 = UserFacingError.locationPermissionDenied
        let error2 = UserFacingError.watchNotReachable

        #expect(error1 != error2)
    }

    @Test("Stale location errors with different ages are not equal")
    func testStaleLocationAgeInequality() async throws {
        let error1 = UserFacingError.staleLocationData(age: 30)
        let error2 = UserFacingError.staleLocationData(age: 60)

        #expect(error1 != error2)
    }

    // MARK: - Severity Color Tests

    @Test("Severity colors are appropriate")
    func testSeverityColors() async throws {
        #expect(UserFacingError.Severity.info.color == "blue")
        #expect(UserFacingError.Severity.warning.color == "orange")
        #expect(UserFacingError.Severity.error.color == "red")
        #expect(UserFacingError.Severity.critical.color == "purple")
    }

    // MARK: - Edge Cases

    @Test("NoLocationData error is informational")
    func testNoLocationDataError() async throws {
        let error = UserFacingError.noLocationData

        #expect(error.severity == .info)
        #expect(error.isRetryable == true)
        #expect(error.recoverySuggestion?.contains("Watch app") == true)
    }

    @Test("LocationDecodingFailed suggests app update")
    func testLocationDecodingFailedSuggestion() async throws {
        let error = UserFacingError.locationDecodingFailed

        #expect(error.recoverySuggestion?.contains("updated") == true)
    }

    @Test("Unknown error has generic recovery suggestion")
    func testUnknownErrorRecovery() async throws {
        let error = UserFacingError.unknown(description: "Something went wrong")

        #expect(error.isRetryable == true)
        #expect(error.recoverySuggestion?.contains("restart") == true)
    }

    // MARK: - Integration Tests

    @Test("Error sequence maps correctly")
    func testErrorSequenceMapping() async throws {
        // Simulate a sequence of errors with various error types
        struct PermissionError: LocalizedError {
            var errorDescription: String? { "Location permission denied." }
        }
        struct NotSupportedError: LocalizedError {
            var errorDescription: String? { "WatchConnectivity is not supported." }
        }
        struct NotActivatedError: LocalizedError {
            var errorDescription: String? { "Session is not activated." }
        }

        let errors: [(any Error, UserFacingError)] = [
            (PermissionError(), .locationPermissionDenied),
            (NotSupportedError(), .watchConnectivityNotSupported),
            (NotActivatedError(), .watchSessionNotActivated)
        ]

        for (internalError, expectedUserError) in errors {
            let mappedError = UserFacingError.from(internalError)
            #expect(mappedError == expectedUserError)
        }
    }

    @Test("All error descriptions are user-friendly")
    func testUserFriendlyDescriptions() async throws {
        let allErrors: [UserFacingError] = [
            .locationPermissionDenied,
            .locationServicesDisabled,
            .poorGPSAccuracy,
            .locationUpdateFailed(underlyingError: "Test"),
            .watchConnectivityNotSupported,
            .watchSessionNotActivated,
            .watchSessionActivationTimeout,
            .watchNotReachable,
            .messageSendFailed(underlyingError: "Test"),
            .locationDecodingFailed,
            .noLocationData,
            .staleLocationData(age: 30),
            .unknown(description: "Test")
        ]

        for error in allErrors {
            let description = error.errorDescription ?? ""
            // Check description is not empty
            #expect(description.isEmpty == false)
            // Check description doesn't contain technical jargon
            #expect(description.contains("NSError") == false)
            #expect(description.contains("Exception") == false)
            // Check first letter is capitalized
            #expect(description.first?.isUppercase == true)
        }
    }
}
