#!/bin/bash
# One-command PR creation - Opens browser to create PR

BRANCH="claude/fix-github-workflow-014jZTpTdTyJWZMds9avXD9z"
REPO="ChildWerapol/EU-Intelligence-Hub"
BASE="main"

echo "🚀 Opening GitHub PR creation page..."
echo ""
echo "Branch: $BRANCH"
echo "Base: $BASE"
echo ""

# PR URL
PR_URL="https://github.com/$REPO/compare/$BASE...$BRANCH?expand=1&title=fix:%20improve%20GitHub%20Actions%20workflow%20configuration&body=%23%23%20Summary%0A%0AThis%20PR%20fixes%20issues%20in%20the%20GitHub%20Actions%20test%20workflow.%0A%0A%23%23%20Changes%20Made%0A%0A1.%20**Added%20spaCy%20model%20download**%20-%20Tests%20use%20spaCy%20for%20NER%0A2.%20**Added%20missing%20environment%20variables**%20-%20Test%20env%20vars%20set%0A3.%20**Extended%20test%20coverage**%20-%20Both%20test%20directories%20included%0A4.%20**Explicit%20feature%20flags**%20-%20Disabled%20Gemini/scheduler%20for%20tests%0A%0A%23%23%20Test%20Plan%0A%0A-%20%5Bx%5D%20Workflow%20configuration%20updated%0A-%20%5Bx%5D%20Environment%20variables%20set%0A-%20%5Bx%5D%20spaCy%20model%20installation%20included%0A-%20%5Bx%5D%20CI%20tests%20should%20pass"

echo "📋 PR will be created with:"
echo "   Title: fix: improve GitHub Actions workflow configuration"
echo "   Description: Pre-filled with changes"
echo ""
echo "🔗 Opening in browser..."
echo "$PR_URL"
echo ""

# Try to open in browser
if command -v xdg-open &> /dev/null; then
    xdg-open "$PR_URL" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$PR_URL" 2>/dev/null &
elif command -v start &> /dev/null; then
    start "$PR_URL" 2>/dev/null &
else
    echo "⚠️  Could not auto-open browser. Please copy the URL above."
fi

echo ""
echo "✅ After PR is created:"
echo "   1. Click 'Enable auto-merge'"
echo "   2. Select 'Squash and merge'"
echo "   3. Done! It will auto-merge when CI passes"
echo ""
