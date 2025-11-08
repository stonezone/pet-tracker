#!/bin/bash
set -e

echo "🔧 Installing Git hooks..."
echo ""

# Change to repository root
cd "$(git rev-parse --show-toplevel)"

# Check if .git directory exists
if [ ! -d ".git" ]; then
  echo "❌ Error: Not a Git repository"
  exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
echo "📋 Installing pre-commit hook..."
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed"
echo ""

# Test the hook
echo "🧪 Testing pre-commit hook..."
if .git/hooks/pre-commit; then
  echo ""
  echo "✅ Git hooks installed successfully!"
  echo ""
  echo "The pre-commit hook will now run automatically before each commit."
  echo "It will check for:"
  echo "  - All tests passing"
  echo "  - No print() statements"
  echo "  - No TODOs/FIXMEs"
  echo "  - Force unwraps (warning only)"
  echo ""
  echo "To skip the hook (NOT recommended), use: git commit --no-verify"
else
  echo ""
  echo "⚠️  Hook installed but test run failed"
  echo "This is expected if tests are currently failing"
  echo "Fix the issues before attempting to commit"
fi
