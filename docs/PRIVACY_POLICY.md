# Privacy Policy for PetTracker

**Effective Date**: 2025-11-08
**Last Updated**: 2025-11-08
**Version**: 1.0.0

---

## Overview

PetTracker is designed with privacy as a core principle. We believe your pet's location is your business, and nobody else's.

**Our Promise**: Your data never leaves your devices. Period.

---

## What We Collect

**The Short Answer**: NOTHING.

**The Long Answer**: PetTracker does not collect, store, transmit, or process any user data on external servers. All data remains exclusively on your personal devices (iPhone and Apple Watch).

### Location Data

**What Happens**:
- Your Apple Watch captures GPS coordinates when you start tracking
- GPS data is transmitted locally to your iPhone via Bluetooth (WatchConnectivity)
- Location coordinates are displayed on your iPhone screen
- Location history is stored temporarily in device memory (last 100 GPS fixes)

**What Does NOT Happen**:
- GPS coordinates are NOT uploaded to any server
- GPS coordinates are NOT shared with third parties
- GPS coordinates are NOT stored in the cloud
- GPS coordinates are NOT used for analytics or advertising

**Storage Duration**:
- Location history: Stored temporarily in memory
- Cleared when: You close the app or when the 100-fix buffer is exceeded
- Optional: Future versions may offer persistent local storage (still on-device only)

### Health Data

**What Happens**:
- PetTracker requests HealthKit permission to create workout sessions
- Workout sessions enable extended GPS runtime on Apple Watch
- HealthKit manages the workout session in the background

**What Does NOT Happen**:
- We do NOT access your health metrics (heart rate, steps, etc.)
- We do NOT read your health data
- We do NOT store any health information
- We do NOT transmit any health data

**Why We Need HealthKit**:
- Apple Watch GPS runs for ~20-30 minutes normally
- HealthKit workout sessions extend GPS runtime to 8-12 hours
- This is essential for all-day pet tracking
- We only use HealthKit for GPS extension, nothing else

### Battery Data

**What Happens**:
- PetTracker monitors Apple Watch battery level
- Battery percentage is displayed on your iPhone
- Battery warnings appear at 20% and 10%

**What Does NOT Happen**:
- Battery data is NOT transmitted to external servers
- Battery data is NOT stored persistently
- Battery data is NOT shared with third parties

### Connection Status

**What Happens**:
- PetTracker monitors WatchConnectivity session state
- Connection status (Connected, Reconnecting, Disconnected) is displayed

**What Does NOT Happen**:
- Connection status is NOT transmitted to external servers
- Connection logs are NOT stored externally
- Connection metadata is NOT analyzed or shared

---

## What We Do NOT Collect

To be absolutely clear, PetTracker does **NOT** collect:

- ❌ Personal information (name, email, phone number)
- ❌ Account credentials (no accounts exist)
- ❌ Payment information (app is free/one-time purchase)
- ❌ Device identifiers (UDID, IDFA, etc.)
- ❌ IP addresses
- ❌ Usage analytics
- ❌ Crash reports (unless you manually submit via TestFlight/Feedback)
- ❌ App usage patterns
- ❌ Feature usage statistics
- ❌ Search queries
- ❌ Contacts or address book
- ❌ Photos or media
- ❌ Microphone or camera data
- ❌ Browsing history
- ❌ Any other personal data

**Why**: We fundamentally believe in privacy by design. If we don't collect data, we can't lose it, sell it, or misuse it.

---

## Data Storage

### Local Storage Only

All data is stored **locally on your devices**:

**iPhone**:
- Location history: In-memory array (last 100 GPS fixes)
- Connection state: Transient WatchConnectivity state
- Battery level: Current value only

**Apple Watch**:
- GPS coordinates: Current fix only
- Workout session: Managed by HealthKit
- Battery level: System-provided value

### No Cloud Storage

PetTracker does **NOT** use:
- ❌ iCloud (no iCloud storage or sync)
- ❌ CloudKit (no cloud database)
- ❌ Remote servers (no backend infrastructure)
- ❌ Third-party cloud services (AWS, Google Cloud, Azure, etc.)
- ❌ Analytics services (Firebase, Mixpanel, etc.)
- ❌ Crash reporting services (Crashlytics, Sentry, etc.)

### Data Persistence

**Current Behavior (Version 1.0.0)**:
- Location history: Cleared when app terminates
- No persistent storage across app launches
- Fresh start every time you open the app

**Future Versions** (Planned):
- Optional persistent storage (still on-device only)
- User-controlled: Enable/disable in settings
- Export location history to GPX file (stays on your device)
- No cloud sync (ever)

---

## Data Sharing

**The Short Answer**: We share NOTHING.

**The Long Answer**: PetTracker does not share, sell, rent, trade, or otherwise transfer any data to third parties. There is no data to share because we don't collect any.

### No Third Parties

PetTracker does **NOT** integrate with:
- ❌ Analytics platforms (Google Analytics, Mixpanel, etc.)
- ❌ Advertising networks (AdMob, Facebook Ads, etc.)
- ❌ Social media platforms (Facebook SDK, Twitter SDK, etc.)
- ❌ Tracking services (Segment, Amplitude, etc.)
- ❌ Payment processors (not needed, no subscriptions)
- ❌ Customer support platforms (Zendesk, Intercom, etc.)
- ❌ Any other third-party services

### No Government Requests

Because we don't collect any data, we have **nothing to provide** in response to:
- Government data requests
- Law enforcement subpoenas
- Court orders
- National security letters

If we receive such requests, our response is: "We have no data to provide."

### No Sale of Data

We will **NEVER**:
- Sell your data to third parties
- Rent your data to advertisers
- Trade your data for services
- Monetize your data in any way

**Why**: We don't have your data to sell.

---

## Permissions Explained

PetTracker requires certain iOS/watchOS permissions to function. Here's what each permission is used for:

### Location Services (iOS & watchOS)

**Permission Level**: "Always Allow" (recommended) or "While Using App"

**Why We Need It**:
- **iPhone**: Calculate distance between you and your pet
- **Apple Watch**: Capture GPS coordinates for pet tracking

**What We Do With It**:
- Display pet location on iPhone screen
- Calculate distance in real-time
- Store last 100 GPS fixes in memory (temporary)

**What We DON'T Do With It**:
- Upload coordinates to any server
- Share location with third parties
- Track your movements (we only use it for distance calculation)

**User Control**:
- You can revoke permission in Settings > Privacy > Location Services
- App will not function without location access (core feature)

### HealthKit (watchOS Only)

**Permission Level**: Read access to Workout data

**Why We Need It**:
- Create workout sessions for extended GPS runtime
- Apple Watch GPS normally runs for ~20-30 minutes
- HealthKit workouts extend this to 8-12 hours

**What We Do With It**:
- Create "Outdoor Walk" workout session
- Keep GPS active during tracking session
- End workout when tracking stops

**What We DON'T Do With It**:
- Read your health metrics (heart rate, steps, etc.)
- Access your health history
- Store any health data
- Transmit any health information

**User Control**:
- You can revoke permission in Settings > Health > Data Access & Devices
- App will still function but GPS runtime will be limited to ~20-30 minutes

### WatchConnectivity (iOS & watchOS)

**Permission Level**: Automatic (no user prompt)

**Why We Need It**:
- Communication between iPhone and Apple Watch
- Transmit GPS coordinates from Watch to iPhone
- Send battery level from Watch to iPhone

**What We Do With It**:
- Local Bluetooth communication only
- No internet or cellular connection
- Data stays between your paired devices

**What We DON'T Do With It**:
- Transmit data over the internet
- Share data with external services
- Store communication logs externally

**User Control**:
- Managed automatically by iOS/watchOS
- No user action required
- Devices must be paired

---

## Security

### On-Device Processing

All data processing happens **on your devices**:
- GPS coordinates: Processed on Apple Watch
- Distance calculation: Processed on iPhone
- Location history: Stored in iPhone memory
- No server-side processing (because there's no server)

### Encryption

**Data in Transit** (Watch to iPhone):
- Encrypted by iOS/watchOS WatchConnectivity framework
- Bluetooth communication is encrypted by default
- No additional encryption needed (local network only)

**Data at Rest** (On Device):
- In-memory storage (not written to disk in v1.0.0)
- Protected by iOS/watchOS system security
- Device encryption (if enabled by user)

### No Attack Surface

Because PetTracker:
- Has no backend servers
- Doesn't transmit data over the internet
- Doesn't store data in the cloud
- Doesn't use third-party services

**Result**: There is no remote attack surface. Your data cannot be compromised by server hacks, data breaches, or man-in-the-middle attacks.

---

## Open Source Transparency

PetTracker is **fully open source**: [GitHub Repository](https://github.com/stonezone/pet-tracker)

**What This Means**:
- You can review the source code yourself
- Independent security researchers can audit the code
- Community can verify our privacy claims
- Complete transparency in what the app does

**Code Verification**:
- No hidden tracking code
- No obfuscated analytics
- No third-party SDKs
- Everything is visible and auditable

---

## Children's Privacy

**COPPA Compliance**: PetTracker is suitable for all ages, including children under 13.

**Why We're Compliant**:
- We don't collect any personal information
- We don't collect any data from children (or anyone else)
- We have no online features that interact with children
- We have no in-app purchases or subscriptions

**Parental Control**: Because we collect no data, there's nothing for parents to manage or monitor (from a data privacy perspective).

---

## International Privacy Laws

### GDPR (European Union)

**Compliance**: PetTracker is fully GDPR-compliant.

**Why**:
- **Data Minimization**: We collect zero data (ultimate minimization)
- **Purpose Limitation**: N/A (no data collected)
- **Storage Limitation**: Temporary in-memory storage only
- **Data Portability**: N/A (no data to export)
- **Right to Erasure**: N/A (no data to delete)
- **Right to Access**: N/A (no data to access)

### CCPA (California)

**Compliance**: PetTracker is fully CCPA-compliant.

**Why**:
- We do not sell personal information
- We do not collect personal information
- We do not share data with third parties

**CCPA Rights**: Not applicable (no personal information collected)

### Other Jurisdictions

PetTracker complies with privacy laws worldwide by **not collecting any data**. This is the simplest and most effective compliance strategy.

---

## Changes to This Privacy Policy

### Notification of Changes

If we ever change this privacy policy, we will:
1. Update the "Last Updated" date at the top of this document
2. Post the updated policy in the app and on GitHub
3. Notify users via app update notes (in App Store)

### Material Changes

Any **material changes** (e.g., starting to collect data) will require:
- Prominent in-app notification
- User consent before implementation
- Opt-in (not opt-out) mechanism

**Current Commitment**: We have no plans to collect data. Our business model does not require it.

---

## Your Rights

### Data Access

**Right to Access**: You have the right to know what data we have about you.
**Our Response**: We have no data about you.

### Data Deletion

**Right to Deletion**: You have the right to request deletion of your data.
**Our Response**: There is no data to delete.

### Data Portability

**Right to Export**: You have the right to export your data.
**Our Response**: Future versions may offer GPX export (local file, stays on your device).

### Opt-Out

**Right to Opt-Out**: You have the right to opt out of data collection.
**Our Response**: There is no data collection to opt out of.

---

## Contact Us

### Questions About Privacy

If you have questions about this privacy policy or how PetTracker handles data:

**Email**: [Your Contact Email]
**GitHub**: [Open an issue](https://github.com/stonezone/pet-tracker/issues)
**Website**: [Your Website URL]

### Reporting Privacy Concerns

If you believe PetTracker is violating this privacy policy:
1. Open a GitHub issue (public accountability)
2. Email us directly (confidential disclosure)
3. We will investigate and respond within 48 hours

---

## Legal

### Governing Law

This privacy policy is governed by the laws of [Your Jurisdiction].

### No Warranty

PetTracker is provided "as is" without warranty of any kind. While we strive for accuracy and reliability, we make no guarantees about GPS accuracy, battery life, or data integrity.

### Limitation of Liability

We are not liable for:
- Lost pets (PetTracker is a tool, not a guarantee)
- GPS inaccuracy (dependent on hardware and environment)
- Battery drain (GPS is inherently battery-intensive)
- Data loss (in-memory storage is temporary)

**Use Responsibly**: PetTracker is a tracking aid, not a replacement for responsible pet ownership.

---

## Summary (TL;DR)

**What PetTracker Collects**: Nothing
**What PetTracker Shares**: Nothing
**What PetTracker Stores in Cloud**: Nothing
**What PetTracker Sells**: Nothing

**What PetTracker Does**: Displays your pet's GPS location on your iPhone using local Bluetooth communication. All data stays on your devices.

**Open Source**: [GitHub Repository](https://github.com/stonezone/pet-tracker)

---

**Privacy Philosophy**: "The best way to protect your data is to not collect it in the first place."

---

**Document Version**: 1.0.0
**Effective Date**: 2025-11-08
**Last Updated**: 2025-11-08

---

**End of Privacy Policy**
