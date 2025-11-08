#!/bin/bash
set -e

echo "🔍 Running pre-commit checks..."
echo ""

# Change to repository root
cd "$(git rev-parse --show-toplevel)"

# 1. Run tests
echo "📝 Running tests..."
cd PetTrackerPackage
if swift test --quiet 2>&1 | grep -q "Test run with"; then
  TESTS=$(swift test --quiet 2>&1 | grep "Test run with" | awk '{print $4}')
  echo "✅ All $TESTS tests passed"
else
  echo "❌ FAILED: Tests did not pass"
  echo "Run 'scripts/run-tests.sh' to see detailed test output"
  exit 1
fi
cd ..

echo ""

# 2. Check for print statements
echo "🔍 Checking for print() statements..."
if grep -r "print(" --include="*.swift" PetTrackerPackage/Sources/ 2>/dev/null; then
  echo "❌ FAILED: print() statements found. Use Logger instead."
  echo "Remove print() statements before committing."
  exit 1
else
  echo "✅ No print() statements found"
fi

echo ""

# 3. Check for TODOs
echo "🔍 Checking for TODOs/FIXMEs..."
if grep -r "TODO\|FIXME" --include="*.swift" PetTrackerPackage/Sources/ 2>/dev/null; then
  echo "❌ FAILED: TODOs/FIXMEs found in source code."
  echo "All code must be complete before committing."
  exit 1
else
  echo "✅ No TODOs/FIXMEs found"
fi

echo ""

# 4. Check for force unwraps (warning only)
echo "🔍 Checking for force unwraps..."
UNWRAPS=$(grep -rn "!" --include="*.swift" PetTrackerPackage/Sources/ 2>/dev/null | \
  grep -v "!=" | \
  grep -v "^[^:]*:[^:]*:.*//.*!" | \
  grep -v "^[^:]*:[^:]*:.*\bif !" | \
  grep -v "^[^:]*:[^:]*:.*\bguard !" | \
  grep -v "^[^:]*:[^:]*:.*\bwhile !" | \
  head -5 || true)

if [ -n "$UNWRAPS" ]; then
  echo "⚠️  WARNING: Potential force unwraps found (review manually):"
  echo "$UNWRAPS"
  echo ""
  echo "This is a warning only - commit will proceed."
else
  echo "✅ No force unwraps detected"
fi

echo ""
echo "✅ Pre-commit checks passed!"
echo ""
