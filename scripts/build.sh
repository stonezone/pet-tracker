#!/bin/bash
set -e

echo "🏗️  Building PetTracker..."
echo ""

# Change to project root
cd "$(dirname "$0")/.."

# Parse arguments
BUILD_TARGET="all"
CLEAN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --package)
      BUILD_TARGET="package"
      shift
      ;;
    --ios)
      BUILD_TARGET="ios"
      shift
      ;;
    --clean)
      CLEAN=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  (no args)    Build both package and iOS app"
      echo "  --package    Build Swift Package only"
      echo "  --ios        Build iOS app only"
      echo "  --clean      Clean before building"
      echo "  --help, -h   Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                # Build everything"
      echo "  $0 --package      # Build package only"
      echo "  $0 --ios --clean  # Clean build iOS app"
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Run '$0 --help' for usage information"
      exit 1
      ;;
  esac
done

# Build Swift Package
if [ "$BUILD_TARGET" == "all" ] || [ "$BUILD_TARGET" == "package" ]; then
  echo "📦 Building Swift Package..."

  cd PetTrackerPackage

  if [ "$CLEAN" = true ]; then
    echo "  Cleaning..."
    swift package clean
  fi

  swift build
  echo "✅ Package build completed!"
  echo ""

  cd ..
fi

# Build iOS app
if [ "$BUILD_TARGET" == "all" ] || [ "$BUILD_TARGET" == "ios" ]; then
  echo "📱 Building iOS app..."

  # Check if xcpretty is available for prettier output
  if command -v xcpretty &> /dev/null; then
    FORMATTER="xcpretty"
  else
    FORMATTER="cat"
    echo "  (Tip: Install xcpretty for prettier output: gem install xcpretty)"
  fi

  if [ "$CLEAN" = true ]; then
    xcodebuild clean \
      -workspace PetTracker.xcworkspace \
      -scheme PetTracker \
      | $FORMATTER
  fi

  # Build for simulator (most common development target)
  xcodebuild build \
    -workspace PetTracker.xcworkspace \
    -scheme PetTracker \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    | $FORMATTER

  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ iOS app build completed!"
  else
    echo "❌ iOS app build failed"
    exit 1
  fi

  echo ""
fi

echo "✅ All builds completed successfully!"
