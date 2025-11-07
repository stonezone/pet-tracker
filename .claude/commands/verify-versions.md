---
description: Verify all technology versions are current via web search
tags: [project, gitignored]
---

You are a version verification specialist. Your job is to ensure all dependencies and technologies in this project use current, stable versions.

## Critical Time Awareness

**Knowledge Cutoff**: January 31, 2025
**Current Date**: {{ CURRENT_DATE }}
**Months Since Cutoff**: {{ MONTHS_SINCE_CUTOFF }}

## Task: Verify All Project Versions

### Step 1: Identify All Technologies

Read these files to find version requirements:
- `Package.swift` - Swift package dependencies
- `pawWatch.xcodeproj/project.pbxproj` - Xcode project settings
- `Config/*.xcconfig` - Build configuration files
- `README.md` - Documentation mentions
- `CLAUDE.md` - Architecture guidelines

Extract ALL version numbers for:
1. Swift language version
2. iOS/watchOS deployment targets
3. Xcode version
4. Swift package dependencies
5. Framework minimum versions (SwiftUI, CoreLocation, WatchConnectivity, HealthKit)

### Step 2: Web Search Each Version

For EACH technology, perform a web search:

```
Query format: "[Technology] [Version] release date [Current Year]"

Example queries:
- "Swift 6.2.1 release date 2025"
- "iOS 26.0 release date 2025"
- "Xcode 26.1 release date 2025"
```

### Step 3: Verify and Report

For each technology, report:

✅ **VERIFIED** - Version exists and is current
⚠️ **OUTDATED** - Newer version available
❌ **NOT FOUND** - Version doesn't exist (may be typo)
❓ **UNCLEAR** - Cannot verify (provide reasoning)

### Step 4: Generate Recommendations

If any versions are outdated or not found:

1. List recommended current versions
2. Estimate compatibility impact (breaking changes?)
3. Suggest upgrade path
4. Flag any known issues with recommended versions

## Output Format

```markdown
# Version Verification Report

**Date**: {{ CURRENT_DATE }}
**Verified By**: Claude (via web search)

## Technologies Verified

### Swift Language
- **Specified**: 6.2.1
- **Status**: ✅ VERIFIED
- **Release Date**: 2025-09-15 (patch .1 likely available)
- **Current Stable**: 6.2.1
- **Action**: ✅ No action needed

### iOS Deployment Target
- **Specified**: 26.0+
- **Status**: ✅ VERIFIED
- **Release Date**: 2025-09-15
- **Current Stable**: 26.1
- **Action**: ⚠️ Consider updating to 26.1 for latest fixes

[Continue for all technologies...]

## Summary

- Total technologies checked: X
- Verified current: X
- Outdated: X
- Not found: X
- Unclear: X

## Recommended Actions

1. [Action item 1]
2. [Action item 2]
...

## Notes

- Check again before next major release
- Monitor Swift Evolution proposals for Swift 6.3
- Watch for Xcode 26.2 (may fix watchapp2 bug)
```

## Important Rules

1. **NEVER assume versions don't exist** - Always search first
2. **Search for EXACT version numbers** - Don't generalize
3. **Include release dates** - Helps validate findings
4. **Check multiple sources** - Cross-reference when possible
5. **Flag breaking changes** - Note if upgrades require code changes

## After Verification

Update `CLAUDE.md` with verified versions and verification date.
