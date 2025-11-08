#!/bin/bash
set -e

echo "🔍 Running comprehensive quality checks..."
echo ""

# Change to project root
cd "$(dirname "$0")/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILURES=0

# Run tests with coverage
echo "📝 Running tests with coverage..."
cd PetTrackerPackage
swift test --enable-code-coverage 2>&1 | tee test-output.txt
TEST_EXIT_CODE=${PIPESTATUS[0]}
cd ..

if [ $TEST_EXIT_CODE -ne 0 ]; then
  echo -e "${RED}❌ FAILED: Tests did not pass${NC}"
  FAILURES=$((FAILURES + 1))
else
  # Extract test count
  TESTS=$(grep "Test run with" PetTrackerPackage/test-output.txt | awk '{print $4}' || echo "Unknown")
  echo -e "${GREEN}✅ Tests passed: $TESTS tests${NC}"
fi

rm -f PetTrackerPackage/test-output.txt

# Check for anti-patterns
echo ""
echo "🔍 Checking for anti-patterns..."

# Check for print() statements
PRINTS=$(grep -r "print(" --include="*.swift" PetTrackerPackage/Sources/ 2>/dev/null | wc -l)
PRINTS=$(echo $PRINTS | xargs) # Trim whitespace

if [ "$PRINTS" -gt 0 ]; then
  echo -e "${RED}❌ FAILED: print() statements found${NC}"
  grep -rn "print(" --include="*.swift" PetTrackerPackage/Sources/ | head -5
  FAILURES=$((FAILURES + 1))
else
  echo -e "${GREEN}✅ No print() statements${NC}"
fi

# Check for TODOs/FIXMEs
TODOS=$(grep -r "TODO\|FIXME" --include="*.swift" PetTrackerPackage/Sources/ 2>/dev/null | wc -l)
TODOS=$(echo $TODOS | xargs) # Trim whitespace

if [ "$TODOS" -gt 0 ]; then
  echo -e "${RED}❌ FAILED: TODOs/FIXMEs found${NC}"
  grep -rn "TODO\|FIXME" --include="*.swift" PetTrackerPackage/Sources/ | head -5
  FAILURES=$((FAILURES + 1))
else
  echo -e "${GREEN}✅ No TODOs/FIXMEs${NC}"
fi

# Check for force unwraps (warning only)
UNWRAPS=$(grep -rn "!" --include="*.swift" PetTrackerPackage/Sources/ 2>/dev/null | \
  grep -v "!=" | \
  grep -v "^[^:]*:[^:]*:.*//.*!" | \
  grep -v "^[^:]*:[^:]*:.*\bif !" | \
  grep -v "^[^:]*:[^:]*:.*\bguard !" | \
  grep -v "^[^:]*:[^:]*:.*\bwhile !" | \
  wc -l || echo "0")
UNWRAPS=$(echo $UNWRAPS | xargs) # Trim whitespace

if [ "$UNWRAPS" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  WARNING: Potential force unwraps found: $UNWRAPS${NC}"
  echo "   (Review manually - this is a warning, not a failure)"
else
  echo -e "${GREEN}✅ No force unwraps detected${NC}"
fi

# Count files
FILES=$(find PetTrackerPackage/Sources -name "*.swift" -type f 2>/dev/null | wc -l)
FILES=$(echo $FILES | xargs) # Trim whitespace

# Display metrics
echo ""
echo "📊 Quality Metrics:"
echo "  Tests: $TESTS"
echo "  Print statements: $PRINTS (target: 0)"
echo "  TODOs/FIXMEs: $TODOS (target: 0)"
echo "  Force unwraps (potential): $UNWRAPS (review manually)"
echo "  Swift source files: $FILES"

# Final result
echo ""
if [ $FAILURES -eq 0 ]; then
  echo -e "${GREEN}✅ All quality checks passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ Quality checks failed with $FAILURES error(s)${NC}"
  exit 1
fi
