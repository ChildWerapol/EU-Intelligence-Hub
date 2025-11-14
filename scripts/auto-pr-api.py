#!/usr/bin/env python3
"""Automated PR creation and merge using GitHub API."""

import os
import sys
import time
import json
import subprocess
from typing import Dict, Any, Optional

# GitHub API base URL
API_BASE = "https://api.github.com"
REPO_OWNER = "ChildWerapol"
REPO_NAME = "EU-Intelligence-Hub"
BRANCH_NAME = "claude/fix-github-workflow-014jZTpTdTyJWZMds9avXD9z"
BASE_BRANCH = "main"

PR_TITLE = "fix: improve GitHub Actions workflow configuration"
PR_BODY = """## Summary

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
"""


def run_command(cmd: str) -> str:
    """Run a shell command and return output."""
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True, check=False
    )
    return result.stdout.strip()


def get_github_token() -> Optional[str]:
    """Try to get GitHub token from environment or gh CLI."""
    # Try environment variable first
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        return token

    # Try gh auth token
    try:
        token = run_command("gh auth token 2>/dev/null")
        if token:
            return token
    except:
        pass

    return None


def create_pr() -> Optional[Dict[str, Any]]:
    """Create a pull request using GitHub API."""
    token = get_github_token()
    if not token:
        print("❌ No GitHub token found. Please authenticate with 'gh auth login'")
        return None

    import urllib.request

    url = f"{API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/pulls"

    data = {
        "title": PR_TITLE,
        "body": PR_BODY,
        "head": BRANCH_NAME,
        "base": BASE_BRANCH,
    }

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json",
    }

    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers=headers,
            method="POST",
        )

        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 422:
            # PR might already exist
            print("⚠️  PR might already exist, checking...")
            return check_existing_pr(token)
        else:
            print(f"❌ Error creating PR: {e.code} {e.reason}")
            print(e.read().decode())
            return None


def check_existing_pr(token: str) -> Optional[Dict[str, Any]]:
    """Check if PR already exists."""
    import urllib.request

    url = f"{API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/pulls?head={REPO_OWNER}:{BRANCH_NAME}&state=open"

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
    }

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            prs = json.loads(response.read().decode())
            if prs:
                print(f"✅ Found existing PR: {prs[0]['html_url']}")
                return prs[0]
    except Exception as e:
        print(f"❌ Error checking existing PR: {e}")

    return None


def check_pr_status(pr_number: int, token: str) -> Dict[str, Any]:
    """Check PR check status."""
    import urllib.request

    url = f"{API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/pulls/{pr_number}"

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
    }

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            pr_data = json.loads(response.read().decode())
            return pr_data
    except Exception as e:
        print(f"❌ Error checking PR status: {e}")
        return {}


def merge_pr(pr_number: int, token: str) -> bool:
    """Merge the pull request."""
    import urllib.request

    url = f"{API_BASE}/repos/{REPO_OWNER}/{REPO_NAME}/pulls/{pr_number}/merge"

    data = {
        "commit_title": PR_TITLE,
        "merge_method": "squash",
    }

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json",
    }

    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(data).encode("utf-8"),
            headers=headers,
            method="PUT",
        )

        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            if result.get("merged"):
                print("✅ PR merged successfully!")
                return True
    except urllib.error.HTTPError as e:
        print(f"❌ Error merging PR: {e.code} {e.reason}")
        print(e.read().decode())

    return False


def main():
    """Main execution flow."""
    print("🚀 Starting automated PR creation and merge process...")

    # Step 1: Create or find PR
    print("\n📝 Creating pull request...")
    pr_data = create_pr()

    if not pr_data:
        print("❌ Failed to create or find PR")
        sys.exit(1)

    pr_number = pr_data["number"]
    pr_url = pr_data["html_url"]

    print(f"✅ PR #{pr_number}: {pr_url}")

    # Step 2: Wait for checks
    token = get_github_token()
    if not token:
        print("❌ No GitHub token available")
        sys.exit(1)

    print("\n⏳ Waiting for CI checks to complete...")
    max_retries = 60
    retry_interval = 30

    for attempt in range(max_retries):
        time.sleep(retry_interval)

        pr_status = check_pr_status(pr_number, token)

        if not pr_status:
            continue

        mergeable_state = pr_status.get("mergeable_state", "")

        print(f"   Status: {mergeable_state} (attempt {attempt + 1}/{max_retries})")

        if mergeable_state == "clean":
            print("✅ All checks passed!")
            break
        elif mergeable_state in ["dirty", "unstable"]:
            print(f"❌ PR has issues: {mergeable_state}")
            print(f"   Please check: {pr_url}")
            sys.exit(1)
    else:
        print("❌ Timeout waiting for checks")
        sys.exit(1)

    # Step 3: Merge PR
    print("\n🔀 Merging PR...")
    if merge_pr(pr_number, token):
        print(f"\n🎉 Process completed successfully!")
        print(f"📍 PR URL: {pr_url}")
    else:
        print(f"❌ Merge failed. Please merge manually at: {pr_url}")
        sys.exit(1)


if __name__ == "__main__":
    main()
