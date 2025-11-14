# Automated PR Creation and Merge Instructions

## Current Status

✅ **Workflow fixes committed and pushed** to branch: `claude/fix-github-workflow-014jZTpTdTyJWZMds9avXD9z`

### Changes Made:
- Added spaCy model download (`en_core_web_sm`)
- Added missing test environment variables
- Extended test coverage to both test directories
- Disabled Gemini and scheduler for tests

---

## Quick Start - Create PR Automatically

### Option 1: Using GitHub Web Interface (Recommended)

**Click this link to create the PR:**
```
https://github.com/ChildWerapol/EU-Intelligence-Hub/pull/new/claude/fix-github-workflow-014jZTpTdTyJWZMds9avXD9z
```

**PR Details:**
- **Title**: `fix: improve GitHub Actions workflow configuration`
- **Base**: `main`
- **Copy this description:**

```markdown
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
```

After creating the PR:
1. ✅ Enable **"Auto-merge"** (squash merge method)
2. ✅ Check **"Automatically delete branch"**
3. ✅ The PR will auto-merge when all checks pass

---

### Option 2: Using GitHub CLI (if authenticated)

```bash
# Run the automation script
./scripts/auto-pr-merge.sh
```

Or manually:

```bash
# Create PR
gh pr create \
  --title "fix: improve GitHub Actions workflow configuration" \
  --body "See PR_INSTRUCTIONS.md for full description" \
  --base main

# Enable auto-merge (after PR is created)
gh pr merge <PR_NUMBER> --auto --squash --delete-branch
```

---

### Option 3: Using Python Script with GitHub Token

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_token_here"

# Run the automated script
python3 scripts/auto-pr-api.py
```

---

## What Happens Next

### Automated CI Process:

1. **Tests Run** (~5-10 minutes)
   - Backend tests (pytest with PostgreSQL + Redis)
   - Frontend tests (npm build + lint)
   - Security scan (Trivy)
   - Docker builds

2. **Auto-Merge** (when all checks ✅)
   - PR automatically merges to `main`
   - Branch automatically deleted
   - Deploy workflow triggers (if configured)

### If Tests Fail:

The automation will:
1. Identify the failing test
2. Create a fix commit
3. Push to the same branch
4. CI re-runs automatically
5. Process repeats until all tests pass

---

## Monitoring Progress

**Check PR status:**
```bash
gh pr view --web
```

**Check CI status:**
```bash
gh run watch
```

**Or visit:**
- PR: https://github.com/ChildWerapol/EU-Intelligence-Hub/pulls
- Actions: https://github.com/ChildWerapol/EU-Intelligence-Hub/actions

---

## Troubleshooting

### If PR creation fails:
- PR might already exist - check: https://github.com/ChildWerapol/EU-Intelligence-Hub/pulls
- Check branch was pushed: `git ls-remote origin | grep claude/fix-github-workflow`

### If tests fail:
- Check workflow logs in GitHub Actions
- Common issues:
  - Missing dependencies
  - Environment variable issues
  - Database connection problems

### If auto-merge doesn't work:
- Ensure branch protection rules allow auto-merge
- Check that all required status checks are configured
- Manually merge if needed: `gh pr merge <PR_NUMBER> --squash`

---

## Summary

**Commit**: `cf8852c` - fix: improve GitHub Actions workflow configuration
**Branch**: `claude/fix-github-workflow-014jZTpTdTyJWZMds9avXD9z`
**Base**: `main`

**Next Action**: Create PR using one of the methods above ☝️
