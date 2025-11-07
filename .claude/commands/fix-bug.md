---
description: TDD approach to bug fixes (failing test → fix → regression test)
tags: [project, gitignored]
---

You are a bug fix specialist following Test-Driven Development for regression prevention.

## Bug Fix Workflow (TDD Approach)

### Step 1: Reproduce the Bug

Ask the user:

1. **What is the expected behavior?**
2. **What is the actual behavior?**
3. **Steps to reproduce?**
4. **Is there an error message or crash log?**
5. **Which version/build?**

### Step 2: Write Failing Test

**BEFORE fixing the bug**, create a test that demonstrates the failure:

```swift
import Testing
@testable import pawWatchFeature

@Suite("Bug Fix: WatchConnectivity timeout on background")
struct WatchConnectivityTimeoutBugTests {

    @Test("Issue #42: Application context should retry on failure")
    func testApplicationContextRetriesOnFailure() async throws {
        let provider = WatchLocationProvider()
        let fix = LocationFix.sample() // Test fixture

        // Simulate failure scenario
        provider.simulateNetworkFailure = true

        // Attempt to send
        await provider.sendLocation(fix)

        // Expected: Should fall back to file transfer
        #expect(provider.lastTransferMethod == .fileTransfer)
        #expect(provider.messageQueue.isEmpty == false)
    }
}
```

**Run the test** - it should FAIL:

```bash
swift test --filter WatchConnectivityTimeoutBugTests
```

### Step 3: Investigate Root Cause

Use debugging tools to find the issue:

```swift
// Add logging
print("🐛 [DEBUG] Attempting to send via context: \(fix)")
print("🐛 [DEBUG] Session reachable: \(session.isReachable)")
print("🐛 [DEBUG] Last error: \(lastError?.localizedDescription ?? "none")")

// Add breakpoints
// Set breakpoint in Xcode at suspected failure point

// Check assumptions
assert(session.isActivated, "WCSession not activated")
assert(fix.isValid, "LocationFix invalid")
```

Common root causes:
- Missing nil check
- Off-by-one error
- Race condition
- Incorrect error handling
- Logic inversion
- Type mismatch

### Step 4: Fix the Bug

Apply minimal fix that makes the test pass:

```swift
// BEFORE (Bug):
func sendLocationViaContext(_ fix: LocationFix) async {
    do {
        try session.updateApplicationContext(fix.jsonDict)
    } catch {
        // BUG: Silent failure, no fallback
        print("Error: \(error)")
    }
}

// AFTER (Fixed):
func sendLocationViaContext(_ fix: LocationFix) async {
    do {
        try session.updateApplicationContext(fix.jsonDict)
    } catch {
        print("Application context failed: \(error), falling back to file transfer")
        // FIX: Fall back to guaranteed delivery
        await sendLocationViaFile(fix)
    }
}
```

**Key Principles**:
- Make the MINIMAL change needed
- Don't refactor while fixing (refactor separately)
- Add defensive checks if missing
- Preserve existing behavior (regression prevention)

### Step 5: Verify Test Passes

Run the test again:

```bash
swift test --filter WatchConnectivityTimeoutBugTests
```

**Expected**: Test should now PASS.

### Step 6: Run Full Test Suite

Ensure the fix doesn't break anything else:

```bash
swift test
```

**Expected**: All tests pass.

If any tests fail:
- Analyze why (is the fix too broad?)
- Adjust fix or update tests (if expectations changed)
- Re-run until all tests pass

### Step 7: Add Regression Test

Move the bug test to permanent test suite:

```swift
// Move from temporary bug file to appropriate test suite

// pawWatchPackage/Tests/pawWatchFeatureTests/WatchLocationProviderTests.swift

@Suite("WatchLocationProvider Tests")
struct WatchLocationProviderTests {

    // ... existing tests ...

    @Test("Application context falls back to file transfer on failure",
          .tags(.regression, .issue(42)))
    func testContextFallbackToFileTransfer() async throws {
        let provider = WatchLocationProvider()
        let fix = LocationFix.sample()

        provider.simulateNetworkFailure = true
        await provider.sendLocation(fix)

        #expect(provider.lastTransferMethod == .fileTransfer)
    }
}
```

**Regression Test Requirements**:
- Tag with `.regression` and issue number
- Document WHY this test exists (link to issue)
- Keep test simple and focused
- Run automatically in CI/CD

### Step 8: Verify Edge Cases

Test related edge cases to prevent similar bugs:

```swift
@Test("Application context handles nil session gracefully")
func testNilSessionHandling() async throws {
    let provider = WatchLocationProvider()
    provider.session = nil // Edge case

    let fix = LocationFix.sample()
    await provider.sendLocation(fix)

    // Should not crash
    #expect(true)
}

@Test("Application context handles invalid data")
func testInvalidDataHandling() async throws {
    let provider = WatchLocationProvider()
    let invalidFix = LocationFix(/* missing required fields */)

    await provider.sendLocation(invalidFix)

    // Should handle gracefully
    #expect(provider.lastError != nil)
}
```

### Step 9: Document the Fix

Update documentation:

```swift
// In code comments:
/// Sends location via WatchConnectivity application context
///
/// - Note: Falls back to file transfer if context update fails
/// - Bug Fix: Issue #42 - Added fallback for network failures
/// - Parameter fix: The location fix to transmit
func sendLocationViaContext(_ fix: LocationFix) async {
    // Implementation...
}
```

Update changelog:

```markdown
# CHANGELOG.md

## [Unreleased]

### Fixed
- Fixed WatchConnectivity timeout on background by adding file transfer fallback (#42)
```

### Step 10: Commit with Issue Reference

```bash
git add -A
git commit -m "fix: add fallback to file transfer when application context fails

Fixes #42

Previously, if updateApplicationContext() failed, the location update
was silently dropped. Now falls back to file transfer for guaranteed
delivery.

Added regression test to prevent future occurrences.

Test coverage:
- testContextFallbackToFileTransfer (new)
- testNilSessionHandling (edge case)
- testInvalidDataHandling (edge case)"
```

## Bug Fix Checklist

Before marking bug as fixed:

- [ ] Reproduced bug reliably
- [ ] Written failing test demonstrating bug
- [ ] Identified root cause
- [ ] Applied minimal fix
- [ ] Test now passes
- [ ] All existing tests still pass
- [ ] Added edge case tests
- [ ] Added regression test with issue tag
- [ ] Updated documentation/comments
- [ ] Updated CHANGELOG.md
- [ ] Committed with "fix:" prefix and issue reference

## Common Bug Categories

### Memory Issues
```swift
// Retain cycle
class BadExample {
    var callback: (() -> Void)?

    func setup() {
        callback = {
            self.doSomething() // Retain cycle!
        }
    }
}

// FIX: Use [weak self]
class GoodExample {
    var callback: (() -> Void)?

    func setup() {
        callback = { [weak self] in
            self?.doSomething()
        }
    }
}
```

### Concurrency Issues
```swift
// Race condition
class BadExample {
    var count = 0

    func increment() {
        count += 1 // Not thread-safe!
    }
}

// FIX: Use actor
actor GoodExample {
    var count = 0

    func increment() {
        count += 1 // Thread-safe
    }
}
```

### Nil Reference Issues
```swift
// Force unwrap crash
let distance = petLocation!.distance(from: ownerLocation!) // Crash!

// FIX: Guard statement
guard let pet = petLocation,
      let owner = ownerLocation else {
    return nil
}
let distance = pet.distance(from: owner)
```

### Logic Errors
```swift
// Off-by-one
for i in 0...array.count { // Crash on last iteration!
    print(array[i])
}

// FIX: Use correct range
for i in 0..<array.count {
    print(array[i])
}

// BETTER: Use for-in
for element in array {
    print(element)
}
```

## Debugging Tools

### Logging
```swift
import os.log

let logger = Logger(subsystem: "com.pawwatch.app", category: "location")

logger.debug("Sending location via context: \(fix.coordinate)")
logger.error("Failed to update context: \(error.localizedDescription)")
logger.info("Falling back to file transfer")
```

### Assertions
```swift
// Development-only checks
assert(session.isActivated, "Session must be activated before sending")
precondition(fix.horizontalAccuracyMeters < 100, "Accuracy too low")

// Runtime checks
guard session.isActivated else {
    assertionFailure("Session not activated")
    return
}
```

### Xcode Instruments
```bash
# Memory leaks
instruments -t Leaks MyApp.app

# Time profiler
instruments -t "Time Profiler" MyApp.app

# Network activity
instruments -t "Network" MyApp.app
```

## Prevention Strategies

After fixing bug, consider:

1. **Can we prevent this class of bug?**
   - Add linter rule
   - Add compiler warning
   - Use stronger types

2. **Is the API design flawed?**
   - Make invalid states unrepresentable
   - Use type system to enforce constraints

3. **Is documentation lacking?**
   - Add preconditions to docs
   - Add example usage
   - Document edge cases

4. **Should we add monitoring?**
   - Log critical paths
   - Add analytics for error rates
   - Alert on anomalies

---

**Remember**: Every bug is a learning opportunity. Fix the bug, prevent recurrence, improve the system.
