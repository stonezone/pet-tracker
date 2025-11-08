# WatchConnectivity Troubleshooting Guide

**Created**: 2025-11-07
**Issue**: Watch app shows "reachable: false", iOS app shows "Watch not reachable"

---

## Understanding WatchConnectivity Reachability

### What is `isReachable`?

`WCSession.isReachable` indicates whether the counterpart app is **currently reachable for immediate message delivery**. This requires:

1. ✅ Both devices are paired via Bluetooth
2. ✅ Bluetooth is enabled on both devices
3. ✅ **Both apps are in the foreground OR the counterpart app is running in background**
4. ✅ WCSession is activated on both sides

### Expected Behavior

| Scenario | `isReachable` | Notes |
|----------|---------------|-------|
| Both apps in foreground | `true` | ✅ Best case - immediate message delivery |
| Watch app foreground, iOS app background | `false` | ⚠️ Use Application Context or File Transfer |
| iOS app foreground, Watch app background | `false` | ⚠️ Messages will be queued |
| Both apps backgrounded | `false` | ⚠️ Use Application Context or File Transfer |
| Bluetooth off on either device | `false` | ❌ No connectivity |

---

## Current Issue: Watch shows `reachable: false`

Based on console output:
```
WatchLocationProvider: Session activated with state: 2, reachable: false
```

This means:
- ✅ WCSession is **activated** (state 2 = `.activated`)
- ❌ The iPhone app is **not reachable** for immediate messages

### Possible Causes

1. **iOS app not running** ⭐ Most likely
   - User hasn't launched iOS app yet
   - iOS app was terminated by system
   - iOS app crashed/exited

2. **iOS app in background**
   - User switched to another app
   - iOS app sent to background before Watch app started

3. **Bluetooth connectivity**
   - Bluetooth disabled on iPhone
   - Devices not properly paired
   - Out of Bluetooth range

4. **iOS app not calling `startTracking()`**
   - WCSession activated but not actively listening
   - App delegate not set up

---

## Triple-Path Messaging Strategy

PetTracker uses **three delivery paths** precisely for this scenario:

### Path 1: Application Context (Background, Latest-Only)
```swift
try session.updateApplicationContext(dict)
```
- ✅ Works when `isReachable == false`
- ✅ Delivered when counterpart app launches
- ✅ Automatic background delivery
- ⚠️ Only keeps **latest** value (old data discarded)
- ⚠️ Throttled to ~2Hz max

**Current Status**: This should be working even with `reachable: false`

### Path 2: Interactive Messages (Foreground, Immediate)
```swift
session.sendMessage(dict, replyHandler: nil)
```
- ❌ Only works when `isReachable == true`
- ✅ Immediate delivery (<100ms)
- ✅ Guaranteed delivery
- ⚠️ Requires both apps active

**Current Status**: Skipped when `reachable: false` (expected)

### Path 3: File Transfer (Background, Guaranteed)
```swift
session.transferFile(tempURL, metadata: metadata)
```
- ✅ Works when `isReachable == false`
- ✅ Guaranteed delivery with automatic retry
- ✅ Background delivery
- ⚠️ Slower than interactive messages

**Current Status**: Should be working as fallback

---

## Testing Procedure

### Test 1: Verify Basic Connectivity

1. **Unpair and re-pair devices**
   - iPhone Settings > Bluetooth > Unpair Apple Watch
   - Watch app > Re-pair with iPhone
   - Verify pairing completes successfully

2. **Verify Bluetooth**
   - Check Bluetooth enabled on iPhone: Settings > Bluetooth
   - Check Bluetooth enabled on Watch: Settings > Bluetooth
   - Verify "Connected" status

3. **Check App Installation**
   ```bash
   # iOS app installed?
   xcrun simctl get_app_container booted com.pettracker.PetTracker

   # Watch app installed?
   xcrun simctl get_app_container booted com.pettracker.PetTracker.watchkitapp
   ```

### Test 2: Both Apps Foreground (Ideal)

1. **Launch iOS app first**
   - Open PetTracker on iPhone
   - Verify shows "Waiting for pet location..."
   - Check console: `PetLocationManager: Session activated`

2. **Launch Watch app second**
   - Open PetTracker on Apple Watch
   - Tap "Start Tracking"
   - Check console: `WatchLocationProvider: Session activated with state: 2, reachable: true`

3. **Verify data flow**
   - Watch app should show "Connected" (green dot)
   - iOS app should receive location data within 5 seconds
   - Console should show: `PetLocationManager: Received location fix #1`

**Expected Result**: `isReachable = true` on both sides

### Test 3: Watch Foreground, iOS Background

1. Launch iOS app, verify session activated
2. Press Home button on iPhone (send to background)
3. Launch Watch app, tap "Start Tracking"

**Expected Result**:
- `isReachable = false`
- But Application Context should deliver data when iOS app returns to foreground

### Test 4: Application Context Delivery

1. Launch iOS app, then background it
2. Launch Watch app, start tracking
3. Wait 10 seconds (multiple location fixes sent)
4. Return iOS app to foreground

**Expected Result**: iOS app should receive the **latest** location fix via Application Context

---

## Console Output Analysis

### Good Activation (Working)
```
WatchLocationProvider: Session activated with state: 2, reachable: true
PetLocationManager: Session activated with state: 2, reachable: true
PetLocationManager: Reachability changed to: true
```

### Current State (Problematic)
```
WatchLocationProvider: Session activated with state: 2, reachable: false
Application context data is nil
WCErrorCodeTransferTimedOut
```

**Analysis**:
- ✅ Session activating correctly (state 2)
- ❌ Reachability false (iOS app not foreground or not running)
- ❌ "Application context data is nil" - likely trying to send before activation completes
- ❌ Transfer timeouts - messages failing because no receiver

---

## Known Issues

### Issue 1: "Application context data is nil"

**Root Cause**: Trying to send data before WCSession activation completes

**Fix Applied**: Added 1-second delay and activation check in `startTracking()`

**Verification**: Look for console log:
```
WatchLocationProvider: Waiting for WCSession activation...
```

### Issue 2: Unresponsive Stop Button

**Root Cause**: `stopTracking()` awaiting HealthKit workout cleanup

**Fix Applied**: Set `isTracking = false` immediately, cleanup runs in background

**Verification**: Stop button should work instantly now

### Issue 3: Transfer Timeouts

**Root Cause**: iOS app not running or not receiving messages

**Next Steps**:
1. Ensure iOS app launches and activates WCSession
2. Keep iOS app in foreground during testing
3. Verify both apps show "Session activated"

---

## Required Testing Order

For successful testing:

1. ✅ **Launch iOS app FIRST**
   - Wait for "Connecting to Watch..." to change to "Connected" or "Watch not reachable"
   - Verify console shows session activation

2. ✅ **Then launch Watch app**
   - Tap "Start Tracking"
   - Should see "Connected" (green) or "Queued" (orange)

3. ✅ **Keep iOS app in FOREGROUND**
   - For best results, don't background iOS app during initial testing
   - Once confirmed working, test backgrounding

4. ✅ **Monitor Console.app**
   - Filter for "WatchLocationProvider:" and "PetLocationManager:"
   - Watch for session activation and message delivery logs

---

## Success Criteria

✅ Both apps show session activated (state: 2)
✅ Watch app shows `reachable: true` when iOS app in foreground
✅ Watch app shows `reachable: false` when iOS app backgrounded (expected)
✅ iOS app receives location data (check console for "Received location fix")
✅ Stop button works immediately (no hang)
✅ No crashes or EXC_BREAKPOINT

---

## Next Debugging Steps

If reachability still false after ensuring both apps are foreground:

1. **Check WCSession paired status**
   ```swift
   print("iOS paired: \(WCSession.default.isPaired)")
   print("Watch app installed: \(WCSession.default.isWatchAppInstalled)")
   ```

2. **Verify bundle identifiers match**
   - iOS: `com.pettracker.PetTracker`
   - Watch: `com.pettracker.PetTracker.watchkitapp`
   - Must be parent-child relationship

3. **Check Info.plist configuration**
   - Watch app must have `WKCompanionAppBundleIdentifier = com.pettracker.PetTracker`
   - Both must have `WKApplication = true`

4. **Test on different device pair**
   - Try different iPhone/Watch combination
   - Update watchOS/iOS to latest versions

---

**Status**: Document created to help diagnose `reachable: false` issue and explain expected WatchConnectivity behavior.
