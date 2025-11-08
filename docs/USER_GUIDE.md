# PetTracker User Guide

**Welcome to PetTracker!** Your complete guide to tracking your pet's location using Apple Watch and iPhone.

**Version**: 0.1.0
**Last Updated**: 2025-11-08
**System Requirements**: iOS 26.0+, watchOS 26.0+

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Features Guide](#features-guide)
4. [Using PetTracker](#using-pettracker)
5. [Troubleshooting](#troubleshooting)
6. [Safety Tips](#safety-tips)
7. [Tips & Tricks](#tips--tricks)
8. [Frequently Asked Questions](#frequently-asked-questions)
9. [Specifications](#specifications)
10. [Support & Feedback](#support--feedback)

---

## Introduction

### What is PetTracker?

PetTracker turns your Apple Watch into a real-time GPS tracker for your pet. Simply attach the Watch securely to your pet's collar, and monitor their location live on your iPhone. It's perfect for:

- Hiking with your dog off-leash
- Monitoring pets in large yards or parks
- Keeping tabs on adventurous cats
- Peace of mind during outdoor activities

### How Does It Work?

```
Apple Watch (on pet)  <--Bluetooth-->  iPhone (with you)
     GPS Tracker                       Live Map Display
```

1. **Apple Watch** captures your pet's GPS location every second
2. **Wireless transmission** sends location data to your iPhone via Bluetooth
3. **iPhone displays** real-time location, distance, and tracking history

### Key Features

- **Real-Time GPS Tracking** - See your pet's location update every 1-2 seconds
- **Distance Monitoring** - Know exactly how far away your pet is (in meters or feet)
- **Battery Monitoring** - Check Watch battery level remotely
- **Location History** - View the last 100 GPS positions to see where they've been
- **Privacy First** - All data stays on your devices. No cloud, no account, no subscription
- **Works Offline** - No internet or cell service required (Bluetooth only)

### System Requirements

**You'll need**:
- iPhone 12 or later with iOS 26.0+
- Apple Watch Series 4 or later with watchOS 26.0+
- Apple Watch with GPS (cellular not required)
- Paired Apple Watch and iPhone

**Battery expectations**:
- Apple Watch: 8-12 hours continuous GPS tracking
- iPhone: Minimal battery drain (less than 5% per hour)

---

## Getting Started

### First-Time Setup

#### Step 1: Install the Apps

1. **Download PetTracker** from the App Store (when published)
   - Tap "Get" to download to your iPhone
   - App automatically installs on paired Apple Watch

2. **Verify installation**:
   - iPhone: Look for PetTracker icon on home screen
   - Apple Watch: Look for PetTracker icon on watch face

#### Step 2: Pair Your Apple Watch

**Already paired?** Skip to Step 3.

**New Watch pairing**:
1. Open **Watch app** on iPhone
2. Tap "Start Pairing"
3. Hold iPhone camera over Watch display
4. Follow on-screen instructions
5. Wait for pairing to complete (5-10 minutes)

#### Step 3: Grant Permissions

**On iPhone**:

1. Launch PetTracker app
2. When prompted, tap "Allow" for:
   - **Location Services**: Choose "While Using the App"
   - **Bluetooth**: Required for Watch communication

3. If you miss the prompts:
   - Open iPhone **Settings**
   - Scroll to **PetTracker**
   - Enable Location: "While Using the App" or "Always"

**On Apple Watch**:

1. Launch PetTracker on Watch
2. Tap "Start Tracking" when prompted
3. Grant permissions:
   - **Location Services**: Tap "Always Allow"
   - **Health** (Workouts): Tap "Allow"
   - **Motion & Fitness**: Tap "Allow"

4. If you miss the prompts:
   - Watch **Settings** > **Privacy** > **Location Services**
   - Find PetTracker > Select "Always"
   - Watch **Settings** > **Health** > **Apps**
   - Find PetTracker > Enable "Workouts"

#### Step 4: Test the Connection

**Quick connection test** (2 minutes):

1. **iPhone**: Open PetTracker
   - Should show "Connecting to Watch..." then "Watch not reachable" or "Connected"

2. **Apple Watch**: Open PetTracker
   - Should show "Start Tracking" button

3. **Test GPS** (outdoor):
   - Tap "Start Tracking" on Watch
   - Wait 30-60 seconds for GPS signal
   - iPhone should display pet location on map

4. **Verify distance**:
   - Place Watch on table or ground
   - Walk 10 meters away with iPhone
   - iPhone should show distance (~10m)

**Success!** You're ready to track your pet.

### Quick Start Guide (5 Minutes)

**Get tracking in 5 easy steps**:

#### 1. Attach Watch to Pet Collar (1 minute)

**Secure attachment is critical**:
- Use a protective case or pouch designed for pet collars
- Secure Watch with Velcro straps or carabiner
- Position screen facing away from pet's neck
- Ensure collar fit: 2-finger rule (snug but not tight)
- Test: Shake collar vigorously - Watch shouldn't move

**Recommended accessories**:
- Sport bands (most secure for pets)
- Waterproof cases (for water-loving pets)
- Collar pouches with secure closures

#### 2. Warm Up GPS (1 minute)

**Before letting pet roam**:
1. Hold Watch with clear sky view
2. Launch PetTracker on Watch
3. Tap "Start Tracking"
4. Wait until accuracy shows <10 meters
5. Verify GPS icon shows solid (not flashing)

**Why?** Cold GPS start can take 30-60 seconds. Warming up ensures immediate tracking.

#### 3. Start Tracking (30 seconds)

**On Apple Watch** (already attached to pet):
- Tap "Start Tracking" button
- Button changes to "Stop Tracking"
- Status shows "Tracking..."
- GPS icon appears

**Visual confirmation**:
- GPS icon: Solid = good signal, Flashing = acquiring
- Battery icon: Shows current Watch battery level

#### 4. Monitor on iPhone (Continuous)

**On your iPhone**:
- Open PetTracker app
- Keep app in foreground for best performance
- Map shows:
  - Blue dot: Your location (iPhone)
  - Red dot: Pet location (Watch)
  - Line connecting dots
  - Distance in large numbers

**What you'll see**:
- Pet's location updates every 1-2 seconds
- Distance updates in real-time as pet moves
- Accuracy indicator (aim for <10m)
- Battery level of Watch

#### 5. Stop Tracking When Done (10 seconds)

**On Apple Watch**:
- Tap "Stop Tracking" button
- Tracking stops immediately
- Battery life is preserved
- GPS turns off

**Remove Watch from pet**:
- Detach from collar
- Recharge Watch for next use
- Clean collar and case if needed

---

## Features Guide

### Real-Time GPS Tracking

**How it works**:
- Apple Watch uses built-in GPS to capture your pet's exact coordinates
- Location updates every 1-2 seconds (approximately 1 Hz)
- Data transmitted wirelessly to your iPhone via Bluetooth
- iPhone displays location on interactive map

**What affects GPS accuracy**:

**Good accuracy** (±5-10 meters):
- Open outdoor areas (parks, fields, beaches)
- Clear view of sky
- Minimal tree cover
- Away from tall buildings

**Reduced accuracy** (±10-30 meters):
- Light forest or tree cover
- Near buildings or structures
- Overcast or stormy weather
- Urban canyons (between tall buildings)

**Poor GPS** (not recommended):
- Indoors or underground
- Dense forest canopy
- Parking garages
- Caves or tunnels

**GPS acquisition time**:
- **Cold start** (first use): 30-60 seconds outdoor
- **Warm start** (recent GPS use): 10-20 seconds
- **Hot start** (GPS just used): Under 10 seconds

**Update frequency**:
- GPS captures: ~1 time per second (1 Hz)
- iPhone display: Updates as data arrives
- No noticeable lag when Bluetooth connected

### Distance Calculation

**Real-time distance monitoring**:
- Shows straight-line distance from you to your pet
- Updates every 1-2 seconds as either of you move
- Displayed in meters (default) or feet

**How distance is measured**:
1. iPhone captures your GPS location
2. Watch captures pet's GPS location
3. iPhone calculates straight-line distance
4. Distance displayed in large, easy-to-read numbers

**Distance accuracy**:
- Depends on GPS accuracy of both devices
- Typical accuracy: ±10 meters (30 feet)
- More accurate in open areas
- Less accurate in urban or forested areas

**Distance display**:
- **Large numbers**: Current distance (e.g., "45m")
- **Updates in real-time**: Changes as pet moves
- **"--" shown**: When pet location unavailable

**Practical uses**:
- Know when pet is getting too far away
- Track pet approaching or moving away
- Set mental "safe distance" limits
- Useful for recall training

**Future feature** (not yet available):
- Geofencing: Alerts when pet exceeds set distance
- Safe zone: Notifications when pet leaves designated area

### Battery Monitoring

**Watch battery display**:
- Shows on both Watch and iPhone
- Updates every few seconds
- Displayed as percentage (e.g., "85%")
- Icon changes color based on level

**Battery indicators**:
- **Green** (80-100%): Full battery, extended tracking time
- **Yellow** (20-79%): Normal battery, monitor usage
- **Orange** (10-19%): Low battery warning
- **Red** (below 10%): Critical battery, stop soon

**Low battery warnings**:
- **20% warning**: "Watch battery low (20%)" notification
- **10% warning**: "Watch battery critical (10%)" notification
- Gives you time to retrieve pet and stop tracking

**Battery life expectations**:

**Typical use** (continuous GPS tracking):
- **8-12 hours**: Most Apple Watches
- **6-10 hours**: Older Watch models (Series 4-5)
- **10-14 hours**: Newer Watch models (Series 7+)

**Factors affecting battery life**:
- GPS usage (biggest drain)
- Screen brightness (dimmer = longer life)
- Watch model and age
- Temperature (cold weather reduces battery)
- Battery health (check in Watch Settings)

**Battery optimization features**:
- App automatically reduces GPS frequency when battery is low
- Stationary pets use less battery (adaptive throttling)
- Background operation conserves power vs foreground

**Maximizing battery life**:
- Start with fully charged Watch (100%)
- Use Theater Mode (mutes notifications, dims screen)
- Avoid cold weather when possible
- Close other Watch apps before tracking

### Connection Status

**Understanding connection states**:

#### Green: Connected
- Both apps are in foreground
- Bluetooth is connected and reachable
- Fastest updates (under 100 milliseconds)
- Interactive messages being sent

**When you'll see this**:
- iPhone app open, Watch app open
- Both devices within Bluetooth range (30 feet)
- No obstructions between devices

#### Orange: Queued Updates
- Watch is sending but iPhone not reachable
- iPhone app is backgrounded or closed
- Updates queued for delivery
- Data delivered when connection restored

**When you'll see this**:
- iPhone app in background
- Watch and iPhone separated beyond Bluetooth range
- Temporary Bluetooth interference

**Not an error**: Normal operation for background tracking.

#### Yellow: Connecting
- WatchConnectivity session activating
- Temporary state during app startup
- Should resolve within 5 seconds

**When you'll see this**:
- Just launched either app
- Watch and iPhone establishing connection

#### Red: Not Reachable
- Connection issue detected
- Check Bluetooth and permissions
- Troubleshooting needed

**When you'll see this**:
- Bluetooth disabled on iPhone
- Watch and iPhone unpaired
- Permissions not granted
- App issues

**Connection range**:
- **Optimal**: 0-10 feet (3 meters)
- **Good**: 10-30 feet (10 meters)
- **Marginal**: 30-50 feet (15 meters)
- **Unreliable**: Beyond 50 feet

**Automatic reconnection**:
- App automatically attempts reconnection
- No manual intervention needed
- Queued data delivered when reconnected
- No location data is lost

### Location History

**View past locations**:
- Last 100 GPS fixes stored
- Shows pet's trail on map
- Timestamps for each position
- Accuracy values displayed

**How to use**:
- Blue line on map shows historical trail
- Tap markers to see details
- Zoom in/out to view full trail
- Pan map to explore path

**History display**:
- Most recent: Brightest/darkest marker
- Older positions: Faded markers
- Trail line: Connects positions in order

**Storage**:
- Last 100 positions kept in memory
- Oldest positions removed as new ones arrive
- Cleared when app restarts
- Not saved to disk (privacy)

**Clear history**:
- Tap "Clear History" button (if available)
- Or restart the app
- History automatically clears on stop tracking

**Future feature** (not yet available):
- Export trail as GPX file
- Save favorite trails
- Share trails with others
- Trail statistics (distance, time, speed)

---

## Using PetTracker

### iOS App (Owner's iPhone)

#### Main Screen Walkthrough

**Top section: Map View**
- Interactive map showing your location and pet's location
- Blue dot with circle: Your current position (iPhone GPS)
- Red dot/marker: Pet's current position (Watch GPS)
- Blue line/trail: Historical path showing where pet has been
- Zoom controls: Pinch to zoom in/out
- Pan: Drag map to move around

**Center section: Distance Display**
- Large bold numbers: Current distance to pet
  - Example: "45m" means pet is 45 meters away
  - Updates in real-time as distance changes
  - Shows "--" when pet location is unavailable

**Stats section: Location Details**
- **Pet Location**:
  - Latitude/Longitude coordinates
  - Altitude (meters above sea level)
  - Horizontal accuracy (±10m typical)
  - Speed (if pet is moving)
  - Timestamp of last update

- **Your Location**:
  - Your current coordinates
  - Your accuracy
  - Last update time

**Bottom section: Status Bar**
- **Connection Status**:
  - "Connected" (green) = Real-time updates
  - "Watch not reachable" (orange) = Background updates
  - "Connecting..." (yellow) = Establishing connection

- **Battery Indicator**:
  - Watch battery percentage
  - Color-coded icon (green/yellow/orange/red)

- **GPS Accuracy**:
  - Shows current GPS accuracy for both devices
  - Aim for <10m for best results

**Action buttons**:
- "Clear History": Removes trail markers from map
- "Center on Pet": Re-centers map on pet's location
- "Center on Me": Re-centers map on your location

#### Reading the Map

**Your location (Blue)**:
- Blue dot: Your current GPS position
- Blue circle: Accuracy radius (uncertainty zone)
- Smaller circle = more accurate

**Pet's location (Red)**:
- Red dot/marker: Pet's current GPS position
- Updates every 1-2 seconds
- Moves in real-time as pet moves

**Trail (Blue line)**:
- Connects historical GPS positions
- Shows where pet has been
- Fades for older positions
- Maximum 100 positions shown

**Map interactions**:
- Pinch: Zoom in/out
- Drag: Pan/move map
- Tap marker: View details
- Double-tap: Quick zoom in

**Map tips**:
- Use satellite view for terrain reference
- Zoom in for detail, zoom out for overview
- Re-center frequently to track moving pet
- Note landmarks for pet recall

#### Understanding Distance

**Distance display**:
- **Large numbers**: Main distance in meters
- **Small label**: Unit (m for meters, ft for feet)
- **Real-time**: Updates as you or pet moves
- **"--"**: Shown when pet location unavailable

**Distance interpretation**:
- **0-10m**: Pet very close (within sight)
- **10-30m**: Pet nearby (should be visible in open area)
- **30-100m**: Pet at moderate distance
- **100-300m**: Pet far away (may be out of sight)
- **300m+**: Pet very far (consider recall)

**Distance uses**:
- Monitor pet's range during off-leash play
- Know when to call pet back
- Track pet returning to you
- Estimate search area if pet hides

**Accuracy notes**:
- Distance is straight-line (as the crow flies)
- Doesn't account for terrain or obstacles
- ±10m accuracy typical
- More accurate in open areas

#### Viewing Location History

**Trail visualization**:
- Map shows blue line connecting past positions
- Markers show individual GPS fixes
- Latest position most prominent
- Trail fades back in time

**History details**:
- Tap any marker to view:
  - Timestamp: When position was captured
  - Coordinates: Exact lat/long
  - Accuracy: GPS precision at that time
  - Sequence number: Order in trail

**Using history**:
- See where pet has explored
- Identify favorite areas or paths
- Track pet's movement pattern
- Retrace steps if pet is lost

**History limitations**:
- Maximum 100 positions stored
- Cleared when tracking stops
- Not saved between sessions
- Cannot export yet (future feature)

#### Error Messages and What They Mean

**"Watch not reachable"**
- **Meaning**: Bluetooth connection not active
- **Cause**: iPhone and Watch too far apart, or Watch app in background
- **Action**: Normal during background operation. Bring iPhone closer for faster updates.
- **Status**: Not an error - updates still being sent

**"Connecting to Watch..."**
- **Meaning**: Establishing WatchConnectivity session
- **Cause**: App just launched
- **Action**: Wait 5 seconds for connection
- **Status**: Normal during startup

**"Location permission denied"**
- **Meaning**: PetTracker doesn't have location access
- **Cause**: Permissions not granted or revoked
- **Action**: Go to Settings > PetTracker > Location > Select "While Using"
- **Status**: Error - must fix to use app

**"WatchConnectivity not supported"**
- **Meaning**: Watch not paired or WatchConnectivity unavailable
- **Cause**: Watch not paired to iPhone
- **Action**: Pair Watch via Watch app on iPhone
- **Status**: Error - pairing required

**"GPS signal lost"**
- **Meaning**: Watch cannot acquire GPS signal
- **Cause**: Indoors, poor sky view, or GPS interference
- **Action**: Move to outdoor area with clear sky view
- **Status**: Temporary - GPS will re-acquire when signal returns

**"--" for distance**
- **Meaning**: Pet location currently unavailable
- **Cause**: GPS acquiring, connection issue, or tracking not started
- **Action**: Wait for GPS signal or start tracking on Watch
- **Status**: Normal during GPS acquisition

### Watch App (Pet's Watch)

#### Watch Screen Walkthrough

**Main screen elements**:

**Top section**:
- **Status indicator**: "Ready to Track" or "Tracking..."
- **GPS icon**: Shows GPS signal strength
  - Solid: Good GPS signal
  - Flashing: Acquiring GPS
  - X: No GPS signal

**Middle section**:
- **Large button**: "Start Tracking" or "Stop Tracking"
  - Green background: Ready to start
  - Red background: Currently tracking
  - Tap to toggle tracking on/off

**Bottom section**:
- **Battery indicator**:
  - Percentage (e.g., "85%")
  - Icon with color coding
  - Updates every few seconds

- **Accuracy indicator**:
  - Shows GPS accuracy in meters
  - Example: "±8m"
  - Lower number = better accuracy

**Stats display** (when tracking):
- Sequence number: Count of GPS fixes sent
- Duration: How long tracking has been active
- Speed: Pet's current speed (if moving)

#### Start Tracking Button

**Before tracking**:
- Button shows: "Start Tracking"
- Green background
- Tap to begin GPS capture

**Starting tracking**:
1. Tap "Start Tracking" button
2. Button immediately responds
3. Status changes to "Tracking..."
4. GPS acquisition begins
5. Button changes to "Stop Tracking" (red)

**What happens**:
- HealthKit workout session starts
- GPS turns on and begins acquiring signal
- Location updates begin (every 1-2 seconds)
- Data transmission to iPhone starts
- Battery monitoring activates

**First GPS fix**:
- Wait 30-60 seconds outdoor
- GPS icon changes from flashing to solid
- First location sent to iPhone
- Accuracy improves over next 1-2 minutes

#### Stop Tracking Button

**During tracking**:
- Button shows: "Stop Tracking"
- Red background
- Tap to end GPS capture

**Stopping tracking**:
1. Tap "Stop Tracking" button
2. Button responds immediately (under 200ms)
3. Status changes to "Ready to Track"
4. GPS turns off
5. Button changes to "Start Tracking" (green)

**What happens**:
- HealthKit workout session ends
- GPS turns off (saves battery)
- Location updates stop
- Data transmission ends
- Battery drain significantly reduces

**Response time**:
- Button should respond in under 200 milliseconds
- If delayed, see Troubleshooting section

#### Battery Indicator

**Display format**:
- Percentage: "85%" shows remaining battery
- Icon: Battery shape with fill level
- Color: Changes based on battery level
  - Green: 80-100%
  - Yellow: 20-79%
  - Orange: 10-19%
  - Red: Below 10%

**Updates**:
- Refreshes every few seconds during tracking
- Transmitted to iPhone for remote monitoring
- Accurate to ±1-2%

**Low battery warnings**:
- 20% warning: Yellow icon, consider stopping soon
- 10% warning: Red icon, stop tracking immediately
- Below 5%: May shut down unexpectedly

**Battery tips**:
- Start with 80%+ battery for multi-hour tracking
- Monitor battery every 30 minutes
- Plan return trip when battery reaches 30%
- Bring portable charger for extended trips

#### GPS Accuracy Indicator

**Shows GPS precision**:
- Displayed as "±Xm" (e.g., "±8m")
- Lower number = more accurate
- Updates with each GPS fix

**Accuracy levels**:
- **Excellent** (±5m or less): Best GPS signal
- **Good** (±5-10m): Normal outdoor accuracy
- **Fair** (±10-20m): Acceptable for tracking
- **Poor** (±20m+): Marginal GPS, consider moving to open area

**Factors affecting accuracy**:
- Sky visibility (more sky = better)
- Tree or building obstruction
- Number of GPS satellites visible
- Weather conditions
- Watch movement (stationary = better lock)

**Using accuracy info**:
- Wait for <10m accuracy before letting pet roam
- Higher accuracy = more precise distance calculations
- Poor accuracy indoors is normal
- Accuracy improves over 1-2 minutes after start

#### Screen Lock Prevention

**Why screen locks**:
- Apple Watch auto-locks after inactivity
- Saves battery when not in use
- Prevents accidental taps

**PetTracker and screen lock**:
- Tracking continues even when screen locked
- GPS keeps running in background
- No need to keep screen on
- Battery savings from locked screen

**Prevent accidental stops**:
- Screen lock prevents pet from stopping tracking
- Button requires intentional tap
- Digital Crown exit also locks screen

**Best practice**:
- Start tracking, then let screen lock
- Reduces battery drain
- Prevents accidental interactions
- Tracking continues reliably

---

## Troubleshooting

### Common Issues

#### Issue: "Watch Not Reachable"

**Symptoms**:
- iPhone shows "Watch not reachable" message
- Orange connection status indicator
- Updates delayed or infrequent

**Possible causes**:
1. Watch and iPhone too far apart (beyond Bluetooth range)
2. Bluetooth disabled on iPhone
3. Watch app in background or closed
4. Physical obstacles between devices
5. Bluetooth interference

**Solutions**:

**Check Bluetooth**:
1. iPhone Settings > Bluetooth
2. Verify Bluetooth is ON (green toggle)
3. Look for Apple Watch in device list
4. Should show "Connected"

**Check distance**:
- Bring iPhone and Watch within 10 feet (3 meters)
- Remove obstacles between devices
- Avoid metal, walls, or water barriers

**Restart Bluetooth**:
1. Toggle Bluetooth OFF
2. Wait 5 seconds
3. Toggle Bluetooth ON
4. Wait for reconnection (10-30 seconds)

**Restart devices**:
- iPhone: Hold side button > Slide to power off > Wait 30s > Power on
- Watch: Hold side button > Power Off > Wait 30s > Power on

**Re-pair Watch** (last resort):
1. iPhone Watch app > All Watches > (i) next to your Watch
2. Tap "Unpair Apple Watch"
3. Wait for unpair to complete
4. Pair Watch again from scratch
5. Reinstall PetTracker

**Note**: "Watch not reachable" is normal when:
- iPhone app is backgrounded (expected behavior)
- Watch and iPhone beyond 30 feet apart
- Updates still being sent, just queued

#### Issue: "Location Permission Denied"

**Symptoms**:
- Error message on iPhone or Watch
- GPS not starting
- No location data shown

**Possible causes**:
1. Location Services disabled system-wide
2. PetTracker permission denied or set to "Never"
3. Location Services disabled for PetTracker

**Solutions**:

**On iPhone**:
1. Open **Settings** app
2. Tap **Privacy & Security**
3. Tap **Location Services**
4. Verify Location Services is ON (green toggle at top)
5. Scroll down to **PetTracker**
6. Tap **PetTracker**
7. Select **"While Using the App"** or **"Always"**
8. Verify "Precise Location" is enabled

**On Apple Watch**:
1. Open **Settings** on Watch
2. Tap **Privacy**
3. Tap **Location Services**
4. Verify Location Services is ON
5. Scroll to **PetTracker**
6. Tap **PetTracker**
7. Select **"Always"**

**Reset Location & Privacy** (nuclear option):
1. iPhone Settings > General > Transfer or Reset iPhone
2. Tap "Reset"
3. Tap "Reset Location & Privacy"
4. Enter passcode
5. Confirm reset
6. Re-grant permissions when prompted

**Verify fix**:
- Restart PetTracker app
- Should prompt for location permission
- Grant permission and test GPS

#### Issue: "GPS Signal Lost"

**Symptoms**:
- GPS icon shows X or flashing
- No location fixes after 60+ seconds
- Accuracy shows very high number (±100m+)

**Possible causes**:
1. Testing indoors or underground
2. Dense tree cover or forest canopy
3. Urban canyon (tall buildings blocking sky)
4. Poor weather (heavy clouds, storm)
5. GPS antenna issue

**Solutions**:

**Move to open area**:
- Go outside to open space
- Clear view of sky required
- Avoid areas near tall buildings
- Stay away from dense tree cover

**Wait for GPS acquisition**:
- Cold start: 30-60 seconds normal
- Don't move Watch during acquisition
- Keep Watch facing up (antenna facing sky)
- Be patient - GPS needs time

**Check for interference**:
- Move away from power lines
- Avoid radio towers or antennas
- Remove from metal containers
- Keep away from other GPS devices

**Restart GPS** (if not acquiring after 90 seconds):
1. Tap "Stop Tracking"
2. Wait 10 seconds
3. Tap "Start Tracking" again
4. Wait 30-60 seconds outdoor

**Verify GPS hardware**:
- Test GPS in Apple Maps on Watch
- Open Maps app on Watch
- Check if GPS location works
- If Maps GPS fails, hardware issue possible

**Environmental limitations**:
- Indoors: GPS not designed to work
- Parking garages: No GPS signal
- Basements: GPS won't penetrate
- Dense forest: Reduced accuracy expected

#### Issue: Slow GPS Acquisition (First Fix Taking Too Long)

**Symptoms**:
- GPS acquiring for 60+ seconds
- GPS icon flashing for extended time
- "Waiting for GPS..." message

**Possible causes**:
1. Cold start (first GPS use in hours/days)
2. Watch moved before GPS lock
3. Poor satellite geometry
4. Weak GPS signal

**Solutions**:

**Pre-warm GPS** (recommended):
1. Before attaching Watch to pet collar
2. Hold Watch stationary with clear sky view
3. Tap "Start Tracking"
4. Wait until accuracy shows <10m
5. Wait for GPS icon to show solid (not flashing)
6. THEN attach to pet collar

**Stationary acquisition**:
- Don't move Watch during acquisition
- Hold Watch still for 30-60 seconds
- Watch movement delays GPS lock
- Once locked, movement is fine

**Optimal positioning**:
- Watch face up (antenna facing sky)
- Clear line of sight to sky
- No hand/body blocking Watch
- Away from walls or roof overhangs

**Timing expectations**:
- **Cold start** (first time): 30-90 seconds
- **Warm start** (GPS used recently): 10-30 seconds
- **Hot start** (GPS just stopped): 5-10 seconds

**Improve future acquisitions**:
- Use GPS regularly (keeps almanac fresh)
- Don't let Watch sit unused for days
- Occasional Maps app use helps
- Location Services always enabled

#### Issue: Poor Battery Life (Less Than 6 Hours)

**Symptoms**:
- Battery draining faster than 15% per hour
- Watch dying in under 6 hours
- Unexpected shutdowns

**Possible causes**:
1. Old Watch with degraded battery
2. Other apps running in background
3. Screen brightness too high
4. GPS accuracy setting too aggressive
5. Cold weather operation

**Solutions**:

**Check battery health**:
1. Watch Settings > Battery
2. Tap "Battery Health"
3. Check "Maximum Capacity"
   - 100-80%: Healthy battery
   - 79-60%: Degraded, consider replacement
   - Below 60%: Replace battery soon
4. If "Peak Performance Capability" shows message, battery degraded

**Close other apps**:
1. Before starting tracking, close all Watch apps
2. Press Digital Crown to see app grid
3. Swipe away or force-quit apps
4. Only PetTracker should run

**Reduce screen brightness**:
1. Watch Settings > Display & Brightness
2. Reduce brightness slider
3. Or use Theater Mode (swipe up, tap masks icon)
4. Screen off saves significant battery

**Optimize Watch settings**:
1. Disable Always-On Display (if enabled)
   - Settings > Display & Brightness > Always On > OFF
2. Reduce haptic strength
   - Settings > Sounds & Haptics > Haptic Strength > Low
3. Disable background app refresh
   - Settings > General > Background App Refresh > OFF

**Temperature considerations**:
- Cold weather (below 32°F / 0°C) reduces battery
- Keep Watch warm before use
- Insulate Watch if tracking in cold
- Battery recovers when warmed

**Verify GPS settings** (advanced):
- Check if app using "Best for Navigation" accuracy (not recommended)
- Should use "Best" accuracy (PetTracker default)
- Excessive accuracy drains battery faster

**Battery replacement**:
- Apple Watch battery replacement: $79 (Apple Store)
- Batteries degrade after 2-3 years
- 500-1000 charge cycles expected life

#### Issue: Distance Shows "--"

**Symptoms**:
- Distance display shows dashes instead of number
- Distance unavailable or missing
- "Distance: --" message

**Possible causes**:
1. iPhone GPS disabled or no permission
2. Pet location not yet acquired
3. GPS signal lost on iPhone
4. Location Services disabled

**Solutions**:

**Enable iPhone GPS**:
1. Settings > Privacy & Security > Location Services
2. Turn ON Location Services (top toggle)
3. Scroll to PetTracker
4. Select "While Using the App"
5. Enable "Precise Location"

**Check iPhone GPS working**:
- Open Apple Maps on iPhone
- Verify your location shows correctly
- Blue dot should appear on map
- If Maps GPS fails, iOS issue

**Wait for GPS acquisition**:
- iPhone may need 10-30 seconds for GPS lock
- Keep iPhone outdoors with clear sky view
- Don't block GPS antenna (top of iPhone)

**Keep app in foreground**:
- PetTracker must be open on iPhone
- "While Using" permission requires foreground
- Lock screen okay, but app must be active

**Restart Location Services**:
1. Settings > Privacy > Location Services
2. Toggle OFF
3. Wait 5 seconds
4. Toggle ON
5. Relaunch PetTracker

**Verify both devices have GPS**:
- iPhone: GPS acquired (blue dot on map)
- Watch: GPS acquired (red dot on map)
- Distance requires BOTH positions

---

## Safety Tips

### Pet Safety

**Secure Watch attachment is critical**:

**Collar fit**:
- Use "2-finger rule": Slip 2 fingers under collar
- Collar should be snug but not tight
- Too loose: Watch can slip off or dangle
- Too tight: Discomfort or breathing issues
- Check fit after attaching Watch

**Watch positioning**:
- Position Watch on top or side of neck
- Screen facing away from pet's skin
- Avoid throat area (too sensitive)
- Secure Watch so it doesn't rotate
- Check that collar doesn't restrict movement

**Attachment methods**:
- **Sport bands**: Most secure, wrap around collar
- **Velcro straps**: Quick attach/detach, check tightness
- **Collar pouches**: Dedicated pet GPS pouches
- **Carabiner clips**: Quick release, ensure secure closure
- **Avoid**: Tape, rubber bands, loose fabric

**Regular checks**:
- **Before each use**: Test attachment security
- **Every 15-30 minutes**: Check Watch hasn't shifted
- **After activity**: Inspect for looseness or damage
- **Daily**: Check collar for wear or fraying

**Monitor for discomfort**:
- Watch for signs of irritation or discomfort
- Pet scratching at collar excessively
- Rubbing neck against objects
- Reluctance to move or play
- Red marks or hair loss on neck

**When to remove Watch**:
- Indoor time (GPS not needed)
- Sleeping or resting
- Eating or drinking
- Swimming (unless waterproof case)
- Any signs of discomfort

**Important**: PetTracker is a tracking aid, not a replacement for supervision. Always maintain visual contact when possible, especially in high-risk areas.

### Device Safety

**Protect Watch from damage**:

**Water exposure**:
- Check Watch water resistance rating (Apple Watch Series 2+: water-resistant to 50m)
- Use waterproof case for swimming or water play
- Rinse with fresh water after saltwater exposure
- Dry thoroughly before charging
- Water resistance degrades over time

**Temperature extremes**:
- **Too hot** (above 95°F / 35°C): Watch may overheat and shut down
- **Too cold** (below 32°F / 0°C): Battery drains faster, may shut down
- Don't leave in direct sunlight when not tracking
- Don't use in extreme heat (desert, summer car interior)
- Insulate Watch in freezing conditions

**Physical protection**:
- Use protective case or screen protector
- Prevents scratches from outdoor terrain
- Protects from impact if pet runs into objects
- Cases designed for rugged use recommended

**Cleaning and maintenance**:
- Clean Watch and band after each use
- Dirt, mud, or debris can affect sensors
- Wipe with soft, lint-free cloth
- Avoid harsh chemicals or solvents
- Check band for wear and replace if needed

**Storage when not in use**:
- Remove from pet collar
- Store in cool, dry place
- Keep away from extreme temperatures
- Charge to 50% for long-term storage
- Clean before storing

**Signs of overheating**:
- Watch feels very hot to touch
- "Temperature Warning" message on screen
- Unexpected shutdown
- Reduced performance

**If Watch overheats**:
1. Stop tracking immediately
2. Remove from pet collar
3. Power off Watch
4. Place in cool (not cold) location
5. Allow to cool for 15-30 minutes
6. Do not charge until cooled

### Privacy and Data Security

**Your location data is private**:

**No cloud storage**:
- All location data stays on your iPhone and Apple Watch
- Nothing uploaded to servers
- No remote tracking or access
- Complete privacy and control

**No account required**:
- No login credentials
- No personal information collected
- No email or phone number needed
- No subscription or payment

**No third-party sharing**:
- Zero data sharing with other companies
- No advertising or analytics tracking
- No sale of location data
- Complete transparency

**Data retention**:
- Location history stored in device memory only
- Maximum 100 GPS fixes kept
- Cleared when tracking stops or app restarts
- Not saved to disk or persistent storage

**Clearing your data**:
1. Stop tracking (clears current session)
2. Restart app (clears all history)
3. Delete app (removes all data permanently)

**Bluetooth security**:
- Encrypted Bluetooth connection
- Paired devices only (no open broadcast)
- WatchConnectivity uses secure channel
- No vulnerability to Bluetooth snooping

**Permissions transparency**:
- App only requests necessary permissions
- Location: Required for GPS tracking
- HealthKit: Required for workout session (battery optimization)
- Bluetooth: Required for Watch communication
- No camera, microphone, or contact access

**What we can't access**:
- Your location when app not in use
- Other apps' data
- Photos or media
- Messages or calls
- Any personal information

---

## Tips & Tricks

### For Best GPS Accuracy

**Pre-tracking preparation**:

**1. Warm up GPS before use** (1-2 minutes):
- Hold Watch outdoors with clear sky view
- Launch PetTracker and tap "Start Tracking"
- Wait until accuracy shows <10 meters
- Wait for GPS icon to become solid (not flashing)
- THEN attach to pet collar and let pet roam
- Why: Cold GPS start takes 30-60 seconds; pre-warming ensures immediate accurate tracking

**2. Choose optimal locations**:
- **Best**: Open parks, fields, beaches, deserts
- **Good**: Light forest, suburban yards, hiking trails
- **Fair**: Urban areas with buildings, moderate tree cover
- **Avoid**: Dense forests, urban canyons, indoors, parking garages

**3. Time of day considerations**:
- **Best GPS**: Clear, sunny days with no cloud cover
- **Good GPS**: Partly cloudy, overcast but dry
- **Reduced GPS**: Heavy clouds, fog, rain, or snow
- **Worst GPS**: Severe weather, thunderstorms, heavy precipitation
- Satellite geometry changes throughout day; accuracy varies

**4. Watch positioning on collar**:
- Position Watch on top of pet's neck (highest point)
- Screen and sensors facing up toward sky
- Avoid positioning under pet's chin or on throat
- Ensure no metal collar parts blocking GPS antenna
- GPS antenna is on back of Watch (opposite screen)

**5. Movement for faster GPS lock**:
- Initial acquisition: Keep Watch stationary
- After GPS lock: Movement is fine and expected
- GPS maintains lock better when moving slowly
- Rapid direction changes may briefly reduce accuracy

### For Longer Battery Life

**Maximize Watch runtime**:

**1. Start with sufficient charge**:
- Charge to 80-100% before tracking session
- 80% charge = ~8 hours of tracking
- 100% charge = ~10-12 hours of tracking
- Below 50% start = high risk of early shutdown

**2. Battery-saving Watch settings**:
```
Before tracking, configure Watch:
Settings > Display & Brightness:
  - Always On Display: OFF
  - Brightness: 50% or lower
  - Text Size: Default (larger text uses more power)

Settings > Sounds & Haptics:
  - Haptic Strength: Medium or Low
  - Mute notifications (reduces vibration)

Settings > General > Background App Refresh:
  - OFF (or disable for all apps except essential)
```

**3. Use Theater Mode during tracking**:
- Swipe up on Watch face (Control Center)
- Tap theater masks icon (Theater Mode)
- Screen stays off until button pressed
- Notifications silenced
- Significant battery savings
- Tracking continues normally

**4. Close unnecessary apps**:
- Before starting PetTracker, close all other Watch apps
- Press Digital Crown to see app grid
- Swipe up on app cards to close
- Reduces background CPU and memory usage

**5. Avoid extreme temperatures**:
- Cold weather (below 32°F / 0°C): Battery drains 2-3x faster
- Keep Watch warm before use
- Insulate with fabric or protective case in cold
- Hot weather (above 95°F / 35°C): May trigger thermal protection
- Avoid direct sunlight when not in use

**6. Optimize for stationary pets**:
- PetTracker automatically reduces GPS frequency for stationary pets
- If pet stays in one area, battery lasts longer
- Adaptive throttling kicks in after 30 seconds of no movement
- Battery savings: 20-30% for stationary pets

**7. Plan your tracking session**:
- 1-2 hour outing: 30%+ battery sufficient
- Half-day (4-5 hours): 60%+ battery recommended
- Full day (8+ hours): Start at 100%, monitor every hour
- Bring portable battery pack for extended trips

**8. Monitor battery during use**:
- Check Watch battery every 30 minutes
- iPhone displays Watch battery remotely
- Plan return trip when battery reaches 30%
- Return immediately at 10% warning

### For Hiking and Camping

**Extended outdoor adventures**:

**Pre-trip preparation**:

**1. Test system before heading out**:
- Day before trip: Full test run (1-2 hours)
- Verify GPS acquires quickly
- Test Bluetooth range and connection
- Ensure both devices fully charged
- Update to latest iOS/watchOS versions

**2. Note GPS coordinates at trailhead**:
- Launch Maps app and screenshot coordinates
- Write down or save in Notes app
- Provides reference point if GPS fails
- Helps search and rescue if needed

**3. Bring backup power**:
- Portable battery pack for Watch (minimum 5000mAh)
- USB-C or Watch charging cable
- Solar charger for multi-day trips
- Spare batteries for emergency lighting

**4. Weatherproof protection**:
- Waterproof case or bag for Watch
- Plastic bag for iPhone (moisture protection)
- Consider GPS-specific protective case
- Test water resistance before trip

**During the hike**:

**1. Manage battery strategically**:
- Don't run GPS continuously for entire hike
- Use GPS during off-leash periods only
- Keep pet on leash during low-battery periods
- Track for 1-2 hours, then break to conserve battery

**2. Optimal tracking windows**:
- Start of hike: Track while energy high, pet likely to roam
- Water/rest breaks: Stop tracking to save battery
- Off-leash areas: Resume tracking
- Return hike: Stop tracking if battery low, use leash

**3. Stay within Bluetooth range when possible**:
- Bluetooth range: 30-50 feet optimal
- Reduces reliance on queued updates
- Faster location updates
- Less battery drain than out-of-range operation

**4. Regular visual checks**:
- Don't rely solely on GPS for pet location
- Visual confirmation every 1-2 minutes
- Use GPS to assist, not replace, supervision
- Call pet back regularly for check-ins

**Emergency preparedness**:

**1. Backup identification**:
- Always use traditional ID tag with phone number
- Consider microchip (permanent identification)
- PetTracker is a tool, not sole identification
- Multiple layers of protection

**2. If Watch battery dies**:
- Last known location stored in iPhone app
- Screenshot or note coordinates
- Search from that point outward
- GPS coordinates can be shared with others

**3. Share trip details**:
- Tell someone your hiking plan
- Share trailhead location
- Provide estimated return time
- Emergency contact information

**4. Download offline maps**:
- Apple Maps: Download area before trip
- Allows map viewing without cell service
- GPS still works offline
- Navigate even without data connection

**Multi-day camping**:

**1. Power management**:
- Bring 10,000mAh+ battery pack
- Solar charger for sunny locations
- Track only during off-leash periods
- Keep devices powered off when not tracking

**2. Establish "safe zone" at campsite**:
- Let pet roam within visual range
- Use GPS to verify pet hasn't wandered far
- Set mental geofence (e.g., 50m from camp)
- Call pet back if exceeding range

**3. Night tracking**:
- GPS works 24/7 (no light needed)
- Watch screen provides light for visibility
- Higher risk of pet wandering at night
- Consider keeping pet secured at night

### For Multiple Pets

**Current limitations**:
- PetTracker currently supports 1 Apple Watch (1 pet)
- One-to-one pairing: iPhone to Watch
- Cannot track multiple pets simultaneously with one iPhone

**Workarounds for multi-pet tracking**:

**Option 1: Multiple iPhones** (full tracking)
- Use separate iPhone for each pet
- Each iPhone paired to separate Watch
- Each pet gets dedicated Watch on collar
- Full independent tracking for each pet
- Expensive but most comprehensive

**Option 2: Rotate tracking** (single Watch)
- Track one pet at a time
- Swap Watch between pet collars
- Use for pet most likely to roam
- Practical for controlled environments

**Option 3: Track highest-risk pet** (focus)
- Identify pet most likely to wander or run
- Track that pet with PetTracker
- Keep other pets on leash or in sight
- Allocate resources to highest need

**Option 4: Traditional collar for backup**
- Primary pet: PetTracker with GPS
- Secondary pets: GPS collars from other manufacturers
- Combine technologies for full coverage
- Redundancy and peace of mind

**Future feature request**:
- Multi-pet support planned for future versions
- Multiple Watch pairing to single iPhone
- Different colors/markers for each pet on map
- If interested, provide feedback (see Support section)

**Best practices for multi-pet households**:
- Always have visual on untracted pets
- Use leashes during high-risk situations
- Recall training for all pets
- PetTracker as supplement, not replacement, for supervision

---

## Frequently Asked Questions

### General Questions

**Q: Do I need a cellular Apple Watch?**

A: No, a GPS-only Apple Watch works perfectly. PetTracker uses Bluetooth to communicate between your Watch and iPhone, not cellular networks. Cellular capability is not required and provides no benefit for pet tracking.

**Q: Does it work indoors?**

A: GPS works best outdoors with clear sky view. Indoor accuracy is significantly limited because GPS signals cannot penetrate buildings effectively. You may get occasional GPS fixes near windows, but indoor tracking is not reliable. PetTracker is designed for outdoor use (yards, parks, trails, beaches).

**Q: How far away can my pet go?**

A: There's no distance limit for GPS tracking itself. However, Bluetooth range affects how quickly you receive updates:

- **Within 30 feet (Bluetooth range)**: Real-time updates (<100ms latency)
- **Beyond 30 feet (out of Bluetooth range)**: Queued updates delivered when connection restored
- **Any distance**: GPS continues tracking, location delivered when devices reconnect

GPS itself works at any distance (even miles away), but you'll need to return within Bluetooth range to retrieve queued location data.

**Q: Can I use it for other things besides pets?**

A: Absolutely! PetTracker works great for:
- Tracking kids during outdoor activities (skiing, hiking, biking)
- Monitoring elderly family members during walks
- Tracking hiking companions who spread out on trail
- Keeping tabs on yourself (leave iPhone at camp, track your position)
- Vehicle tracking (place Watch in car or bike)

Any scenario where you need to track a GPS-equipped Watch works.

**Q: Do I need internet or cell service?**

A: No! PetTracker works completely offline via Bluetooth. No internet, WiFi, or cellular service required. Perfect for remote hiking, camping, or areas without cell coverage. All communication happens directly between iPhone and Apple Watch via Bluetooth.

**Q: How accurate is the GPS?**

A: Typical accuracy is ±10 meters (±30 feet) horizontal under good conditions. Accuracy depends on:

**Good conditions** (±5-10m):
- Open outdoor areas
- Clear sky view
- Minimal obstructions

**Fair conditions** (±10-20m):
- Light tree cover
- Near buildings
- Overcast weather

**Poor conditions** (±20m+):
- Dense forest
- Urban canyons
- Indoor or underground

**Q: Can I see where my pet has been?**

A: Yes! PetTracker displays a trail on the map showing the last 100 GPS positions. You can see the path your pet has taken, with timestamps and accuracy for each position. However, history is not currently saved between sessions or exported (future feature planned).

**Q: Does it drain my iPhone battery?**

A: Minimal impact. iPhone battery drain is typically less than 5% per hour when running PetTracker. The Watch does the heavy GPS work; iPhone only displays data. Keep iPhone app in foreground for best performance with minimal additional drain.

**Q: Is my data private?**

A: Yes, completely private. All location data stays on your devices only. Nothing is uploaded to cloud servers, no account required, no tracking by third parties. When you stop tracking or delete the app, all data is erased permanently.

**Q: Can I export location data?**

A: Not yet. Location export (GPX format) is a planned future feature. Currently, you can view the trail on the map and take screenshots, but structured export is not available in version 0.1.0.

### Setup and Configuration

**Q: How do I pair my Apple Watch if I haven't already?**

A:
1. Open **Watch** app on iPhone
2. Tap **"Start Pairing"**
3. Hold iPhone camera over Watch animation
4. Follow on-screen setup instructions
5. Choose wrist, create passcode, sign in with Apple ID
6. Wait for pairing and sync (5-15 minutes)
7. Apps automatically install on Watch

**Q: What permissions does PetTracker need?**

A:

**iPhone**:
- **Location Services**: "While Using" or "Always" (for your position)
- **Bluetooth**: Required (for Watch communication)

**Apple Watch**:
- **Location Services**: "Always" (for pet GPS tracking)
- **HealthKit**: "Workouts" (for extended GPS runtime via workout sessions)
- **Motion & Fitness**: Optional (for activity data)

All permissions are necessary for core functionality.

**Q: Can I use an older Apple Watch?**

A: PetTracker requires Apple Watch Series 4 or later with GPS capability. Older models (Series 0-3) may lack GPS or sufficient performance. Watch Series 4 (2018) and newer are supported.

**Q: Do both devices need to be on the latest OS?**

A: Yes. PetTracker requires iOS 26.0+ and watchOS 26.0+. These versions include necessary WatchConnectivity and location APIs. Update both devices to the latest OS before installing PetTracker.

**Q: How do I update my Apple Watch?**

A:
1. Place Watch on charger
2. Connect to WiFi
3. iPhone: Open **Watch** app
4. Tap **General** > **Software Update**
5. Download and install available updates
6. Wait 15-30 minutes for installation

### Usage and Features

**Q: Can I track multiple pets at once?**

A: Not currently. PetTracker supports one Apple Watch (one pet) per iPhone. To track multiple pets, you'd need separate iPhones and Watches for each pet. Multi-pet support is a requested feature for future versions.

**Q: What happens if Bluetooth disconnects?**

A: Watch continues tracking and queues location updates. When Bluetooth reconnects, queued data is automatically delivered to iPhone. No location data is lost during disconnection. This is normal and expected when devices separate beyond Bluetooth range.

**Q: Can I track my pet while my iPhone is in my pocket or bag?**

A: Yes! iPhone doesn't need to be in hand. Keep app open (can lock screen), and put iPhone in pocket, bag, or backpack. Bluetooth works through fabric and bags. Updates continue as long as app is running.

**Q: How long does the Watch battery last while tracking?**

A: Typical battery life is 8-12 hours of continuous GPS tracking. Factors affecting battery life:
- Watch model (newer = better battery)
- Battery health (degrades over 2-3 years)
- Temperature (cold reduces battery)
- Screen use (Theater Mode saves battery)
- Movement (stationary = slightly better battery)

**Q: Can I use the Watch for other things while tracking?**

A: Not recommended. Running other apps while tracking increases battery drain and may interfere with GPS. Close all other Watch apps before starting PetTracker for best results. After tracking stops, use Watch normally.

**Q: What happens if the Watch battery dies while tracking?**

A: Tracking stops and last known location is displayed in iPhone app. You can use last known coordinates to search area. Always monitor battery and plan return trip before battery reaches critical levels (10%).

### Technical Questions

**Q: What is "WatchConnectivity" and why does it matter?**

A: WatchConnectivity is Apple's framework for communication between iPhone and Apple Watch. PetTracker uses three delivery methods:

1. **Interactive Messages**: Fast (<100ms) when both apps in foreground
2. **Application Context**: Background updates (~0.5s throttle)
3. **File Transfer**: Guaranteed delivery with automatic retry

This ensures reliable data delivery regardless of app state or Bluetooth range.

**Q: Why does it say "Watch not reachable" when tracking works fine?**

A: "Not reachable" means devices are beyond Bluetooth range or iPhone app is backgrounded. This is normal and expected. Watch still tracks and sends data via Application Context or queued File Transfer. "Not reachable" is NOT an error - it's how the system operates during background tracking.

**Q: What is GPS "accuracy" and why does it vary?**

A: Accuracy is the uncertainty radius around the GPS position. "±10m accuracy" means true position is within 10 meters of displayed position. Lower number = more precise. Accuracy varies based on satellite geometry, sky visibility, obstructions, and atmospheric conditions.

**Q: Why does the first GPS fix take so long?**

A: First GPS acquisition (cold start) requires Watch to:
1. Download current satellite almanac data
2. Acquire signals from 4+ satellites
3. Calculate precise position

This process takes 30-60 seconds outdoor. Subsequent fixes (warm/hot starts) are faster (5-20 seconds) because satellite data is already cached.

**Q: Can I use PetTracker with Android?**

A: No. PetTracker requires Apple Watch and iPhone. It uses Apple-specific frameworks (WatchConnectivity, HealthKit) that don't exist on Android. An Android version would require complete rewrite and is not currently planned.

**Q: Does PetTracker work with third-party GPS trackers?**

A: No. PetTracker is designed specifically for Apple Watch as the GPS source. It does not integrate with other GPS devices, collars, or trackers. However, you can use PetTracker alongside other trackers for redundancy.

### Troubleshooting

**Q: What should I do if tracking doesn't start?**

A:
1. Verify permissions granted (Location, HealthKit)
2. Ensure Watch and iPhone are paired
3. Check Bluetooth is enabled on iPhone
4. Restart both Watch and iPhone
5. Verify both devices on latest OS
6. Try outdoor location with clear sky view
7. Wait 60 seconds for GPS acquisition

**Q: Why is my distance always showing "--"?**

A: Distance requires GPS on both iPhone and Watch. Check:
1. iPhone Location Services enabled
2. PetTracker has "While Using" permission
3. iPhone GPS acquired (blue dot on map)
4. Watch GPS acquired (red dot on map)
5. Keep iPhone app in foreground

**Q: The Stop button doesn't respond. What's wrong?**

A: If Stop button is unresponsive for more than 1 second, force-quit and restart app:
1. Press Digital Crown on Watch
2. Find PetTracker in app grid
3. Swipe up on app to force quit
4. Relaunch PetTracker
5. Tracking should stop
6. If issue persists, restart Watch

**Q: Can I reset the app if something goes wrong?**

A: Yes:

**Soft reset** (clears session data):
- Stop tracking
- Close app (swipe up on iPhone, force quit on Watch)
- Relaunch app

**Hard reset** (clears all data):
- Delete PetTracker from iPhone (holds app icon > Remove App)
- Delete PetTracker from Watch (Watch app > scroll to PetTracker > delete)
- Restart both devices
- Reinstall PetTracker from App Store
- Re-grant permissions

---

## Specifications

### System Requirements

**iPhone**:
- Model: iPhone 12 or later
- Operating System: iOS 26.0 or later
- Storage: 50 MB free space
- Bluetooth: Bluetooth 5.0 or later
- GPS: Built-in GPS required

**Apple Watch**:
- Model: Apple Watch Series 4 or later
- Operating System: watchOS 26.0 or later
- Storage: 20 MB free space
- GPS: Built-in GPS required (cellular not required)
- Pairing: Must be paired to iPhone

**Connectivity**:
- Bluetooth pairing between iPhone and Apple Watch
- No WiFi, internet, or cellular required

### GPS Performance

**Accuracy**:
- Typical horizontal accuracy: ±10 meters (±30 feet)
- Best-case accuracy: ±5 meters (±15 feet)
- Altitude accuracy: ±15 meters (±50 feet)
- Speed accuracy: ±0.5 m/s

**Update Rate**:
- GPS capture frequency: ~1 Hz (every 1 second)
- Transmission rate: ~2 Hz max (0.5s throttle via Application Context)
- Interactive message rate: <100ms latency (when reachable)

**Acquisition Time**:
- Cold start (first use): 30-60 seconds outdoor
- Warm start (recent GPS use): 10-20 seconds
- Hot start (GPS recently active): 5-10 seconds

**Coverage**:
- Works worldwide (GPS, GLONASS, Galileo satellites)
- No geofencing or regional restrictions
- Optimized for outdoor use

### Battery Life

**Apple Watch** (continuous GPS tracking):
- Typical runtime: 8-12 hours
- Minimum expected: 6 hours (older Watch models)
- Maximum observed: 14 hours (newer models, optimal conditions)

**Factors affecting Watch battery**:
- Watch model and age
- Battery health (degrades 2-3 years)
- Screen use (Theater Mode extends life)
- Temperature (cold reduces 20-30%)
- GPS signal strength

**iPhone** (displaying tracking data):
- Battery drain: <5% per hour
- Minimal impact vs normal use
- Drain increases if screen always on

**Battery optimization features**:
- Adaptive GPS throttling (stationary pets use less power)
- Low battery mode (automatic at 20%)
- Critical battery mode (automatic at 10%)
- Background operation reduces drain

### Supported Features

**Real-Time Tracking**:
- Live GPS position updates
- Distance calculation (you to pet)
- Accuracy monitoring
- Speed calculation
- Altitude display

**Data Transmission**:
- Triple-path WatchConnectivity messaging
- Interactive messages (foreground, <100ms)
- Application Context (background, ~0.5s throttle)
- File transfer (guaranteed delivery)

**Battery Monitoring**:
- Watch battery percentage display
- Low battery warnings (20%, 10%)
- Battery level transmitted to iPhone
- Drain rate calculation

**Location History**:
- Last 100 GPS fixes stored
- Trail visualization on map
- Timestamp and accuracy for each fix
- In-memory storage (not saved to disk)

**Privacy Features**:
- On-device processing only
- No cloud storage or upload
- No account or login required
- All data cleared on app deletion

### Not Yet Supported

**Planned Future Features**:
- Geofencing and safe zone alerts
- Location data export (GPX format)
- Multi-pet tracking (multiple Watches)
- Historical trail replay
- Route planning and waypoints
- Activity statistics (distance, time, speed)
- Offline map tile downloads

**Not Planned**:
- Cloud storage or syncing
- Web dashboard or remote access
- Integration with third-party GPS devices
- Android version
- Cellular tracking (without iPhone)

### Data Specifications

**Location Fix Data**:
- JSON format (~200-300 bytes per fix)
- Fields: latitude, longitude, altitude, accuracy, speed, course, heading, battery, timestamp, sequence
- Encoding: Compact field names for minimal payload
- 100-fix buffer: ~20-30 KB total memory

**Transmission Protocol**:
- WatchConnectivity framework (Apple proprietary)
- Encrypted Bluetooth Low Energy (BLE)
- Automatic retry on failure
- Queued delivery for offline periods

**Storage**:
- In-memory only (RAM)
- No persistent storage to disk
- Cleared on app termination
- Maximum 100 fixes retained

---

## Support & Feedback

### Getting Help

**Check documentation first**:
1. Review this User Guide (you're reading it!)
2. Check [Troubleshooting](#troubleshooting) section
3. Review [FAQ](#frequently-asked-questions)
4. Read app-specific error messages

**Search for known issues**:
- Browse GitHub Issues (if project is open source)
- Search community forums or discussions
- Check release notes for known bugs

**Technical documentation** (developers):
- See `/docs/PHYSICAL_DEVICE_TESTING.md` for device testing
- See `/docs/architecture/` for design documentation
- See `CLAUDE.md` for development guidelines
- See `README.md` for project overview

### Reporting Bugs

**If you encounter a bug**:

1. **Verify it's reproducible**:
   - Can you make the bug happen again?
   - Does it happen consistently?
   - What are the exact steps to trigger it?

2. **Collect information**:
   - iOS version (Settings > General > About > Software Version)
   - watchOS version (Watch Settings > General > About > Version)
   - iPhone model
   - Apple Watch model
   - PetTracker version (check App Store)

3. **Document the issue**:
   - What happened (expected vs actual behavior)
   - Steps to reproduce
   - Screenshots or screen recordings
   - Console logs (if technical user)

4. **Report via GitHub Issues** (when project published):
   - Search existing issues first (avoid duplicates)
   - Create new issue with template
   - Include all collected information
   - Be detailed and specific

**Example bug report**:
```
Title: "Distance shows '--' despite both GPS signals acquired"

Description:
Expected: Distance should display in meters
Actual: Distance shows "--" continuously

Steps to reproduce:
1. Launch PetTracker on iPhone (iOS 26.0, iPhone 14)
2. Launch PetTracker on Watch (watchOS 26.0, Series 7)
3. Tap "Start Tracking" on Watch
4. Wait 60 seconds for GPS acquisition
5. Both devices show GPS acquired (<10m accuracy)
6. Distance remains "--" on iPhone

Screenshots: [attached]
Console logs: [attached]
```

### Feature Requests

**Have an idea for improvement?**

**Before requesting**:
- Check if already planned (see [Not Yet Supported](#not-yet-supported))
- Search existing feature requests (avoid duplicates)
- Consider if it aligns with PetTracker's mission

**Submit feature request via GitHub Issues**:
- Use "Feature Request" template
- Describe the feature clearly
- Explain the use case (why you need it)
- Provide examples or mockups if applicable

**Popular feature ideas**:
- Geofencing and safe zone alerts
- Multi-pet tracking support
- Location data export (GPX)
- Offline map tiles
- Historical trail replay
- Activity statistics and reports

### Contributing

**Want to contribute?**

**For developers**:
- Review `CONTRIBUTING.md` (if available)
- Check open issues labeled "good first issue"
- Fork repository and submit pull requests
- Follow code style and guidelines (`CLAUDE.md`)
- Include tests with new features

**For non-developers**:
- Report bugs and issues
- Request features
- Test beta versions
- Improve documentation
- Share your tracking stories

### Community and Social

**Share your experience**:
- Rate PetTracker on App Store (when published)
- Write App Store review sharing your story
- Share screenshots on social media (tag us!)
- Recommend to fellow pet owners

**Stay updated**:
- Watch GitHub repository for releases (when published)
- Follow development blog or Twitter (if available)
- Subscribe to mailing list for announcements

### Privacy Policy

**PetTracker Privacy Commitment**:

**We do NOT collect**:
- Location data (stays on your devices)
- Personal information (name, email, phone)
- Usage analytics or telemetry
- Crash reports (unless you opt-in to share with Apple)

**We do NOT share**:
- Any data with third parties
- Location data with servers or cloud
- User information with advertisers

**We do NOT require**:
- Account creation or login
- Email address or phone number
- Payment or subscription

**Your data belongs to you**:
- Complete control over location data
- Delete anytime by stopping tracking or deleting app
- No data retention after app deletion
- No cloud backup or recovery

**Permissions explained**:
- Location Services: Required for GPS tracking (stays local)
- HealthKit: Required for workout session (battery optimization)
- Bluetooth: Required for Watch communication (encrypted)

For detailed privacy policy (when app is published), visit App Store listing.

### Contact Information

**Project maintainer**: [To be determined]

**Support email**: [To be determined]

**GitHub repository**: [To be determined]

**Website**: [To be determined]

---

## Appendix: Quick Reference Cards

### Quick Start Checklist

**Before First Use**:
- [ ] Install PetTracker on iPhone and Watch
- [ ] Pair Apple Watch to iPhone (if not already paired)
- [ ] Grant Location permission ("Always" on Watch, "While Using" on iPhone)
- [ ] Grant HealthKit permission on Watch
- [ ] Charge both devices to 80%+

**Every Tracking Session**:
- [ ] Charge Watch to 80%+ (100% for long sessions)
- [ ] Attach Watch securely to pet collar (test attachment)
- [ ] Hold Watch outdoor, tap "Start Tracking"
- [ ] Wait 30-60 seconds for GPS acquisition (accuracy <10m)
- [ ] Verify GPS icon solid (not flashing)
- [ ] Check battery indicator shows adequate charge
- [ ] Let pet roam, monitor on iPhone
- [ ] Check Watch attachment every 15-30 minutes
- [ ] Monitor battery level regularly
- [ ] Tap "Stop Tracking" when done
- [ ] Remove Watch from pet collar
- [ ] Recharge Watch for next use

### Troubleshooting Quick Reference

| Problem | Quick Fix |
|---------|-----------|
| "Watch not reachable" | Normal if backgrounded; bring devices within 10 feet |
| "Location permission denied" | Settings > PetTracker > Location > "While Using" |
| GPS won't acquire | Go outdoor, clear sky view, wait 60s |
| Distance shows "--" | Enable iPhone Location Services, keep app foreground |
| Stop button unresponsive | Force quit app, restart Watch |
| Poor battery (<6 hours) | Check battery health, close other apps, Theater Mode |
| Slow GPS acquisition | Pre-warm GPS before attaching to pet |

### Battery Life Quick Reference

| Watch Battery | Expected Runtime | Action |
|---------------|------------------|--------|
| 100% | 10-12 hours | Full day tracking |
| 80% | 8-10 hours | Extended session |
| 50% | 4-6 hours | Half-day session |
| 30% | 2-3 hours | Short session, plan return |
| 20% | 1-2 hours | Warning: stop soon |
| 10% | <1 hour | Critical: stop immediately |

### GPS Accuracy Quick Reference

| Accuracy | Display | Quality | Recommended Action |
|----------|---------|---------|-------------------|
| ±5m or less | <±5m | Excellent | Ideal tracking conditions |
| ±5-10m | <±10m | Good | Normal tracking, reliable |
| ±10-20m | <±20m | Fair | Usable, expect some drift |
| ±20m+ | <±20m+ | Poor | Move to open area, wait |

---

**Version**: 0.1.0
**Last Updated**: 2025-11-08
**Document**: USER_GUIDE.md

**Thank you for using PetTracker! Happy tracking!**
