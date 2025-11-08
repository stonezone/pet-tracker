# Contributing to PetTracker

Thank you for your interest in contributing to PetTracker! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Setup](#development-setup)
- [Code Style Guidelines](#code-style-guidelines)
- [Git Workflow](#git-workflow)
- [Testing Requirements](#testing-requirements)
- [Quality Gates](#quality-gates)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Architecture Principles](#architecture-principles)

## Code of Conduct

This project follows Clean Architecture principles and maintains high code quality standards. All contributors are expected to:

- Write production-quality code with no placeholders
- Follow Swift best practices and conventions
- Maintain test coverage above 90%
- Ensure all tests pass before committing
- Write clear, descriptive commit messages

## Development Setup

### Prerequisites

- **macOS**: Latest version recommended
- **Xcode**: 26.1 or later
- **Swift**: 6.2 or later
- **Git**: Latest version

### Initial Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/stonezone/pet-tracker.git
   cd pet-tracker
   ```

2. Install Git hooks:
   ```bash
   ./scripts/install-hooks.sh
   ```

3. Open the workspace:
   ```bash
   open PetTracker.xcworkspace
   ```

4. Run tests to verify setup:
   ```bash
   ./scripts/run-tests.sh
   ```

## Code Style Guidelines

### Swift Conventions

- **No Force Unwrapping**: Use `guard`, `if let`, or optional chaining instead of `!`
- **No Print Statements**: Use `Logger` from `os.log` for debugging
- **No Placeholders**: No `TODO`, `FIXME`, or incomplete implementations
- **Swift Concurrency**: Use `async/await`, not GCD
- **@MainActor**: All UI updates must be on the main actor
- **Sendable**: All types crossing concurrency boundaries must conform to `Sendable`

### SwiftUI Best Practices

- **No ViewModels**: Use `@Observable` models directly
- **Task Lifecycle**: Use `.task {}` modifier, not `.onAppear { Task {} }`
- **State Management**: Keep state in models, not views
- **Minimal Views**: Views should only contain UI logic

### Naming Conventions

- **Types**: PascalCase (e.g., `LocationFix`, `PetLocationManager`)
- **Functions/Variables**: camelCase (e.g., `startTracking`, `latestLocation`)
- **Constants**: camelCase (e.g., `maxRetryCount`, not `MAX_RETRY_COUNT`)
- **Protocols**: Descriptive names (e.g., `LocationProviding`, not `ILocationProvider`)

## Git Workflow

### Branch Strategy

1. **master**: Production-ready code
2. **feature/**: New features (`feature/distance-alerts`)
3. **fix/**: Bug fixes (`fix/watchconnectivity-timeout`)
4. **refactor/**: Code improvements (`refactor/location-manager`)

### Creating a Branch

```bash
# Create feature branch from master
git checkout master
git pull origin master
git checkout -b feature/your-feature-name
```

### Making Changes

1. Make your changes in small, logical commits
2. Run tests frequently: `./scripts/run-tests.sh`
3. Check quality: `./scripts/quality-check.sh`
4. Commit with conventional commit messages (see below)

### Syncing with Master

```bash
# Update your branch with latest master
git checkout master
git pull origin master
git checkout feature/your-feature-name
git rebase master
```

## Testing Requirements

### Test-Driven Development (TDD)

All new features and bug fixes should follow TDD:

1. **Write failing test** that demonstrates the requirement
2. **Implement** the minimum code to pass the test
3. **Refactor** while keeping tests green
4. **Add tests** for edge cases

### Coverage Requirements

- **Business Logic**: >90% coverage
- **Services**: >90% coverage
- **Models**: 100% coverage (they're simple and critical)
- **Views**: >70% coverage (snapshot/preview testing)

### Running Tests

```bash
# Run all tests
./scripts/run-tests.sh

# Run with coverage
./scripts/run-tests.sh --coverage

# Run specific tests
./scripts/run-tests.sh --filter LocationFixTests
```

## Quality Gates

All contributions must pass these quality gates:

### Automated Checks (Pre-commit Hook)

- ✅ All tests pass
- ✅ No `print()` statements in source code
- ✅ No `TODO` or `FIXME` comments
- ⚠️  Force unwrap warning (review manually)

### CI/CD Checks (GitHub Actions)

- ✅ Swift Package builds successfully
- ✅ All tests pass with coverage enabled
- ✅ iOS app builds for simulator
- ✅ Quality gates pass (print, TODO, FIXME checks)
- ✅ Code coverage collected

### Manual Review

- Clean Architecture compliance
- SOLID principles followed
- No circular dependencies
- Proper error handling
- Documentation updated

## Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **docs**: Documentation changes
- **perf**: Performance improvements
- **style**: Code style changes (formatting)
- **chore**: Maintenance tasks

### Examples

```bash
# New feature
git commit -m "feat: add distance alerts for pet tracking"

# Bug fix
git commit -m "fix: resolve WatchConnectivity timeout issue"

# Refactoring
git commit -m "refactor: extract location validation into separate method"

# Tests
git commit -m "test: add LocationFix encoding tests"

# Documentation
git commit -m "docs: update WatchConnectivity setup guide"
```

### Multi-line Commits

```bash
git commit -m "feat: add battery monitoring for Watch app

- Add BatteryMonitor service to track Watch battery level
- Update LocationFix model to include battery percentage
- Add battery indicator to WatchContentView
- Include tests for battery state transitions

Resolves #42"
```

## Pull Request Process

### Before Creating a PR

1. **Ensure all tests pass**:
   ```bash
   ./scripts/run-tests.sh
   ```

2. **Run quality checks**:
   ```bash
   ./scripts/quality-check.sh
   ```

3. **Verify builds succeed**:
   ```bash
   ./scripts/build.sh
   ```

4. **Update documentation** if needed

5. **Rebase on latest master**:
   ```bash
   git checkout master
   git pull origin master
   git checkout feature/your-feature
   git rebase master
   ```

### Creating the PR

1. **Push your branch**:
   ```bash
   git push origin feature/your-feature
   ```

2. **Create PR** on GitHub with this template:

```markdown
## Summary

Brief description of what this PR does.

## Changes

- Bullet point list of changes
- Include affected components
- Note any breaking changes

## Testing

- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed
- [ ] Edge cases covered

## Quality Checks

- [ ] No print() statements
- [ ] No TODOs/FIXMEs
- [ ] No force unwraps (or documented why necessary)
- [ ] Test coverage >90%
- [ ] Follows Clean Architecture principles
- [ ] Documentation updated

## Related Issues

Closes #123
Relates to #456
```

### PR Review Process

1. **Automated checks** run via GitHub Actions
2. **Code review** by maintainers
3. **Address feedback** with new commits
4. **Squash and merge** once approved

### PR Checklist

Before requesting review, ensure:

- [ ] All CI checks pass
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No merge conflicts with master
- [ ] Commit messages follow conventional commits
- [ ] PR description is clear and complete

## Architecture Principles

### Clean Architecture Layers

```
Presentation (SwiftUI Views)
    ↓
Application (@Observable Models)
    ↓
Domain (Business Logic)
    ↓
Infrastructure (Platform Services)
```

**Rule**: Dependencies flow INWARD only.

### Module Boundaries

- **Domain Layer**: No framework dependencies (pure Swift)
- **Application Layer**: Coordinates use cases, manages state
- **Infrastructure Layer**: Platform-specific code (CoreLocation, WatchConnectivity)
- **Presentation Layer**: SwiftUI views, no business logic

### Key Patterns

1. **@Observable Models**: Replace ViewModels for reactive state
2. **Triple-path Messaging**: Application Context + Interactive Messages + File Transfer
3. **Sendable Conformance**: All types crossing concurrency boundaries
4. **@MainActor Isolation**: All UI updates on main thread
5. **Error Handling**: Guard statements, no force unwraps

## Anti-Patterns (Never Do This)

### ❌ Placeholders

```swift
// BAD
func calculateDistance() -> Double {
    // TODO: Implement
    return 0.0
}

// GOOD
func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
    guard from.coordinate.isValid, to.coordinate.isValid else {
        return 0.0
    }
    return from.distance(from: to)
}
```

### ❌ Force Unwrapping

```swift
// BAD
let distance = petLocation!.distance(from: ownerLocation!)

// GOOD
guard let pet = petLocation, let owner = ownerLocation else {
    return nil
}
let distance = pet.distance(from: owner)
```

### ❌ ViewModels

```swift
// BAD
class LocationViewModel: ObservableObject {
    @Published var location: LocationFix?
}

// GOOD
@Observable
class PetLocationManager {
    var latestLocation: LocationFix?
}
```

### ❌ GCD (Grand Central Dispatch)

```swift
// BAD
DispatchQueue.main.async {
    updateUI()
}

// GOOD
@MainActor
func updateUI() {
    // Automatically on main thread
}
```

## Getting Help

- **Architecture Questions**: See `CLAUDE.md` for comprehensive guidelines
- **Setup Issues**: See `README.md` for quick start guide
- **Bug Reports**: Open an issue with detailed reproduction steps
- **Feature Requests**: Open an issue with use case description

## Resources

- [CLAUDE.md](CLAUDE.md) - Comprehensive development guidelines
- [README.md](README.md) - Project overview and setup
- [PROJECT_CHECKLIST.md](PROJECT_CHECKLIST.md) - Quality gates
- [docs/architecture/](docs/architecture/) - Architecture decision records

---

**Remember**: This is a production-quality project. Every contribution should be complete, tested, and follow SOLID principles. Excellence is the standard.
