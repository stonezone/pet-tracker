# PetTracker Physical Device Testing Guide

**Created**: 2025-11-08
**Purpose**: Comprehensive testing protocol for iOS and watchOS physical device validation
**Target**: Phase 5c - Physical Device Testing (+0.5 pts)
**Version**: iOS 26.0, watchOS 26.0, Xcode 26.1

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Instructions](#deployment-instructions)
3. [Test Scenarios](#test-scenarios)
4. [Validation Criteria](#validation-criteria)
5. [Known Issues](#known-issues)
6. [Results Template](#results-template)

---

## Pre-Deployment Checklist

### Hardware Requirements

- [ ] iPhone running iOS 26.0 or later
- [ ] Apple Watch running watchOS 26.0 or later
- [ ] iPhone and Apple Watch paired via Bluetooth
- [ ] Both devices charged (>50% recommended for testing)
- [ ] macOS development machine with Xcode 26.1

### Developer Account Setup

- [ ] Valid Apple Developer account
- [ ] Development certificates installed in Xcode
- [ ] Provisioning profiles configured for:
  - iOS app (bundle ID: `com.pettracker.PetTracker`)
  - Watch app (bundle ID: `com.pettracker.PetTracker.watchkitapp`)
- [ ] Development team selected in Xcode project settings

### Xcode Configuration

1. **Open workspace**:
   ```bash
   cd /Users/zackjordan/code/pet-tracker
   open PetTracker.xcworkspace
   ```

2. **Verify targets**:
   - iOS target: `PetTracker`
   - Watch target: `PetTracker Watch App`

3. **Check signing**:
   - Select iOS target > Signing & Capabilities
   - Verify "Automatically manage signing" is enabled
   - Verify development team is selected
   - Repeat for Watch target

### Entitlements Verification

**iOS App** (`PetTracker.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.pettracker</string>
    </array>
</dict>
</plist>
```

**Watch App** (`PetTracker Watch App Extension.entitlements`):
- Should contain App Groups capability
- Should contain HealthKit capability (if configured)
- Should contain Location capability

### Permissions Required

**iOS App**:
- Location Services: "While Using the App" or "Always"
- Bluetooth: Required for WatchConnectivity

**Watch App**:
- Location Services: Required for GPS tracking
- HealthKit: Required for workout sessions
- Motion & Fitness: Required for activity tracking

---

## Deployment Instructions

### Standard Deployment (Recommended for App Store)

**Note**: This method works for most cases but may encounter Xcode 26.1 watchapp2 bug (error 143).

1. **Connect iPhone via USB**:
   ```bash
   # Verify device connected
   xcrun xctrace list devices
   ```

2. **Select destination in Xcode**:
   - Product > Destination > Your iPhone name
   - Ensure Apple Watch is paired and unlocked

3. **Build and run**:
   - Select scheme: `PetTracker`
   - Click Run (⌘R) or Product > Run
   - Accept codesigning prompts

4. **Verify installation**:
   - iOS app should launch on iPhone
   - Watch app should appear on Apple Watch home screen

### Workaround Deployment (If Error 143 Occurs)

**Symptom**: iOS rejects Watch app installation with:
```
MIInstallerErrorDomain error 143:
"Extensionless WatchKit app has a WatchKit extension"
```

**Workaround** (Development Only - NOT App Store compatible):

1. **Modify iOS target build phases**:
   - Select iOS target `PetTracker`
   - Build Phases tab
   - Delete or disable "Embed Watch Content" phase
   - General tab > Remove Watch app from "Frameworks, Libraries, and Embedded Content"

2. **Build iOS app separately**:
   ```bash
   # Get iPhone UDID
   IPHONE_UDID=$(xcrun xctrace list devices | grep iPhone | head -1 | sed 's/.*(\(.*\)).*/\1/')

   # Build iOS app
   xcodebuild -workspace PetTracker.xcworkspace \
     -scheme PetTracker \
     -destination "platform=iOS,id=$IPHONE_UDID" \
     build

   # Install iOS app
   xcrun devicectl device install app \
     --device $IPHONE_UDID \
     build/Release-iphoneos/PetTracker.app
   ```

3. **Build Watch app separately**:
   ```bash
   # Get Watch UDID
   WATCH_UDID=$(xcrun xctrace list devices | grep Watch | head -1 | sed 's/.*(\(.*\)).*/\1/')

   # Build Watch app
   xcodebuild -workspace PetTracker.xcworkspace \
     -scheme "PetTracker Watch App" \
     -destination "platform=watchOS,id=$WATCH_UDID" \
     build

   # Install Watch app
   xcrun devicectl device install app \
     --device $WATCH_UDID \
     "build/Release-watchos/PetTracker Watch App.app"
   ```

**Important**: This workaround is for development testing only. Revert changes before App Store submission.

### Console Logging Setup

**Critical for validation**: Use Console.app to monitor detailed logs.

1. **Open Console.app** on macOS

2. **Connect devices via USB**

3. **Filter logs**:
   ```
   # For iOS logs
   category:connectivity OR category:location OR subsystem:com.pettracker.PetTracker

   # For Watch logs
   category:connectivity OR category:watchLocation OR category:healthKit
   ```

4. **Start logging** before running tests

5. **Save logs** for each test scenario

---

## Test Scenarios

### Scenario 1: WCSession Activation

**Objective**: Verify WatchConnectivity session activates within 5 seconds on both devices.

**Prerequisites**:
- Both apps installed
- Devices paired and unlocked
- Bluetooth enabled on both devices

**Test Steps**:

1. **Launch iOS app**:
   - Open PetTracker on iPhone
   - Observe UI shows "Connecting to Watch..."

2. **Monitor Console.app** (iOS filter):
   ```
   category:connectivity
   ```

3. **Verify activation logs**:
   - Look for: `PetLocationManager: Initializing PetLocationManager`
   - Look for: `PetLocationManager: Setting up WatchConnectivity`
   - Look for: `WCSession activated successfully: duration=X.XXs`

4. **Check activation timing**:
   - Activation should complete within 5 seconds
   - Console log shows duration

5. **Verify UI update**:
   - Status should change from "Connecting to Watch..." to "Watch not reachable" or "Connected"

6. **Launch Watch app**:
   - Open PetTracker on Apple Watch
   - Monitor Console.app (Watch filter)

7. **Verify Watch activation**:
   - Look for: `WatchLocationProvider: Session activated with state: 2`
   - State 2 = `.activated`

**Pass Criteria**:
- [ ] iOS session activates within 5 seconds
- [ ] Watch session activates within 5 seconds
- [ ] No error logs during activation
- [ ] UI updates to show connection status

**Failure Indicators**:
- Timeout after 5 seconds
- Error: "WCSession activation timeout"
- Console shows: `activationDidCompleteWith error`

**Console Log Examples**:

✅ **Success**:
```
PetLocationManager: WCSession activated successfully: duration=1.23s, reachable=false
WatchLocationProvider: Session activated with state: 2, reachable: false
```

❌ **Failure**:
```
PetLocationManager: WCSession activation timeout after 5.0s: state=1
```

---

### Scenario 2: GPS Tracking Lifecycle

**Objective**: Verify GPS starts, captures locations, and stops correctly on Apple Watch.

**Prerequisites**:
- WCSession activated (Scenario 1 passed)
- Location permissions granted on Watch
- HealthKit permissions granted on Watch
- Outdoor location (clear sky view for GPS)

**Test Steps**:

1. **Start tracking from Watch**:
   - Tap "Start Tracking" button on Watch app
   - Observe button changes to "Stop Tracking"
   - Status should show "Tracking..."

2. **Monitor Console.app** (Watch filter):
   ```
   category:watchLocation OR category:healthKit
   ```

3. **Verify startup sequence**:
   - Look for: `WatchLocationProvider: Starting tracking`
   - Look for: `WatchLocationProvider: Waiting for WCSession activation` (if needed)
   - Look for: `HealthKit: Starting workout session`
   - Look for: `WatchLocationProvider: Tracking started successfully`

4. **Wait for GPS acquisition** (30-60 seconds outdoor):
   - Watch should show first location fix
   - Console shows: `Sending location fix #1`

5. **Observe GPS updates**:
   - Should receive updates ~1Hz (every 1-2 seconds)
   - Console shows incrementing sequence numbers

6. **Stop tracking**:
   - Tap "Stop Tracking" button
   - Button should respond immediately (<200ms)

7. **Verify shutdown sequence**:
   - Look for: `WatchLocationProvider: Stopping tracking`
   - Look for: `Location updates stopped`
   - Look for: `Stopping workout session`
   - Look for: `Stop tracking complete`

**Pass Criteria**:
- [ ] Start button initiates tracking within 2 seconds
- [ ] GPS first fix within 60 seconds (outdoor)
- [ ] GPS updates at ~1Hz frequency
- [ ] Stop button responds immediately (<200ms)
- [ ] No crashes or hangs during start/stop
- [ ] HealthKit workout session starts and stops cleanly

**Failure Indicators**:
- Start button unresponsive
- No GPS fixes after 60 seconds outdoor
- Stop button hangs (>1 second delay)
- Error: "Failed to start workout"
- Error: "Location permission denied"

**Console Log Examples**:

✅ **Success**:
```
WatchLocationProvider: Starting tracking
WatchLocationProvider: Tracking started successfully
WatchLocationProvider: Sending location fix #1, reachable: false
WatchLocationProvider: Sending location fix #2, reachable: false
WatchLocationProvider: Stopping tracking
WatchLocationProvider: Stop tracking complete
```

❌ **Failure**:
```
WatchLocationProvider: Failed to start workout: Error Domain=...
WatchLocationProvider: Location permission denied
```

---

### Scenario 3: Triple-Path Messaging Validation

**Objective**: Verify all three WatchConnectivity delivery mechanisms work correctly.

**Prerequisites**:
- GPS tracking active on Watch (Scenario 2)
- iOS app running
- Both devices within Bluetooth range

#### Test 3A: Application Context (Background, Latest-Only)

**Expected Behavior**: ~2Hz updates, works in background, only latest data.

**Test Steps**:

1. **Launch iOS app, then background it**:
   - Open iOS app
   - Press Home button (send to background)

2. **Start tracking on Watch**:
   - Tap "Start Tracking"
   - Wait for 10 GPS fixes (~10 seconds)

3. **Monitor Console.app** (Watch filter):
   ```
   category:connectivity
   ```

4. **Verify Application Context sends**:
   - Look for: `Sending location fix #N, reachable: false`
   - Should see updates every ~0.5 seconds (throttled)

5. **Return iOS app to foreground**:
   - Open iOS app
   - Should immediately show latest pet location

6. **Monitor Console.app** (iOS filter):
   - Look for: `Received application context`
   - Look for: `Received location fix: sequence=N`

**Pass Criteria**:
- [ ] Application Context updates sent every ~0.5s
- [ ] iOS app receives latest fix when returning to foreground
- [ ] No errors about "Application context data is nil"
- [ ] Sequence number matches latest Watch fix

**Failure Indicators**:
- Error: "Application context data is nil"
- iOS app shows stale data or no data
- Console shows: `Error sending application context`

#### Test 3B: Interactive Messages (Foreground, Immediate)

**Expected Behavior**: <100ms latency, requires both apps in foreground.

**Test Steps**:

1. **Launch both apps in foreground**:
   - iOS app foreground on iPhone
   - Watch app foreground on Watch

2. **Start tracking on Watch**:
   - Tap "Start Tracking"

3. **Monitor Console.app** (both devices):
   ```
   category:connectivity
   ```

4. **Verify reachability**:
   - Watch console: `Sending location fix #N, reachable: true`
   - iOS console: `Received interactive message`

5. **Measure latency**:
   - Note timestamp on Watch send log
   - Note timestamp on iOS receive log
   - Calculate delta (should be <100ms)

6. **Verify immediate updates**:
   - iOS app should update within 100ms of Watch GPS fix

**Pass Criteria**:
- [ ] Reachability shows `true` when both apps foreground
- [ ] Interactive messages delivered within 100ms
- [ ] iOS app updates in near real-time
- [ ] No message send failures

**Failure Indicators**:
- Reachability remains `false` despite both apps foreground
- Latency >500ms
- Error: "Interactive message failed"

#### Test 3C: File Transfer (Background, Guaranteed Delivery)

**Expected Behavior**: Guaranteed delivery with retry, works offline, queued.

**Test Steps**:

1. **Start tracking with iOS app backgrounded**:
   - iOS app in background or closed
   - Watch app starts tracking

2. **Simulate poor Bluetooth connectivity**:
   - Increase distance between devices
   - Or turn off Bluetooth briefly on iPhone

3. **Monitor Console.app** (Watch filter):
   - Look for: `Interactive message failed`
   - Look for: File transfer initiated (implicit)

4. **Restore connectivity**:
   - Bring devices close together
   - Ensure Bluetooth enabled

5. **Launch iOS app**:
   - Should receive queued location fixes

6. **Monitor Console.app** (iOS filter):
   - Look for: `session(_:didReceive file:)`
   - Look for: `Received location fix: sequence=N`

**Pass Criteria**:
- [ ] File transfers queue when unreachable
- [ ] Files delivered when connectivity restored
- [ ] iOS app receives all queued fixes
- [ ] No permanent data loss

**Failure Indicators**:
- File transfers never delivered
- Error: "Transfer timed out"
- Data loss after connectivity restored

---

### Scenario 4: Distance Calculation Accuracy

**Objective**: Verify distance calculation between pet and owner is accurate to ±10 meters.

**Prerequisites**:
- GPS tracking active on Watch
- iOS app tracking owner location
- Outdoor environment with clear GPS signals

**Test Steps**:

1. **Position devices at known distance**:
   - Place Watch 10 meters from iPhone
   - Measure distance with tape measure or GPS app

2. **Wait for GPS stabilization**:
   - Allow 60 seconds for both devices to acquire accurate GPS
   - Check accuracy values in UI (<10m horizontal accuracy)

3. **Record displayed distance**:
   - Note distance shown in iOS app

4. **Verify calculation**:
   - Compare displayed distance to measured distance
   - Should be within ±10 meters

5. **Test multiple distances**:
   - Repeat at 20m, 50m, 100m
   - Verify accuracy maintained

6. **Monitor Console.app** (iOS filter):
   ```
   category:location
   ```

7. **Verify distance logs** (if logging enabled):
   - Check calculated distance values
   - Verify using CLLocation.distance(from:)

**Pass Criteria**:
- [ ] Distance accuracy within ±10 meters at 10m
- [ ] Distance accuracy within ±10 meters at 50m
- [ ] Distance accuracy within ±10 meters at 100m
- [ ] Distance updates in real-time as devices move
- [ ] Horizontal accuracy <10m for both devices

**Failure Indicators**:
- Distance error >10 meters
- Distance shows 0.0 when devices separated
- Distance calculation crashes
- Horizontal accuracy >20m

**Accuracy Validation**:
- GPS horizontal accuracy should be <10m
- If accuracy >10m, wait longer for GPS lock
- Test in open area (not near buildings or trees)

---

### Scenario 5: Battery Life Monitoring

**Objective**: Verify Watch can track for >8 hours continuous GPS operation.

**Prerequisites**:
- Apple Watch fully charged (100%)
- GPS tracking active
- Outdoor environment for testing

**Test Steps**:

1. **Record starting battery level**:
   - Note Watch battery percentage
   - Record time

2. **Start continuous tracking**:
   - Tap "Start Tracking" on Watch
   - Keep Watch on wrist or stationary

3. **Monitor battery every 30 minutes**:
   - Check battery indicator in Watch app UI
   - Record percentage and timestamp

4. **Monitor Console.app** (Watch filter):
   ```
   subsystem:com.pettracker
   ```

5. **Verify battery reporting**:
   - UI should show accurate battery level
   - Battery level should transmit to iOS app

6. **Calculate battery drain rate**:
   - After 1 hour: (100% - current%) / 1 hour
   - Extrapolate to 8 hours

7. **Target drain rate**:
   - Should be ≤12.5% per hour
   - Allows >8 hours of continuous tracking

**Pass Criteria**:
- [ ] Battery drains at ≤12.5% per hour
- [ ] Battery indicator updates in real-time
- [ ] iOS app shows Watch battery level
- [ ] No abnormal battery drain (>20% per hour)
- [ ] Watch doesn't overheat during tracking

**Failure Indicators**:
- Battery drain >15% per hour
- Watch overheats (thermal warning)
- Battery indicator stuck at same value
- iOS app doesn't receive battery updates

**Battery Optimization Notes**:
- HealthKit workout provides optimized GPS access
- Activity type `.other` balances accuracy and battery
- Background location updates enabled

**Abbreviated Testing**:
- Full 8-hour test requires dedicated time
- 1-hour test can validate drain rate
- Extrapolate to estimate full battery life

---

### Scenario 6: Background Mode Operation

**Objective**: Verify app continues tracking when backgrounded or screen locked.

**Prerequisites**:
- GPS tracking active
- Both apps granted background location permissions

#### Test 6A: Watch App Backgrounded

**Test Steps**:

1. **Start tracking on Watch**:
   - Tap "Start Tracking"
   - Verify GPS fixes flowing

2. **Background Watch app**:
   - Press Digital Crown (return to watch face)
   - Wait 30 seconds

3. **Monitor Console.app**:
   - Verify GPS updates continue
   - Look for: `Sending location fix #N`

4. **Return to Watch app**:
   - Tap app icon
   - Verify tracking still active
   - Sequence numbers should have incremented

**Pass Criteria**:
- [ ] GPS tracking continues in background
- [ ] Location fixes still transmitted
- [ ] UI reflects correct tracking state when resumed

#### Test 6B: Watch Screen Locked

**Test Steps**:

1. **Start tracking on Watch**:
   - Tap "Start Tracking"

2. **Lock Watch screen**:
   - Cover Watch display or wait for auto-lock

3. **Wait 2 minutes**

4. **Unlock Watch screen**:
   - Raise wrist or tap display

5. **Verify tracking continued**:
   - Check sequence number incremented
   - Verify battery level updated

**Pass Criteria**:
- [ ] Tracking continues with screen locked
- [ ] GPS updates not interrupted
- [ ] HealthKit workout session maintained

#### Test 6C: iOS App Backgrounded

**Test Steps**:

1. **Start tracking with iOS app foreground**:
   - Watch sending GPS data
   - iOS app displaying updates

2. **Background iOS app**:
   - Press Home button on iPhone
   - Wait 2 minutes

3. **Return iOS app to foreground**:
   - Tap app icon

4. **Verify data received**:
   - Should show latest pet location
   - Distance calculation up-to-date

**Pass Criteria**:
- [ ] Application Context delivers latest location
- [ ] iOS app resumes without errors
- [ ] No data loss during background period

---

### Scenario 7: Error Handling UI Flows

**Objective**: Verify error states display correctly and users can recover.

#### Test 7A: Location Permission Denied (Watch)

**Test Steps**:

1. **Deny location permission**:
   - Watch Settings > Privacy > Location Services > PetTracker > Never

2. **Launch Watch app**:
   - Tap "Start Tracking"

3. **Verify error display**:
   - Should show error message
   - Should prompt to enable in Settings

4. **Grant permission**:
   - Navigate to Settings
   - Enable location access

5. **Retry tracking**:
   - Return to app
   - Tap "Start Tracking"
   - Should now work

**Pass Criteria**:
- [ ] Clear error message displayed
- [ ] User guidance provided
- [ ] App recovers after permission granted
- [ ] No crashes on permission denial

#### Test 7B: HealthKit Permission Denied

**Test Steps**:

1. **Deny HealthKit permission**:
   - When prompted, tap "Don't Allow"

2. **Attempt to start tracking**:
   - Tap "Start Tracking"

3. **Verify error display**:
   - Should show HealthKit error
   - Should provide recovery instructions

4. **Grant permission**:
   - Settings > Health > Apps > PetTracker
   - Enable Workouts

5. **Retry tracking**:
   - Should succeed

**Pass Criteria**:
- [ ] Error clearly identifies HealthKit issue
- [ ] Instructions provided for recovery
- [ ] App recovers after permission granted

#### Test 7C: WatchConnectivity Not Supported

**Test Steps**:

1. **Test on unpaired device** (simulator):
   - Launch iOS app without paired Watch

2. **Verify error display**:
   - Should show "WatchConnectivity not supported"
   - Should explain pairing requirement

**Pass Criteria**:
- [ ] Error message clear and actionable
- [ ] App doesn't crash
- [ ] User understands next steps

#### Test 7D: GPS Signal Lost

**Test Steps**:

1. **Start tracking outdoor**:
   - Acquire GPS lock

2. **Move indoor** (block GPS signal):
   - Enter building

3. **Verify UI behavior**:
   - Should show degraded accuracy
   - Should continue attempting GPS acquisition

4. **Return outdoor**:
   - Verify GPS re-acquisition

**Pass Criteria**:
- [ ] App handles GPS loss gracefully
- [ ] No crashes or freezes
- [ ] GPS re-acquires when signal returns
- [ ] Accuracy values reflect signal quality

#### Test 7E: Bluetooth Disconnection

**Test Steps**:

1. **Start tracking with both apps connected**:
   - Verify `isReachable = true`

2. **Disable Bluetooth on iPhone**:
   - Settings > Bluetooth > Off

3. **Verify Watch app response**:
   - Should show "Not Reachable" status
   - Should continue sending via Application Context

4. **Re-enable Bluetooth**:
   - Settings > Bluetooth > On

5. **Verify reconnection**:
   - Should return to "Connected" status
   - Should resume interactive messages

**Pass Criteria**:
- [ ] App detects Bluetooth disconnection
- [ ] Fallback to Application Context automatic
- [ ] Reconnection automatic when Bluetooth restored
- [ ] No data loss during disconnection

---

### Scenario 8: Connection Status Indicators

**Objective**: Verify UI accurately reflects WatchConnectivity state.

**Test Steps**:

1. **Launch iOS app without Watch app running**:
   - Status should show "Watch not reachable"

2. **Launch Watch app**:
   - Status should update

3. **Monitor status changes**:
   - Watch app foreground: "Connected" (if iOS foreground too)
   - Watch app background: "Watch not reachable"

4. **Verify indicator colors** (if implemented):
   - Green: Connected (isReachable = true)
   - Orange: Queued (isReachable = false, session active)
   - Red: Error (session not activated)

5. **Test all state transitions**:
   - Not activated → Activated
   - Not reachable → Reachable
   - Reachable → Not reachable

**Pass Criteria**:
- [ ] Status text accurate for all states
- [ ] Status updates within 2 seconds of state change
- [ ] Visual indicators match actual connectivity
- [ ] No misleading status messages

**Status Messages to Verify**:
- "Connecting to Watch..." (during activation)
- "Watch not reachable" (session active, not reachable)
- "Connected" (session active, reachable)
- "WatchConnectivity not supported" (error state)

---

## Validation Criteria

### Performance Targets

| Metric | Target | How to Measure |
|--------|--------|----------------|
| WCSession Activation | <5 seconds | Console log: `duration=X.XXs` |
| GPS First Fix | <60 seconds (outdoor) | Time from "Start Tracking" to first location |
| GPS Update Rate | ~1 Hz (1-2 seconds) | Console log sequence number timestamps |
| Interactive Message Latency | <100ms | Watch send timestamp vs iOS receive timestamp |
| Application Context Throttle | ~0.5s (2Hz max) | Console log send timestamps |
| Distance Accuracy | ±10 meters | Compare to measured distance |
| Battery Life | >8 hours | Extrapolate from 1-hour drain rate |
| Stop Button Response | <200ms | UI feedback time |

### Code Quality Validation

**Run before testing**:
```bash
cd /Users/zackjordan/code/pet-tracker

# Run all unit tests
swift test

# Verify tests pass
# Expected: 90 tests, 0 failures
```

**Console Log Quality**:
- [ ] No force unwrap crashes (EXC_BREAKPOINT)
- [ ] No retain cycle warnings
- [ ] No sendability violations
- [ ] Structured logging categories used

### Memory and Stability

**During testing, monitor**:
- [ ] No memory warnings in Console
- [ ] No crashes or unexpected terminations
- [ ] CPU usage reasonable (<50% average)
- [ ] Watch doesn't overheat

**Use Xcode Instruments** (optional deep dive):
```bash
# Memory leaks
xctrace record --template 'Leaks' --device DEVICE_ID --launch com.pettracker.PetTracker

# CPU profiling
xctrace record --template 'Time Profiler' --device DEVICE_ID --attach PetTracker
```

---

## Known Issues

### Issue 1: Xcode 26.1 Watchapp2 Bug (Error 143)

**Status**: Known Apple bug in Xcode 26.1
**Symptom**: iOS rejects Watch app installation
**Error Message**:
```
MIInstallerErrorDomain error 143:
"Extensionless WatchKit app has a WatchKit extension"
```

**Root Cause**: Xcode 26.1 generates both executable AND stub for watchapp2, confusing iOS installer

**Workaround**: See [Workaround Deployment](#workaround-deployment-if-error-143-occurs)

**Limitation**: Workaround NOT compatible with App Store submission

**Expected Fix**: Future Xcode update from Apple

**Reference**: `/Users/zackjordan/code/pet-tracker/docs/architecture/watchconnectivity-troubleshooting.md`

### Issue 2: WCSession "reachable: false" Expected Behavior

**Status**: Expected behavior, not a bug
**Symptom**: Watch logs show `reachable: false`

**Understanding**: `isReachable` only true when:
- Both apps in foreground
- Bluetooth enabled and connected
- Both sessions activated

**Expected States**:

| Scenario | isReachable | Delivery Method |
|----------|-------------|-----------------|
| Both foreground | true | Interactive Messages |
| Watch foreground, iOS background | false | Application Context |
| Both background | false | Application Context |
| Bluetooth off | false | None (queued) |

**Not an Error**: Application Context and File Transfer designed for `reachable: false`

**Reference**: See [WatchConnectivity Troubleshooting Guide](/Users/zackjordan/code/pet-tracker/docs/architecture/watchconnectivity-troubleshooting.md)

### Issue 3: First GPS Fix Delay

**Status**: Expected behavior
**Symptom**: First GPS fix takes 30-60 seconds outdoor

**Cause**: GPS cold start requires satellite acquisition

**Expected Timing**:
- Cold start (first launch): 30-60 seconds
- Warm start (recent GPS use): 10-20 seconds
- Hot start (GPS recently active): <10 seconds

**Mitigation**: Inform users of expected delay

**Not an Error**: Standard GPS behavior on all devices

### Issue 4: Application Context "data is nil"

**Status**: Fixed in current version
**Symptom**: Console shows "Application context data is nil"

**Cause**: Attempting to send before WCSession activation completes

**Fix Applied**: Added activation check and 1-second delay in `startTracking()`

**Verification**: Should not occur in current version
- If seen, report as regression

**Code Location**: `WatchLocationProvider.swift` line 138-148

### Issue 5: Stop Button Hang

**Status**: Fixed in current version
**Symptom**: Stop button unresponsive for 1-2 seconds

**Cause**: `stopTracking()` awaiting HealthKit workout cleanup on main thread

**Fix Applied**: Set `isTracking = false` immediately, cleanup runs async

**Verification**: Stop button should respond <200ms

**Code Location**: `WatchLocationProvider.swift` line 189

---

## Results Template

### Test Execution Record

**Date**: _____________
**Tester**: _____________
**Devices**:
- iPhone: Model _________, iOS Version _________
- Apple Watch: Model _________, watchOS Version _________
- Xcode Version: _________

### Scenario Results

| Scenario | Pass/Fail | Notes | Time |
|----------|-----------|-------|------|
| 1. WCSession Activation | ☐ Pass ☐ Fail | Activation time: ___s | |
| 2. GPS Tracking Lifecycle | ☐ Pass ☐ Fail | First fix: ___s | |
| 3A. Application Context | ☐ Pass ☐ Fail | Throttle rate: ___s | |
| 3B. Interactive Messages | ☐ Pass ☐ Fail | Latency: ___ms | |
| 3C. File Transfer | ☐ Pass ☐ Fail | | |
| 4. Distance Accuracy | ☐ Pass ☐ Fail | Error at 10m: ±___m | |
| 5. Battery Life | ☐ Pass ☐ Fail | Drain rate: ___%/hr | |
| 6A. Watch Backgrounded | ☐ Pass ☐ Fail | | |
| 6B. Watch Screen Locked | ☐ Pass ☐ Fail | | |
| 6C. iOS Backgrounded | ☐ Pass ☐ Fail | | |
| 7A. Location Permission Denied | ☐ Pass ☐ Fail | | |
| 7B. HealthKit Permission Denied | ☐ Pass ☐ Fail | | |
| 7C. WatchConnectivity Not Supported | ☐ Pass ☐ Fail | | |
| 7D. GPS Signal Lost | ☐ Pass ☐ Fail | | |
| 7E. Bluetooth Disconnection | ☐ Pass ☐ Fail | | |
| 8. Connection Status Indicators | ☐ Pass ☐ Fail | | |

### Performance Metrics

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| WCSession Activation | <5s | ___s | ☐ Pass ☐ Fail |
| GPS First Fix | <60s | ___s | ☐ Pass ☐ Fail |
| GPS Update Rate | ~1Hz | ___Hz | ☐ Pass ☐ Fail |
| Interactive Message Latency | <100ms | ___ms | ☐ Pass ☐ Fail |
| Application Context Throttle | ~0.5s | ___s | ☐ Pass ☐ Fail |
| Distance Accuracy (10m) | ±10m | ±___m | ☐ Pass ☐ Fail |
| Distance Accuracy (50m) | ±10m | ±___m | ☐ Pass ☐ Fail |
| Battery Drain Rate | ≤12.5%/hr | ___%/hr | ☐ Pass ☐ Fail |
| Stop Button Response | <200ms | ___ms | ☐ Pass ☐ Fail |

### Issues Encountered

| Issue | Severity | Description | Workaround/Fix |
|-------|----------|-------------|----------------|
| | ☐ Critical ☐ Major ☐ Minor | | |
| | ☐ Critical ☐ Major ☐ Minor | | |
| | ☐ Critical ☐ Major ☐ Minor | | |

### Console Logs

**Attach console logs for each scenario**:
- `ios-logs-scenario-N.txt`
- `watch-logs-scenario-N.txt`

**Save logs**:
1. Select all relevant logs in Console.app
2. Edit > Copy
3. Save to text file
4. Include timestamp and scenario number

### Overall Assessment

**Total Scenarios**: ___ / 15 passed

**Critical Issues**: ___
**Major Issues**: ___
**Minor Issues**: ___

**Recommendation**:
- ☐ Ready for production
- ☐ Minor fixes required
- ☐ Major fixes required
- ☐ Failed - significant issues

**Next Steps**:
1. _____________________________________________
2. _____________________________________________
3. _____________________________________________

**Tester Signature**: _________________ **Date**: _____________

---

## Appendix A: Console.app Filter Examples

### iOS Device Logs

**Basic connectivity and location**:
```
category:connectivity OR category:location
```

**All PetTracker logs**:
```
subsystem:com.pettracker.PetTracker
```

**Specific categories**:
```
category:connectivity
category:location
category:iOSLocation
```

**Error logs only**:
```
(subsystem:com.pettracker.PetTracker) AND (type:error OR type:fault)
```

### Watch Device Logs

**Basic Watch logging**:
```
category:connectivity OR category:watchLocation OR category:healthKit
```

**GPS and location**:
```
category:watchLocation
```

**HealthKit workout**:
```
category:healthKit
```

**WatchConnectivity**:
```
category:connectivity
```

### Combining Filters

**Errors and warnings only**:
```
(category:connectivity OR category:location) AND (type:error OR type:warning)
```

**Time-based filter** (last 5 minutes):
```
category:connectivity AND timestamp:[now-5m TO now]
```

---

## Appendix B: Troubleshooting Quick Reference

### Problem: Apps won't install on device

**Check**:
1. Valid provisioning profile
2. Development team selected
3. Device registered in Apple Developer portal
4. Xcode 26.1 watchapp2 bug (see Issue 1)

**Fix**:
```bash
# Clean build folder
xcodebuild clean -workspace PetTracker.xcworkspace -scheme PetTracker

# Verify device registered
xcrun xctrace list devices

# Try manual deployment (see Workaround Deployment)
```

### Problem: WCSession won't activate

**Check**:
1. Devices paired via Bluetooth
2. Both apps installed
3. Bundle IDs configured correctly
4. Entitlements include App Groups

**Fix**:
```bash
# Verify pairing
# iPhone: Settings > Bluetooth > Apple Watch > (i)

# Check bundle IDs
grep -r "PRODUCT_BUNDLE_IDENTIFIER" *.xcodeproj

# Restart both devices
```

### Problem: No GPS fixes

**Check**:
1. Location permission granted
2. HealthKit permission granted
3. Testing outdoor with clear sky view
4. CLLocationManager started

**Fix**:
- Check Console for permission errors
- Verify outdoor location
- Wait 60 seconds for cold start
- Reset Location & Privacy (Settings > General > Reset)

### Problem: Bluetooth not connecting

**Check**:
1. Bluetooth enabled on both devices
2. Devices within range (< 10 meters)
3. Watch not in Airplane Mode
4. No interference from other Bluetooth devices

**Fix**:
- Toggle Bluetooth off/on on both devices
- Unpair and re-pair devices
- Restart both devices

### Problem: Battery drains too fast

**Check**:
1. GPS accuracy setting (Best vs BestForNavigation)
2. HealthKit workout session active
3. Display brightness
4. Background app refresh

**Optimize**:
- Verify using `.other` activity type
- Check `distanceFilter` not too aggressive
- Monitor CPU usage in Xcode Instruments

---

## Appendix C: Quick Start Testing Checklist

**For rapid validation** (30-minute smoke test):

### Phase 1: Installation (5 minutes)
- [ ] iOS app installs without errors
- [ ] Watch app appears on Apple Watch
- [ ] Both apps launch successfully

### Phase 2: Connectivity (5 minutes)
- [ ] iOS WCSession activates <5s
- [ ] Watch WCSession activates <5s
- [ ] Status indicators show correct state

### Phase 3: GPS Tracking (10 minutes)
- [ ] Watch starts tracking
- [ ] First GPS fix <60s
- [ ] GPS updates at ~1Hz
- [ ] Stop button works immediately

### Phase 4: Data Flow (5 minutes)
- [ ] iOS app receives pet location
- [ ] Distance calculation displays
- [ ] Battery level shows on iOS
- [ ] Accuracy values reasonable (<10m)

### Phase 5: Error Handling (5 minutes)
- [ ] Test permission denial (recovers gracefully)
- [ ] Test Bluetooth disconnect (fallback works)
- [ ] Test backgrounding (continues working)

**If all pass**: Proceed to full testing suite
**If any fail**: Debug before continuing

---

**Document Version**: 1.0
**Last Updated**: 2025-11-08
**Status**: Ready for Execution
