import Foundation
#if os(iOS) || os(watchOS)
@preconcurrency import WatchConnectivity
#endif
@testable import PetTrackerFeature

#if os(iOS) || os(watchOS)
/// Mock WatchConnectivity session for testing triple-path messaging
///
/// Provides full control over WCSession behavior including:
/// - Activation state simulation
/// - Reachability toggling
/// - Message/context/file transfer capture
/// - Delegate callback triggering
/// - Error injection
///
/// ## Usage
/// ```swift
/// let mockSession = MockWCSession()
/// mockSession.activationState = .activated
/// mockSession.isReachable = true
///
/// // Capture sent messages
/// try mockSession.updateApplicationContext(["key": "value"])
/// #expect(mockSession.capturedContextUpdates.count == 1)
/// ```
@MainActor
public final class MockWCSession: WCSession {

    // MARK: - Captured Data

    /// All application context updates sent
    public var capturedContextUpdates: [[String: Any]] = []

    /// All interactive messages sent
    public var capturedMessages: [[String: Any]] = []

    /// Reply handlers for interactive messages
    public var capturedReplyHandlers: [(([String: Any]) -> Void)] = []

    /// Error handlers for interactive messages
    public var capturedErrorHandlers: [((Error) -> Void)] = []

    /// All file transfers initiated
    public var capturedFileTransfers: [(URL, [String: Any]?)] = []

    // MARK: - Controllable State

    /// Current activation state (default: .activated)
    public var mockActivationState: WCSessionActivationState = .activated

    /// Whether counterpart is reachable (default: true)
    public var mockIsReachable: Bool = true

    /// Whether session is supported (default: true)
    public static var mockIsSupported: Bool = true

    /// Error to inject when sending messages
    public var errorToInject: Error?

    /// Simulated delay before triggering activation callback
    public var activationDelay: TimeInterval = 0

    // MARK: - WCSession Overrides

    public override var activationState: WCSessionActivationState {
        return mockActivationState
    }

    public override var isReachable: Bool {
        return mockIsReachable
    }

    public override class var isSupported: Bool {
        return mockIsSupported
    }

    public override class var `default`: WCSession {
        // Cannot override static property, use dependency injection instead
        fatalError("Use dependency injection instead of WCSession.default in tests")
    }

    // MARK: - Message Sending (Captured)

    public override func updateApplicationContext(_ applicationContext: [String: Any]) throws {
        if let error = errorToInject {
            throw error
        }

        capturedContextUpdates.append(applicationContext)
    }

    public override func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        capturedMessages.append(message)

        if let replyHandler = replyHandler {
            capturedReplyHandlers.append(replyHandler)
        }

        if let errorHandler = errorHandler {
            capturedErrorHandlers.append(errorHandler)
        }

        // Simulate immediate response or error
        if let error = errorToInject {
            errorHandler?(error)
        } else {
            replyHandler?(["status": "received"])
        }
    }

    public override func transferFile(_ file: URL, metadata: [String: Any]?) -> WCSessionFileTransfer {
        capturedFileTransfers.append((file, metadata))

        // Return mock file transfer
        // Note: WCSessionFileTransfer cannot be easily mocked, so we return a dummy
        // In real tests, verify capturedFileTransfers instead
        return super.transferFile(file, metadata: metadata)
    }

    // MARK: - Session Lifecycle

    public override func activate() {
        // Simulate activation delay if needed
        if activationDelay > 0 {
            Task {
                try? await Task.sleep(for: .seconds(activationDelay))
                await triggerActivation()
            }
        } else {
            Task {
                await triggerActivation()
            }
        }
    }

    // MARK: - Test Helpers

    /// Triggers activation callback on delegate
    public func triggerActivation(
        state: WCSessionActivationState = .activated,
        error: Error? = nil
    ) {
        mockActivationState = state
        delegate?.session(self, activationDidCompleteWith: state, error: error)
    }

    /// Triggers reachability change callback
    public func triggerReachabilityChange(reachable: Bool) {
        mockIsReachable = reachable
        delegate?.sessionReachabilityDidChange?(self)
    }

    #if os(iOS)
    /// Triggers session inactive callback (iOS only)
    public func triggerSessionInactive() {
        delegate?.sessionDidBecomeInactive?(self)
    }

    /// Triggers session deactivate callback (iOS only)
    public func triggerSessionDeactivate() {
        delegate?.sessionDidDeactivate?(self)
    }
    #endif

    /// Simulates receiving an interactive message
    public func simulateReceiveMessage(_ message: [String: Any]) {
        delegate?.session?(self, didReceiveMessage: message)
    }

    /// Simulates receiving an interactive message with reply handler
    public func simulateReceiveMessageWithReply(
        _ message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        delegate?.session?(self, didReceiveMessage: message, replyHandler: replyHandler)
    }

    /// Simulates receiving application context update
    public func simulateReceiveApplicationContext(_ context: [String: Any]) {
        delegate?.session?(self, didReceiveApplicationContext: context)
    }

    /// Simulates receiving file transfer
    public func simulateReceiveFile(at url: URL, metadata: [String: Any]? = nil) {
        let fileTransfer = WCSessionFile()
        // Note: Cannot easily mock WCSessionFile, use real file in temp directory
        delegate?.session?(self, didReceive: fileTransfer)
    }

    /// Resets all captured data
    public func reset() {
        capturedContextUpdates.removeAll()
        capturedMessages.removeAll()
        capturedReplyHandlers.removeAll()
        capturedErrorHandlers.removeAll()
        capturedFileTransfers.removeAll()
        errorToInject = nil
        activationDelay = 0
        mockActivationState = .activated
        mockIsReachable = true
    }
}

// MARK: - Mock Errors

public enum MockWCSessionError: Error, LocalizedError {
    case notReachable
    case sessionInactive
    case transferFailed

    public var errorDescription: String? {
        switch self {
        case .notReachable:
            return "Watch is not reachable"
        case .sessionInactive:
            return "Session is not active"
        case .transferFailed:
            return "Data transfer failed"
        }
    }
}
#endif
