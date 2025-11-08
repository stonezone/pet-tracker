# CI/CD Pipeline Documentation

**Project**: PetTracker
**Created**: 2025-11-08
**Status**: Operational

---

## Overview

PetTracker has a comprehensive CI/CD pipeline that ensures code quality, enforces best practices, and automates testing. The pipeline runs on every push and pull request to the master branch.

---

## GitHub Actions Workflow

**File**: `.github/workflows/ci.yml`

### Jobs

#### 1. Build & Test
- Checks out code
- Selects Xcode 26.1 (if available)
- Builds Swift Package
- Runs all tests with code coverage
- Builds iOS app for simulator
- Uploads test results and coverage data

**Duration**: ~5-10 minutes

#### 2. Quality Gates
- Checks for `print()` statements (FAIL if found)
- Checks for `TODO`/`FIXME` comments (FAIL if found)
- Checks for force unwraps (WARN only)
- Verifies all tests passed
- Reports quality metrics

**Duration**: ~1-2 minutes

#### 3. Code Coverage
- Generates coverage report
- Parses profdata files
- Uploads coverage artifacts
- Validates coverage threshold (90%+)

**Duration**: ~2-3 minutes

#### 4. CI Status
- Aggregates results from all jobs
- Reports overall pipeline status
- Fails if any job failed

**Duration**: <10 seconds

### Triggers

- Push to `master` branch
- Pull requests targeting `master`

### Runner

- `macos-latest` (GitHub-hosted)
- Includes Xcode and Swift toolchain
- 30-minute timeout per job

---

## Pre-Commit Hooks

**File**: `scripts/pre-commit-hook.sh`
**Installation**: `scripts/install-hooks.sh`

### Checks Performed

1. **Run All Tests**
   - Executes full test suite
   - Fails commit if any test fails
   - Fast feedback (~10-20 seconds)

2. **Print Statement Check**
   - Scans source code for `print()` calls
   - Fails if found (use `Logger` instead)
   - Enforces production-ready code

3. **TODO/FIXME Check**
   - Scans source code for incomplete work markers
   - Fails if found
   - Ensures all code is complete

4. **Force Unwrap Check**
   - Scans for `!` operators (excluding `!=`, negation, comments)
   - Warning only (doesn't block commit)
   - Encourages safe optional handling

### Installation

```bash
./scripts/install-hooks.sh
```

This copies the hook to `.git/hooks/pre-commit` and makes it executable.

### Skipping Hooks

**NOT recommended**, but possible in emergencies:

```bash
git commit --no-verify
```

---

## Helper Scripts

### 1. Quality Check Script

**File**: `scripts/quality-check.sh`

Runs comprehensive quality checks including:
- All tests with coverage
- Anti-pattern detection
- Metrics reporting

**Usage**:
```bash
./scripts/quality-check.sh
```

**Output**:
- Test pass/fail status
- Test count
- Print statement count
- TODO/FIXME count
- Force unwrap count (warning)
- File count

**Exit Codes**:
- `0`: All checks passed
- `1`: One or more checks failed

---

### 2. Test Runner Script

**File**: `scripts/run-tests.sh`

Flexible test execution with multiple modes.

**Usage**:
```bash
# Run all tests
./scripts/run-tests.sh

# Run with coverage
./scripts/run-tests.sh --coverage

# Run filtered tests
./scripts/run-tests.sh --filter LocationFixTests

# Show help
./scripts/run-tests.sh --help
```

**Features**:
- Coverage report generation with profdata location
- Test filtering by name pattern
- Clear success/failure messaging

---

### 3. Build Script

**File**: `scripts/build.sh`

Builds Swift Package and/or iOS app.

**Usage**:
```bash
# Build everything
./scripts/build.sh

# Build package only
./scripts/build.sh --package

# Build iOS app only
./scripts/build.sh --ios

# Clean build
./scripts/build.sh --clean

# Show help
./scripts/build.sh --help
```

**Features**:
- Selective building (package, iOS, or both)
- Clean build option
- Prettier output with `xcpretty` (if installed)
- Simulator target (iPhone 17 Pro)

---

## Quality Gates

### Enforced Rules

| Rule | Check Type | Action |
|------|-----------|--------|
| All tests pass | Pre-commit, CI | FAIL |
| No `print()` statements | Pre-commit, CI | FAIL |
| No `TODO`/`FIXME` | Pre-commit, CI | FAIL |
| No force unwraps | Pre-commit, CI | WARN |
| Build succeeds | CI | FAIL |
| Test coverage >90% | CI | INFO |

### Bypass Mechanisms

**Pre-commit**: `git commit --no-verify` (NOT recommended)
**CI**: Cannot be bypassed (required for PR merge)

---

## Coverage Reporting

### Generation

Coverage data is generated using:
```bash
swift test --enable-code-coverage
```

This produces `.profdata` and `.profraw` files in `.build/` directory.

### Viewing Coverage

Using `llvm-cov`:
```bash
xcrun llvm-cov show \
  .build/debug/PetTrackerFeaturePackageTests.xctest/Contents/MacOS/PetTrackerFeaturePackageTests \
  -instr-profile=.build/debug/codecov/default.profdata
```

### Coverage Targets

- **Models**: 100% (simple, critical)
- **Services**: 90%+
- **Views**: 70%+
- **Overall**: 90%+

---

## Workflow Examples

### Adding a New Feature

1. Create feature branch:
   ```bash
   git checkout -b feature/distance-alerts
   ```

2. Write tests first (TDD):
   ```bash
   ./scripts/run-tests.sh --filter DistanceAlertTests
   ```

3. Implement feature

4. Run quality checks:
   ```bash
   ./scripts/quality-check.sh
   ```

5. Commit (pre-commit hook runs automatically):
   ```bash
   git commit -m "feat: add distance alerts"
   ```

6. Push (CI runs automatically):
   ```bash
   git push origin feature/distance-alerts
   ```

7. Create PR on GitHub
   - CI runs on PR
   - Review feedback
   - Merge when CI passes

### Fixing a Bug

1. Write failing test that reproduces bug:
   ```bash
   ./scripts/run-tests.sh --filter BugReproductionTest
   ```

2. Fix the bug

3. Verify test passes:
   ```bash
   ./scripts/run-tests.sh
   ```

4. Run quality checks:
   ```bash
   ./scripts/quality-check.sh
   ```

5. Commit and push:
   ```bash
   git commit -m "fix: resolve WatchConnectivity timeout"
   git push origin fix/watchconnectivity-timeout
   ```

### Before Release

1. Run full quality check:
   ```bash
   ./scripts/quality-check.sh
   ```

2. Build everything:
   ```bash
   ./scripts/build.sh --clean
   ```

3. Run tests with coverage:
   ```bash
   ./scripts/run-tests.sh --coverage
   ```

4. Verify all CI jobs pass

5. Tag release:
   ```bash
   git tag -a v1.0.0 -m "Release 1.0.0"
   git push origin v1.0.0
   ```

---

## Troubleshooting

### Pre-commit Hook Fails

**Problem**: Tests fail during commit

**Solution**:
1. Run tests manually: `./scripts/run-tests.sh`
2. Fix failing tests
3. Retry commit

### CI Job Fails

**Problem**: GitHub Actions workflow fails

**Solution**:
1. Check job logs in GitHub Actions tab
2. Reproduce issue locally:
   ```bash
   ./scripts/quality-check.sh
   ./scripts/build.sh
   ```
3. Fix issue
4. Push fix

### Coverage Not Generated

**Problem**: No profdata files found

**Solution**:
1. Ensure tests run with coverage flag:
   ```bash
   swift test --enable-code-coverage
   ```
2. Check `.build/debug/codecov/` directory
3. Verify test target builds successfully

### Xcode Version Mismatch

**Problem**: CI uses different Xcode version

**Solution**:
1. CI workflow attempts to select Xcode 26.1
2. Falls back to `macos-latest` default
3. Update workflow if specific version required

---

## Future Enhancements

### Planned Improvements

- [ ] Code coverage badge in README (codecov integration)
- [ ] Automated changelog generation
- [ ] Release notes automation
- [ ] Performance regression testing
- [ ] SwiftLint integration
- [ ] Dependency vulnerability scanning
- [ ] Automated App Store submission

### Integration Opportunities

- **codecov.io**: Coverage reporting and badges
- **Danger**: Automated PR feedback
- **SwiftLint**: Additional code style enforcement
- **fastlane**: Automated releases and screenshots

---

## Maintenance

### Updating Xcode Version

Edit `.github/workflows/ci.yml`:
```yaml
- name: Select Xcode version
  run: |
    if [ -d "/Applications/Xcode_26.2.app" ]; then
      sudo xcode-select -s /Applications/Xcode_26.2.app
    fi
```

### Updating Quality Checks

Edit `scripts/quality-check.sh` to add new checks:
```bash
# Example: Check for hardcoded strings
HARDCODED=$(grep -r "hardcoded_api_key" --include="*.swift" PetTrackerPackage/Sources/)
if [ -n "$HARDCODED" ]; then
  echo "❌ FAILED: Hardcoded API keys found"
  FAILURES=$((FAILURES + 1))
fi
```

### Updating Pre-commit Hook

1. Edit `scripts/pre-commit-hook.sh`
2. Re-run installation:
   ```bash
   ./scripts/install-hooks.sh
   ```

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Swift Testing Guide](https://developer.apple.com/documentation/xctest)
- [Code Coverage with Swift](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/07-code_coverage.html)

---

**Last Updated**: 2025-11-08
**Maintained By**: PetTracker Team
