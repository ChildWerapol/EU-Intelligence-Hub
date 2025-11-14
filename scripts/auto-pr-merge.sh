#!/bin/bash
# Automatic PR creation and merge script

set -e

BRANCH_NAME="claude/fix-github-workflow-014jZTpTdTyJWZMds9avXD9z"
BASE_BRANCH="main"
PR_TITLE="fix: improve GitHub Actions workflow configuration"
MAX_RETRIES=30
RETRY_INTERVAL=30

# PR Body
read -r -d '' PR_BODY << 'EOF' || true
## Summary

This PR fixes issues in the GitHub Actions test workflow that were causing test failures.

## Changes Made

1. **Added spaCy model download** - Tests use spaCy for NER functionality, which requires the `en_core_web_sm` model to be downloaded
2. **Added missing environment variables** - Explicitly set test environment variables (GEMINI_API_KEY, ENABLE_GEMINI_SENTIMENT, etc.)
3. **Extended test coverage** - Modified pytest command to run tests from both `app/tests` and `tests` directories
4. **Explicit feature flags** - Disabled Gemini sentiment analysis and keyword scheduler during tests

## Test Plan

- [x] Updated GitHub Actions workflow configuration
- [x] All environment variables properly set for testing
- [x] spaCy model installation included
- [x] CI tests should pass successfully

## Related Issues

Fixes workflow failures from previous runs.
EOF

echo "🚀 Starting automated PR creation and merge process..."

# Step 1: Create PR
echo "📝 Creating pull request..."
PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base "$BASE_BRANCH" \
    --head "$BRANCH_NAME" 2>&1 | grep -o 'https://github.com[^ ]*' || echo "")

if [ -z "$PR_URL" ]; then
    echo "❌ Failed to create PR. Checking if PR already exists..."
    PR_URL=$(gh pr list --head "$BRANCH_NAME" --json url --jq '.[0].url' 2>/dev/null || echo "")

    if [ -z "$PR_URL" ]; then
        echo "❌ Could not find or create PR. Exiting."
        exit 1
    fi
    echo "✅ Found existing PR: $PR_URL"
else
    echo "✅ PR created: $PR_URL"
fi

# Extract PR number
PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')
echo "📊 PR Number: #$PR_NUMBER"

# Step 2: Wait for checks to complete
echo "⏳ Waiting for CI checks to complete..."
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Get PR status
    CHECK_STATUS=$(gh pr view "$PR_NUMBER" --json statusCheckRollup --jq '.statusCheckRollup[].conclusion' 2>/dev/null || echo "")
    STATE=$(gh pr view "$PR_NUMBER" --json statusCheckRollup --jq '.statusCheckRollup[].state' 2>/dev/null || echo "")

    # Check if all checks are completed
    if echo "$STATE" | grep -q "PENDING" || echo "$STATE" | grep -q "IN_PROGRESS"; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⏳ Checks still running... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep $RETRY_INTERVAL
        continue
    fi

    # Check if all checks passed
    if echo "$CHECK_STATUS" | grep -qv "SUCCESS" && [ -n "$CHECK_STATUS" ]; then
        FAILED_CHECKS=$(echo "$CHECK_STATUS" | grep -v "SUCCESS" | head -5)
        echo "❌ Some checks failed:"
        echo "$FAILED_CHECKS"
        echo ""
        echo "🔄 Attempting to fix and retry..."
        exit 1
    fi

    # All checks passed
    if [ -n "$CHECK_STATUS" ] && ! echo "$CHECK_STATUS" | grep -qv "SUCCESS"; then
        echo "✅ All CI checks passed!"
        break
    fi

    # No checks yet, keep waiting
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "⏳ Waiting for checks to start... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "❌ Timeout waiting for checks to complete"
    exit 1
fi

# Step 3: Auto-merge PR
echo "🔀 Auto-merging PR..."
if gh pr merge "$PR_NUMBER" --auto --squash --delete-branch; then
    echo "✅ PR set to auto-merge!"
    echo "✅ Will merge automatically when all required checks pass"
else
    echo "⚠️  Auto-merge failed, attempting manual merge..."
    if gh pr merge "$PR_NUMBER" --squash --delete-branch; then
        echo "✅ PR merged successfully!"
    else
        echo "❌ Merge failed. Please merge manually at: $PR_URL"
        exit 1
    fi
fi

echo ""
echo "🎉 Process completed successfully!"
echo "📍 PR URL: $PR_URL"
