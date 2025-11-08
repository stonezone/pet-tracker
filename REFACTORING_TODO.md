# PetTracker Refactoring TODO - Generated 2025-11-07

**Status**: 🚧 Active Retrofit in Progress
**Compliance Score**: 72/100 → Target: 95/100
**Mode**: Conservative → Aggressive (Phased Approach)
**Repository**: https://github.com/stonezone/pet-tracker

---

## 📋 Table of Contents

1. [Priority 1: Critical Fixes](#priority-1-critical-fixes-do-first)
2. [Priority 2: Logging Strategy](#priority-2-logging-strategy)
3. [Priority 3: Test Coverage](#priority-3-test-coverage)
4. [Priority 4: Error Handling & UX](#priority-4-error-handling--ux)
5. [Priority 5: CI/CD & Automation](#priority-5-cicd--automation)
6. [Automation Scripts](#automation-scripts)
7. [Verification Checklist](#verification-checklist)

---

## Priority 1: Critical Fixes (Do First)

### 1.1 Fix iOS App Initialization Crash ❗ BLOCKING

**Issue**: iOS app not logging/starting on physical devices, shows spinny wheel
**Impact**: Critical - App unusable on physical hardware
**Effort**: 4-6 hours
**Status**: ⏳ Pending

**Current Evidence**:
```
# Console shows:
- No "PetTrackerApp: iOS app starting..." log
- No "PetLocationManager: Initializing..." log
- Watch app logs appear but iOS app silent
- Possible crash during init() before logging starts
```

**Root Cause Hypotheses**:
1. WCSession activation blocking main thread
2. CLLocationManager initialization failure
3. Missing entitlements on physical device
4. SwiftUI initialization order issue

**Action Items**:

- [ ] **Step 1.1.1**: Add crash reporting
  ```swift
  // Add to PetTrackerPackage/Sources/PetTrackerFeature/Utilities/CrashReporter.swift
  import OSLog

  public enum CrashReporter {
      private static let logger = Logger(subsystem: "com.pettracker", category: "crash")

      public static func initialize() {
          logger.info("CrashReporter initialized")
          NSSetUncaughtExceptionHandler { exception in
              logger.fault("Uncaught exception: \(exception)")
          }
      }

      public static func log(_ message: String, level: OSLogType = .error) {
          logger.log(level: level, "\(message)")
      }
  }
  ```

- [ ] **Step 1.1.2**: Update PetTrackerApp.swift with early logging
  ```swift
  @main
  struct PetTrackerApp: App {
      init() {
          // FIRST THING: Initialize crash reporting
          CrashReporter.initialize()
          CrashReporter.log("PetTrackerApp: iOS app starting...", level: .info)

          // Wrap manager creation in error handling
          do {
              let manager = PetLocationManager()
              _locationManager = State(initialValue: manager)
              CrashReporter.log("PetTrackerApp: Location manager created successfully", level: .info)
          } catch {
              CrashReporter.log("PetTrackerApp: FATAL - Failed to create location manager: \(error)", level: .fault)
              fatalError("Failed to initialize location manager: \(error)")
          }
      }
  }
  ```

- [ ] **Step 1.1.3**: Add timeout protection to WCSession activation
  ```swift
  // In PetLocationManager.swift setupWatchConnectivity()
  private func setupWatchConnectivity() {
      guard WCSession.isSupported() else {
          lastError = WatchConnectivityError.notSupported
          Logger.connectivity.error("WatchConnectivity not supported")
          return
      }

      session.delegate = self

      // Activate on background queue to avoid blocking main thread
      Task.detached {
          Logger.connectivity.info("Activating WCSession...")
          await MainActor.run {
              self.session.activate()
          }

          // Wait up to 5 seconds for activation
          let timeout = Date().addingTimeInterval(5.0)
          while self.session.activationState != .activated && Date() < timeout {
              try? await Task.sleep(for: .milliseconds(100))
          }

          await MainActor.run {
              if self.session.activationState == .activated {
                  Logger.connectivity.info("WCSession activated successfully")
              } else {
                  Logger.connectivity.error("WCSession activation timeout")
                  self.lastError = WatchConnectivityError.sessionNotActivated
              }
          }
      }
  }
  ```

- [ ] **Step 1.1.4**: Verify entitlements on physical device
  ```bash
  # Check Info.plist has required keys
  plutil -p PetTracker/Info.plist | grep -i location
  plutil -p PetTracker/Info.plist | grep -i background

  # Check entitlements file
  cat PetTracker/PetTracker.entitlements

  # Should include:
  # - com.apple.developer.healthkit
  # - com.apple.developer.healthkit.background-delivery
  # - App Groups for WatchConnectivity
  ```

- [ ] **Step 1.1.5**: Add iOS app Info.plist entries
  ```xml
  <!-- Add to PetTracker/Info.plist -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>PetTracker needs location access to show your distance from your pet.</string>

  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>PetTracker needs continuous location access to track distance from your pet.</string>

  <key>UIBackgroundModes</key>
  <array>
      <string>location</string>
      <string>fetch</string>
  </array>
  ```

- [ ] **Step 1.1.6**: Test on physical device
  ```bash
  # Build for physical device
  xcodebuild -workspace PetTracker.xcworkspace \
    -scheme PetTracker \
    -destination 'platform=iOS,name=YOUR_DEVICE_NAME' \
    clean build

  # Install and monitor logs
  xcrun devicectl device install app --device YOUR_DEVICE_ID PetTracker.app
  xcrun devicectl device info crashlogs --device YOUR_DEVICE_ID
  ```

**Success Criteria**:
- ✅ See "PetTrackerApp: iOS app starting..." in console
- ✅ See "PetLocationManager: Initializing..." in console
- ✅ See "WCSession activated successfully" in console
- ✅ No crash logs in Settings > Privacy > Analytics
- ✅ iOS app launches without spinny wheel

**Commit After**: Fix iOS crash on physical devices

---

## Priority 2: Logging Strategy

### 2.1 Replace print() with OSLog ⚠️ HIGH

**Issue**: 30+ print() statements polluting production logs
**Impact**: Medium - Performance hit, no log levels, hard to filter
**Effort**: 2-3 hours
**Status**: ⏳ Pending

**Current State**:
```bash
# Count print statements
grep -r "print(" --include="*.swift" PetTrackerPackage/Sources/ | wc -l
# Result: 30+
```

**Action Items**:

- [ ] **Step 2.1.1**: Create Logger extensions
  ```swift
  // Create PetTrackerPackage/Sources/PetTrackerFeature/Utilities/Logging.swift
  import OSLog

  extension Logger {
      /// Watch location and GPS tracking
      static let watchLocation = Logger(subsystem: "com.pettracker", category: "watch-location")

      /// WatchConnectivity session and messaging
      static let connectivity = Logger(subsystem: "com.pettracker", category: "connectivity")

      /// iOS location tracking
      static let iOSLocation = Logger(subsystem: "com.pettracker", category: "ios-location")

      /// HealthKit workout sessions
      static let healthKit = Logger(subsystem: "com.pettracker", category: "healthkit")

      /// UI and view lifecycle
      static let ui = Logger(subsystem: "com.pettracker", category: "ui")
  }
  ```

- [ ] **Step 2.1.2**: Replace print() in WatchLocationProvider.swift
  ```swift
  // Find all print() statements:
  grep -n "print(" PetTrackerPackage/Sources/PetTrackerFeature/Services/WatchLocationProvider.swift

  // Replace patterns:
  // print("WatchLocationProvider: Starting tracking...")
  // → Logger.watchLocation.info("Starting tracking")

  // print("WatchLocationProvider: Session activated with state: \(state)")
  // → Logger.connectivity.info("Session activated", metadata: ["state": "\(state)"])

  // print("WatchLocationProvider: Error: \(error)")
  // → Logger.watchLocation.error("Tracking error: \(error.localizedDescription)")
  ```

- [ ] **Step 2.1.3**: Replace print() in PetLocationManager.swift
  ```swift
  // Find all print() statements:
  grep -n "print(" PetTrackerPackage/Sources/PetTrackerFeature/Services/PetLocationManager.swift

  // Replace patterns:
  // print("PetLocationManager: Starting tracking...")
  // → Logger.iOSLocation.info("Starting tracking")

  // print("PetLocationManager: Received location fix #\(seq)")
  // → Logger.connectivity.debug("Received location fix", metadata: ["sequence": "\(seq)"])
  ```

- [ ] **Step 2.1.4**: Replace print() in UI files
  ```swift
  // ContentView.swift, PetTrackerApp.swift
  // print("ContentView: onAppear called")
  // → Logger.ui.debug("ContentView appeared")
  ```

- [ ] **Step 2.1.5**: Add log filtering documentation
  ```markdown
  # Create docs/logging.md

  ## Viewing Logs

  ### In Console.app
  1. Open Console.app
  2. Select your device
  3. Filter by subsystem: `subsystem:com.pettracker`
  4. Filter by category: `category:connectivity`

  ### In Xcode
  1. Run app with debugger
  2. Console filter: `subsystem == "com.pettracker"`

  ### Log Levels
  - `.debug`: Verbose tracking (GPS updates, message sends)
  - `.info`: Important milestones (session activation, tracking start/stop)
  - `.error`: Recoverable errors (message timeouts, permission denials)
  - `.fault`: Critical errors (crashes, fatal failures)

  ### Common Queries
  ```bash
  # All connectivity logs
  log show --predicate 'subsystem == "com.pettracker" AND category == "connectivity"'

  # Only errors and faults
  log show --predicate 'subsystem == "com.pettracker" AND eventType >= logEventError'
  ```
  ```

- [ ] **Step 2.1.6**: Remove all print() statements
  ```bash
  # Verify no print() remain in production code (excluding tests)
  grep -r "print(" --include="*.swift" --exclude-dir="Tests" PetTrackerPackage/Sources/
  # Should return 0 results
  ```

**Success Criteria**:
- ✅ Zero print() statements in production code
- ✅ All logs use appropriate Logger categories
- ✅ Logs filterable by subsystem and category
- ✅ Performance improvement (no string interpolation unless logged)

**Commit After**: Replace print() with structured OSLog logging

---

## Priority 3: Test Coverage

### 3.1 Add Unit Tests for LocationFix 🧪

**Issue**: 0% test coverage for domain model
**Target**: 100% coverage (pure logic, no mocking needed)
**Effort**: 2-3 hours
**Status**: ⏳ Pending

**Action Items**:

- [ ] **Step 3.1.1**: Create test file
  ```swift
  // Create PetTrackerPackage/Tests/PetTrackerFeatureTests/LocationFixTests.swift
  import Testing
  import Foundation
  @testable import PetTrackerFeature

  @Suite("LocationFix Tests")
  struct LocationFixTests {
      // Test suite structure
  }
  ```

- [ ] **Step 3.1.2**: Test Codable conformance
  ```swift
  @Test("LocationFix encodes and decodes correctly")
  func testLocationFixCodable() async throws {
      let fix = LocationFix(
          timestamp: Date(),
          source: .watchOS,
          coordinate: .init(latitude: 37.7749, longitude: -122.4194),
          altitudeMeters: 10.0,
          horizontalAccuracyMeters: 5.0,
          verticalAccuracyMeters: 10.0,
          speedMetersPerSecond: 1.5,
          courseDegrees: 180.0,
          headingDegrees: nil,
          batteryFraction: 0.85,
          sequence: 42
      )

      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let encoded = try encoder.encode(fix)

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let decoded = try decoder.decode(LocationFix.self, from: encoded)

      #expect(decoded.sequence == fix.sequence)
      #expect(decoded.coordinate.latitude == fix.coordinate.latitude)
      #expect(decoded.coordinate.longitude == fix.coordinate.longitude)
      #expect(decoded.batteryFraction == fix.batteryFraction)
  }
  ```

- [ ] **Step 3.1.3**: Test Sendable conformance
  ```swift
  @Test("LocationFix is Sendable")
  func testLocationFixSendable() async throws {
      let fix = LocationFix(/* ... */)

      // Should compile without warnings
      Task {
          let _ = fix // Can safely capture in Task
      }

      await Task {
          let _ = fix // Can safely send across actor boundaries
      }.value
  }
  ```

- [ ] **Step 3.1.4**: Test age calculation
  ```swift
  @Test("LocationFix calculates age correctly")
  func testLocationAge() async throws {
      let pastDate = Date().addingTimeInterval(-30.0)
      let fix = LocationFix(timestamp: pastDate, /* ... */)

      let age = fix.age
      #expect(age >= 30.0)
      #expect(age < 31.0) // Allow 1 second tolerance
  }
  ```

- [ ] **Step 3.1.5**: Test battery percentage
  ```swift
  @Test("LocationFix converts battery fraction to percentage")
  func testBatteryPercentage() async throws {
      let fix = LocationFix(batteryFraction: 0.75, /* ... */)
      #expect(fix.batteryPercentage == 75)
  }
  ```

- [ ] **Step 3.1.6**: Test CLLocation conversion
  ```swift
  @Test("LocationFix converts to CLLocation")
  func testCLLocationConversion() async throws {
      let fix = LocationFix(/* ... */)
      let clLocation = fix.clLocation

      #expect(clLocation.coordinate.latitude == fix.coordinate.latitude)
      #expect(clLocation.coordinate.longitude == fix.coordinate.longitude)
      #expect(clLocation.altitude == fix.altitudeMeters)
      #expect(clLocation.horizontalAccuracy == fix.horizontalAccuracyMeters)
  }
  ```

- [ ] **Step 3.1.7**: Run tests
  ```bash
  swift test --filter LocationFixTests
  swift test --enable-code-coverage

  # Generate coverage report
  xcrun llvm-cov show \
    .build/debug/PetTrackerFeaturePackageTests.xctest/Contents/MacOS/PetTrackerFeaturePackageTests \
    -instr-profile .build/debug/codecov/default.profdata \
    > coverage.txt
  ```

**Success Criteria**:
- ✅ All LocationFix tests pass
- ✅ 100% code coverage for LocationFix.swift
- ✅ Tests run in <1 second

**Commit After**: Add unit tests for LocationFix domain model

---

### 3.2 Add Unit Tests for PetLocationManager 🧪

**Issue**: 0% test coverage for iOS location coordinator
**Target**: 90% coverage (mock WCSession and CLLocationManager)
**Effort**: 4-6 hours
**Status**: ⏳ Pending

**Action Items**:

- [ ] **Step 3.2.1**: Create mock WCSession
  ```swift
  // Create PetTrackerPackage/Tests/PetTrackerFeatureTests/Mocks/MockWCSession.swift
  import WatchConnectivity

  @MainActor
  class MockWCSession: WCSession {
      var mockActivationState: WCSessionActivationState = .notActivated
      var mockIsReachable: Bool = false
      var mockIsPaired: Bool = true
      var mockIsWatchAppInstalled: Bool = true

      var activatedCalled = false
      var sentMessages: [[String: Any]] = []
      var sentContexts: [[String: Any]] = []

      override var activationState: WCSessionActivationState {
          mockActivationState
      }

      override var isReachable: Bool {
          mockIsReachable
      }

      override func activate() {
          activatedCalled = true
          mockActivationState = .activated
      }

      override func sendMessage(_ message: [String : Any], replyHandler: (([String : Any]) -> Void)?, errorHandler: ((any Error) -> Void)? = nil) {
          sentMessages.append(message)
          replyHandler?(["status": "ok"])
      }

      override func updateApplicationContext(_ applicationContext: [String : Any]) throws {
          sentContexts.append(applicationContext)
      }
  }
  ```

- [ ] **Step 3.2.2**: Test WCSession activation
  ```swift
  @Test("PetLocationManager activates WCSession on init")
  @MainActor
  func testWCSessionActivation() async throws {
      let mockSession = MockWCSession()
      let manager = PetLocationManager(session: mockSession)

      try await Task.sleep(for: .milliseconds(100))
      #expect(mockSession.activatedCalled == true)
  }
  ```

- [ ] **Step 3.2.3**: Test message reception
  ```swift
  @Test("PetLocationManager receives and decodes location fixes")
  @MainActor
  func testReceiveLocationFix() async throws {
      let manager = PetLocationManager()

      let fix = LocationFix(/* ... */)
      let encoder = JSONEncoder()
      let jsonData = try encoder.encode(fix)
      let message = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

      // Simulate receiving message
      manager.session(manager.session, didReceiveMessage: message)

      try await Task.sleep(for: .milliseconds(100))
      #expect(manager.latestPetLocation != nil)
      #expect(manager.latestPetLocation?.sequence == fix.sequence)
  }
  ```

- [ ] **Step 3.2.4**: Test location history management
  ```swift
  @Test("PetLocationManager maintains location history")
  @MainActor
  func testLocationHistory() async throws {
      let manager = PetLocationManager()

      // Send 105 location fixes (max is 100)
      for i in 1...105 {
          let fix = LocationFix(sequence: i, /* ... */)
          let message = try encodeToMessage(fix)
          manager.session(manager.session, didReceiveMessage: message)
      }

      try await Task.sleep(for: .milliseconds(500))

      #expect(manager.locationHistory.count == 100)
      #expect(manager.locationHistory.first?.sequence == 6) // Oldest kept
      #expect(manager.locationHistory.last?.sequence == 105) // Latest
  }
  ```

- [ ] **Step 3.2.5**: Test distance calculation
  ```swift
  @Test("PetLocationManager calculates distance correctly")
  @MainActor
  func testDistanceCalculation() async throws {
      let manager = PetLocationManager()

      // Set owner location (San Francisco)
      let ownerLoc = CLLocation(latitude: 37.7749, longitude: -122.4194)
      manager.ownerLocation = ownerLoc

      // Set pet location (1km away)
      let petFix = LocationFix(
          coordinate: .init(latitude: 37.7839, longitude: -122.4194)
          /* ... */
      )
      manager.latestPetLocation = petFix

      let distance = manager.distanceFromOwner
      #expect(distance != nil)
      #expect(distance! > 900.0) // ~1km
      #expect(distance! < 1100.0)
  }
  ```

**Success Criteria**:
- ✅ All PetLocationManager tests pass
- ✅ >90% code coverage
- ✅ Tests run in <5 seconds

**Commit After**: Add unit tests for PetLocationManager

---

### 3.3 Add Unit Tests for WatchLocationProvider 🧪

**Issue**: 0% test coverage for Watch GPS provider
**Target**: 90% coverage (mock CLLocationManager, HKHealthStore, WCSession)
**Effort**: 6-8 hours
**Status**: ⏳ Pending

**Action Items**:

- [ ] **Step 3.3.1**: Create mock CLLocationManager
  ```swift
  @MainActor
  class MockCLLocationManager: CLLocationManager {
      var mockAuthorizationStatus: CLAuthorizationStatus = .authorizedAlways
      var startUpdatingLocationCalled = false
      var stopUpdatingLocationCalled = false
      var mockLocations: [CLLocation] = []

      override var authorizationStatus: CLAuthorizationStatus {
          mockAuthorizationStatus
      }

      override func startUpdatingLocation() {
          startUpdatingLocationCalled = true
      }

      override func stopUpdatingLocation() {
          stopUpdatingLocationCalled = true
      }

      func simulateLocationUpdate(_ location: CLLocation) {
          delegate?.locationManager?(self, didUpdateLocations: [location])
      }
  }
  ```

- [ ] **Step 3.3.2**: Create mock HKHealthStore
  ```swift
  class MockHKHealthStore: HKHealthStore {
      var authorizationRequested = false
      var mockAuthorizationGranted = true

      override func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?) async throws {
          authorizationRequested = true
          if !mockAuthorizationGranted {
              throw NSError(domain: "HKError", code: 5, userInfo: nil)
          }
      }
  }
  ```

- [ ] **Step 3.3.3**: Test GPS tracking lifecycle
  ```swift
  @Test("WatchLocationProvider starts and stops tracking")
  @MainActor
  func testTrackingLifecycle() async throws {
      let mockLocationManager = MockCLLocationManager()
      let provider = WatchLocationProvider(locationManager: mockLocationManager)

      await provider.startTracking()
      #expect(provider.isTracking == true)
      #expect(mockLocationManager.startUpdatingLocationCalled == true)

      await provider.stopTracking()
      #expect(provider.isTracking == false)
      #expect(mockLocationManager.stopUpdatingLocationCalled == true)
  }
  ```

- [ ] **Step 3.3.4**: Test triple-path messaging
  ```swift
  @Test("WatchLocationProvider sends via all three paths when reachable")
  @MainActor
  func testTriplePathMessaging() async throws {
      let mockSession = MockWCSession()
      mockSession.mockIsReachable = true

      let provider = WatchLocationProvider(session: mockSession)
      await provider.startTracking()

      // Simulate location update
      let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
      provider.simulateLocationUpdate(location)

      try await Task.sleep(for: .milliseconds(100))

      // Should send via interactive message AND application context
      #expect(mockSession.sentMessages.count > 0)
      #expect(mockSession.sentContexts.count > 0)
  }
  ```

- [ ] **Step 3.3.5**: Test session activation guard
  ```swift
  @Test("WatchLocationProvider doesn't send before session activated")
  @MainActor
  func testSessionActivationGuard() async throws {
      let mockSession = MockWCSession()
      mockSession.mockActivationState = .notActivated

      let provider = WatchLocationProvider(session: mockSession)
      await provider.startTracking()

      let location = CLLocation(/* ... */)
      provider.simulateLocationUpdate(location)

      try await Task.sleep(for: .milliseconds(100))

      // Should not send any messages
      #expect(mockSession.sentMessages.count == 0)
      #expect(mockSession.sentContexts.count == 0)
  }
  ```

**Success Criteria**:
- ✅ All WatchLocationProvider tests pass
- ✅ >90% code coverage
- ✅ Tests run in <10 seconds

**Commit After**: Add unit tests for WatchLocationProvider

---

## Priority 4: Error Handling & UX

### 4.1 Surface Errors to UI 🎨

**Issue**: Errors stored in lastError but never shown to user
**Impact**: Medium - Poor UX, users don't know what's wrong
**Effort**: 3-4 hours
**Status**: ⏳ Pending

**Action Items**:

- [ ] **Step 4.1.1**: Create error alert view modifier
  ```swift
  // Create PetTrackerPackage/Sources/PetTrackerFeature/Views/ErrorAlertModifier.swift
  import SwiftUI

  struct ErrorAlertModifier: ViewModifier {
      @Binding var error: Error?
      let retry: (() async -> Void)?

      func body(content: Content) -> some View {
          content
              .alert("Error", isPresented: .constant(error != nil)) {
                  if let retry = retry {
                      Button("Retry") {
                          Task {
                              await retry()
                          }
                      }
                  }
                  Button("Dismiss", role: .cancel) {
                      error = nil
                  }
              } message: {
                  if let error = error {
                      Text(error.localizedDescription)
                  }
              }
      }
  }

  extension View {
      func errorAlert(error: Binding<Error?>, retry: (() async -> Void)? = nil) -> some View {
          modifier(ErrorAlertModifier(error: error, retry: retry))
      }
  }
  ```

- [ ] **Step 4.1.2**: Update ContentView to show errors
  ```swift
  // Update PetTracker/ContentView.swift
  var body: some View {
      NavigationStack {
          VStack { /* ... */ }
      }
      .errorAlert(error: $locationManager.lastError) {
          await locationManager.startTracking()
      }
  }
  ```

- [ ] **Step 4.1.3**: Create user-friendly error messages
  ```swift
  // Update error types to provide better descriptions
  extension PetLocationManager.LocationError {
      public var errorDescription: String? {
          switch self {
          case .permissionDenied:
              return "Location access denied. Please enable in Settings > Privacy > Location Services."
          }
      }

      public var recoverySuggestion: String? {
          switch self {
          case .permissionDenied:
              return "Tap Settings to enable location access."
          }
      }
  }
  ```

**Success Criteria**:
- ✅ All errors show user-friendly alerts
- ✅ Retry button available for transient failures
- ✅ Deep link to Settings when appropriate

**Commit After**: Surface errors to UI with retry mechanisms

---

## Priority 5: CI/CD & Automation

### 5.1 Add Pre-commit Hooks ⚙️

**Issue**: No automated quality checks before commits
**Impact**: Low - Manual quality gates are error-prone
**Effort**: 2 hours
**Status**: ⏳ Pending

**Action Items**:

- [ ] **Step 5.1.1**: Create quality check script
  ```bash
  # Create scripts/quality-check.sh
  #!/bin/bash
  set -e

  echo "🔍 Running quality checks..."

  # 1. Swift format check
  echo "📝 Checking code formatting..."
  if command -v swift-format &> /dev/null; then
      swift-format lint --recursive Sources/
  else
      echo "⚠️ swift-format not installed, skipping"
  fi

  # 2. Run tests
  echo "🧪 Running tests..."
  swift test

  # 3. Check for TODOs in production code
  echo "📋 Checking for TODOs..."
  TODO_COUNT=$(grep -r "TODO\|FIXME" --include="*.swift" --exclude-dir=Tests Sources/ | wc -l)
  if [ "$TODO_COUNT" -gt 0 ]; then
      echo "⚠️ Found $TODO_COUNT TODOs/FIXMEs in production code"
      grep -r "TODO\|FIXME" --include="*.swift" --exclude-dir=Tests Sources/
      exit 1
  fi

  # 4. Check for print() statements
  echo "📢 Checking for print() statements..."
  PRINT_COUNT=$(grep -r "print(" --include="*.swift" --exclude-dir=Tests Sources/ | wc -l)
  if [ "$PRINT_COUNT" -gt 0 ]; then
      echo "⚠️ Found $PRINT_COUNT print() statements in production code"
      grep -r "print(" --include="*.swift" --exclude-dir=Tests Sources/
      exit 1
  fi

  echo "✅ All quality checks passed!"
  ```

- [ ] **Step 5.1.2**: Make script executable
  ```bash
  chmod +x scripts/quality-check.sh
  ```

- [ ] **Step 5.1.3**: Create git pre-commit hook
  ```bash
  # Create .git/hooks/pre-commit
  #!/bin/bash
  ./scripts/quality-check.sh
  ```

- [ ] **Step 5.1.4**: Create GitHub Actions workflow
  ```yaml
  # Create .github/workflows/test.yml
  name: Test

  on:
    push:
      branches: [ master, main ]
    pull_request:
      branches: [ master, main ]

  jobs:
    test:
      runs-on: macos-latest

      steps:
      - uses: actions/checkout@v4

      - name: Setup Swift
        uses: swift-actions/setup-swift@v2
        with:
          swift-version: '6.2'

      - name: Build
        run: swift build -v

      - name: Run tests
        run: swift test --enable-code-coverage

      - name: Check coverage
        run: |
          swift test --enable-code-coverage
          # TODO: Add coverage threshold check

      - name: Lint
        run: |
          if command -v swift-format &> /dev/null; then
            swift-format lint --recursive Sources/
          fi
  ```

**Success Criteria**:
- ✅ Pre-commit hook prevents commits with TODOs or print()
- ✅ GitHub Actions runs on every push
- ✅ Tests must pass before merge

**Commit After**: Add CI/CD pipeline with quality gates

---

## Automation Scripts

### Build and Test
```bash
#!/bin/bash
# scripts/build.sh

echo "🏗️ Building PetTracker..."

# Clean build
xcodebuild -workspace PetTracker.xcworkspace \
  -scheme PetTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  clean build

xcodebuild -workspace PetTracker.xcworkspace \
  -scheme "PetTracker Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' \
  clean build

echo "✅ Build complete"
```

### Run All Tests
```bash
#!/bin/bash
# scripts/test.sh

echo "🧪 Running all tests..."

cd PetTrackerPackage
swift test --enable-code-coverage --parallel

echo "📊 Generating coverage report..."
swift test --enable-code-coverage

echo "✅ Tests complete"
```

### Deploy to TestFlight
```bash
#!/bin/bash
# scripts/deploy-testflight.sh

echo "🚀 Deploying to TestFlight..."

# Archive iOS app
xcodebuild -workspace PetTracker.xcworkspace \
  -scheme PetTracker \
  -archivePath build/PetTracker.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/PetTracker.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# Upload to TestFlight
xcrun altool --upload-app \
  --type ios \
  --file build/export/PetTracker.ipa \
  --username "your@email.com" \
  --password "@keychain:AC_PASSWORD"

echo "✅ Deployed to TestFlight"
```

---

## Verification Checklist

After each phase:

### After Priority 1 (Critical Fixes)
- [ ] iOS app launches on physical device without crash
- [ ] Console shows initialization logs
- [ ] WCSession activates within 5 seconds
- [ ] No spinny wheel on launch
- [ ] Crash logs empty

### After Priority 2 (Logging)
- [ ] Zero print() statements in production code
- [ ] All logs use OSLog with categories
- [ ] Logs filterable in Console.app
- [ ] No performance regression

### After Priority 3 (Tests)
- [ ] LocationFix: 100% coverage
- [ ] PetLocationManager: >90% coverage
- [ ] WatchLocationProvider: >90% coverage
- [ ] All tests pass in <30 seconds
- [ ] Tests run in CI/CD

### After Priority 4 (Error Handling)
- [ ] Errors show user-friendly alerts
- [ ] Retry button works for transient failures
- [ ] Deep links to Settings work

### After Priority 5 (CI/CD)
- [ ] Pre-commit hook prevents bad commits
- [ ] GitHub Actions runs on push
- [ ] Tests pass in CI before merge

---

## Estimated Timeline

| Phase | Duration | Start After |
|-------|----------|-------------|
| **Priority 1**: Critical Fixes | 1 day | Immediately |
| **Priority 2**: Logging | 0.5 days | Priority 1 ✅ |
| **Priority 3**: Tests | 3 days | Priority 2 ✅ |
| **Priority 4**: Error Handling | 1 day | Priority 3 ✅ (can overlap) |
| **Priority 5**: CI/CD | 0.5 days | Priority 4 ✅ |

**Total**: ~6 days (1.2 weeks)

---

## Git Commit Strategy

Commit after each major milestone:

```bash
# After Priority 1.1
git add -A && git commit -m "fix: iOS app initialization crash on physical devices

- Add crash reporting with OSLog
- Add timeout protection to WCSession activation
- Verify entitlements and Info.plist entries
- Test on physical device

Fixes #1"

# After Priority 2.1
git add -A && git commit -m "refactor: replace print() with structured OSLog logging

- Create Logger extensions for all subsystems
- Replace 30+ print() statements
- Add log filtering documentation
- Improve performance by removing string interpolation

Closes #2"

# After Priority 3.1
git add -A && git commit -m "test: add unit tests for LocationFix domain model

- Test Codable conformance
- Test Sendable conformance
- Test age calculation
- Test battery percentage conversion
- Achieve 100% coverage

Closes #3"

# Continue for each phase...
```

---

## Context Monitoring

**Use `/context7` and `/vibe_check` throughout**:

### Context7 Checkpoints
- After Priority 1: Check architectural compliance
- After Priority 2: Verify logging doesn't break concurrency
- After Priority 3: Ensure tests follow project patterns
- After Priority 4: Verify error handling doesn't violate Clean Architecture
- After Priority 5: Confirm CI/CD aligns with project goals

### Vibe Check Points
- Before starting aggressive mode: Confirm approach
- After each major refactor: Ensure code quality maintained
- After all tests added: Verify coverage meets standards
- Before final commit: Confirm all TODOs resolved

---

## STOP Conditions

**STOP IMMEDIATELY** if:
- ❌ Any test fails after refactoring
- ❌ Build fails after changes
- ❌ Coverage drops below baseline
- ❌ New TODOs or FIXMEs introduced
- ❌ print() statements added
- ❌ Force unwrapping introduced
- ❌ Architectural boundaries violated
- ❌ Concurrency warnings appear

**Wait for user approval before proceeding.**

---

**Generated**: 2025-11-07
**Mode**: Conservative → Aggressive (Phased)
**Repository**: https://github.com/stonezone/pet-tracker
**Next**: Execute Phase 1 with multiple agents
