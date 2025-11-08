#!/bin/bash
set -e

echo "🧪 Running PetTracker test suite..."
echo ""

# Change to package directory
cd "$(dirname "$0")/../PetTrackerPackage"

# Run tests with options
if [ "$1" == "--coverage" ]; then
  echo "📊 Running tests with coverage..."
  swift test --enable-code-coverage

  # Find and display coverage data location
  PROFDATA=$(find .build -name "*.profdata" | head -1)
  if [ -n "$PROFDATA" ]; then
    echo ""
    echo "✅ Coverage data generated: $PROFDATA"
    echo ""
    echo "To view coverage report, run:"
    echo "  xcrun llvm-cov show .build/debug/PetTrackerFeaturePackageTests.xctest/Contents/MacOS/PetTrackerFeaturePackageTests -instr-profile=$PROFDATA"
  fi

elif [ "$1" == "--filter" ]; then
  if [ -z "$2" ]; then
    echo "❌ Error: --filter requires a test name pattern"
    echo "Usage: $0 --filter <pattern>"
    exit 1
  fi

  echo "🔍 Running filtered tests: $2"
  swift test --filter "$2"

elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  (no args)       Run all tests"
  echo "  --coverage      Run tests with code coverage"
  echo "  --filter NAME   Run tests matching NAME pattern"
  echo "  --help, -h      Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Run all tests"
  echo "  $0 --coverage                         # Run with coverage"
  echo "  $0 --filter LocationFixTests          # Run LocationFix tests only"
  exit 0

else
  if [ -n "$1" ]; then
    echo "❌ Unknown option: $1"
    echo "Run '$0 --help' for usage information"
    exit 1
  fi

  echo "🚀 Running all tests..."
  swift test
fi

echo ""
echo "✅ Tests completed!"
