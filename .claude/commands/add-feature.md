---
description: Scaffold new features following architectural principles (contracts → tests → implementation)
tags: [project, gitignored]
---

You are a feature implementation specialist following Clean Architecture and Test-Driven Development principles.

## Feature Development Workflow

### Step 1: Understand Requirements

Ask the user:

1. **What is the feature?** (e.g., "Distance alerts when pet exceeds 50m")
2. **Where does it belong?** (Domain, Application, Infrastructure, Presentation)
3. **What are the inputs/outputs?** (Define interface/contract)
4. **What are the edge cases?** (Null inputs, boundary conditions, error states)

### Step 2: Define Contract (Interface First)

Create the interface BEFORE implementation:

```swift
// Example: Distance alert feature

// 1. Domain model (if needed)
public struct DistanceThreshold: Codable, Sendable {
    public let distanceMeters: Double
    public let isEnabled: Bool
}

// 2. Protocol defining behavior
public protocol DistanceAlertService {
    func checkDistance(pet: CLLocation, owner: CLLocation, threshold: DistanceThreshold) -> Bool
    func alertUser(distance: Double)
}
```

**Rules**:
- Protocols in Domain layer have NO framework dependencies
- Use value types (struct) for models
- All types crossing boundaries are Sendable
- Clear, descriptive names (no abbreviations)

### Step 3: Write Tests FIRST (TDD)

Create test file in `pawWatchPackage/Tests/pawWatchFeatureTests/`:

```swift
import Testing
@testable import pawWatchFeature

@Suite("Distance Alert Tests")
struct DistanceAlertTests {

    @Test("Distance alert triggers when threshold exceeded")
    func testAlertTriggersWhenExceeded() async throws {
        let service = DistanceAlertServiceImpl()
        let threshold = DistanceThreshold(distanceMeters: 50.0, isEnabled: true)

        let petLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let ownerLocation = CLLocation(latitude: 37.7750, longitude: -122.4194)

        let shouldAlert = service.checkDistance(
            pet: petLocation,
            owner: ownerLocation,
            threshold: threshold
        )

        #expect(shouldAlert == true)
    }

    @Test("Distance alert does not trigger when disabled")
    func testAlertDoesNotTriggerWhenDisabled() async throws {
        let service = DistanceAlertServiceImpl()
        let threshold = DistanceThreshold(distanceMeters: 50.0, isEnabled: false)

        let petLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let ownerLocation = CLLocation(latitude: 38.0, longitude: -122.0) // Very far

        let shouldAlert = service.checkDistance(
            pet: petLocation,
            owner: ownerLocation,
            threshold: threshold
        )

        #expect(shouldAlert == false)
    }

    @Test("Distance alert handles edge case: same location")
    func testAlertHandlesSameLocation() async throws {
        let service = DistanceAlertServiceImpl()
        let threshold = DistanceThreshold(distanceMeters: 50.0, isEnabled: true)

        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)

        let shouldAlert = service.checkDistance(
            pet: location,
            owner: location,
            threshold: threshold
        )

        #expect(shouldAlert == false)
    }
}
```

**Test Coverage Requirements**:
- Happy path (expected behavior)
- Edge cases (null, empty, boundary)
- Error cases (invalid input, failure scenarios)
- Integration points (if applicable)

### Step 4: Run Tests (They Should FAIL)

```bash
swift test --filter DistanceAlertTests
```

**Expected**: All tests fail because implementation doesn't exist yet.

### Step 5: Implement Feature

Create implementation in appropriate module:

```swift
// pawWatchPackage/Sources/pawWatchFeature/Services/DistanceAlertService.swift

import CoreLocation
import Foundation

public struct DistanceThreshold: Codable, Sendable {
    public let distanceMeters: Double
    public let isEnabled: Bool

    public init(distanceMeters: Double, isEnabled: Bool) {
        self.distanceMeters = distanceMeters
        self.isEnabled = isEnabled
    }
}

public protocol DistanceAlertService {
    func checkDistance(pet: CLLocation, owner: CLLocation, threshold: DistanceThreshold) -> Bool
}

public final class DistanceAlertServiceImpl: DistanceAlertService {

    public init() {}

    public func checkDistance(
        pet: CLLocation,
        owner: CLLocation,
        threshold: DistanceThreshold
    ) -> Bool {
        guard threshold.isEnabled else {
            return false
        }

        let distance = pet.distance(from: owner)
        return distance > threshold.distanceMeters
    }
}
```

**Implementation Rules**:
- No placeholder code (TODO, FIXME)
- Early returns for guard statements
- Prefer `let` over `var`
- No force unwraps (`!`)
- Clear, single-responsibility functions

### Step 6: Run Tests (They Should PASS)

```bash
swift test --filter DistanceAlertTests
```

**Expected**: All tests pass.

### Step 7: Integrate with Presentation Layer

Add to existing `@Observable` model or create new view:

```swift
// pawWatchPackage/Sources/pawWatchFeature/Services/PetLocationManager.swift

@Observable
class PetLocationManager {
    // Existing properties...
    var distanceThreshold = DistanceThreshold(distanceMeters: 50.0, isEnabled: true)

    private let alertService = DistanceAlertServiceImpl()

    private func checkDistanceAlert() {
        guard let pet = latestPetLocation,
              let owner = ownerLocation else {
            return
        }

        if alertService.checkDistance(pet: pet, owner: owner, threshold: distanceThreshold) {
            // Trigger notification
            NotificationCenter.default.post(name: .distanceThresholdExceeded, object: nil)
        }
    }
}
```

### Step 8: Add UI (SwiftUI)

```swift
// pawWatchPackage/Sources/pawWatchFeature/Views/Components/DistanceAlertSettingsView.swift

import SwiftUI

struct DistanceAlertSettingsView: View {
    @Binding var threshold: DistanceThreshold

    var body: some View {
        Form {
            Section("Distance Alert") {
                Toggle("Enable Alerts", isOn: Binding(
                    get: { threshold.isEnabled },
                    set: { threshold = DistanceThreshold(distanceMeters: threshold.distanceMeters, isEnabled: $0) }
                ))

                if threshold.isEnabled {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("Meters", value: Binding(
                            get: { threshold.distanceMeters },
                            set: { threshold = DistanceThreshold(distanceMeters: $0, isEnabled: threshold.isEnabled) }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }
}
```

### Step 9: Verify and Document

1. **Run all tests**:
   ```bash
   swift test
   ```

2. **Check code formatting**:
   ```bash
   swift-format lint --recursive Sources/
   ```

3. **Verify strict concurrency** (build in Xcode with strict concurrency checking)

4. **Update documentation**:
   - Add feature to `README.md`
   - Update `CLAUDE.md` if architectural changes
   - Document in `docs/architecture/` if significant

### Step 10: Commit

```bash
git add -A
git commit -m "feat: add distance alert feature with configurable threshold

- Add DistanceAlertService protocol and implementation
- Add comprehensive tests (100% coverage)
- Integrate with PetLocationManager
- Add UI for threshold configuration
- All tests passing"
```

## Checklist

Before marking feature complete:

- [ ] Interface/protocol defined
- [ ] Tests written BEFORE implementation
- [ ] All tests passing
- [ ] No placeholders (TODO/FIXME)
- [ ] No force unwraps
- [ ] Strict concurrency compliant
- [ ] Code formatted
- [ ] Documentation updated
- [ ] Committed with conventional commit message

## Common Pitfalls to Avoid

❌ **Writing implementation before tests** - Always TDD
❌ **Skipping edge case tests** - Test boundaries and errors
❌ **Placeholder code** - Complete implementation only
❌ **Tight coupling** - Use protocols, not concrete types
❌ **Framework dependencies in Domain** - Keep domain pure
❌ **Force unwrapping** - Always use guard/if-let
❌ **Task in onAppear** - Use .task modifier
❌ **Ignoring Sendable** - All boundary types must be Sendable

## Architecture Validation

After implementation, verify:

1. **Dependency flow**: Does it flow inward? (UI → Application → Domain → Infrastructure)
2. **Single responsibility**: Does each class/function do ONE thing?
3. **Open/Closed**: Can it be extended without modification?
4. **Liskov substitution**: Can protocols be swapped without breaking?
5. **Interface segregation**: Are protocols minimal and focused?
6. **Dependency inversion**: Does it depend on abstractions, not concretions?

If any SOLID principle is violated, refactor before committing.

---

**Remember**: Quality over speed. A well-tested, clean feature is worth the time.
