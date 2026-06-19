#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --pr <number> [--issue <number>] [--merge-method merge|squash|rebase] [--run-checks]"
  echo "Example: $0 --pr 123 --issue 42"
}

PR_NUMBER=""
ISSUE_NUMBER=""
MERGE_METHOD="merge"
RUN_CHECKS=0
FAILURES=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --pr)
      PR_NUMBER="${2:-}"
      shift 2
      ;;
    --issue)
      ISSUE_NUMBER="${2:-}"
      shift 2
      ;;
    --merge-method)
      MERGE_METHOD="${2:-}"
      shift 2
      ;;
    --run-checks)
      RUN_CHECKS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

fail() {
  echo "FAIL $1"
  FAILURES=$((FAILURES + 1))
}

warn() {
  echo "WARN $1"
}

pass() {
  echo "PASS $1"
}

shell_quote() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g; s/^/'/; s/$/'/"
}

if ! printf '%s' "$PR_NUMBER" | grep -Eq '^[0-9]+$'; then
  fail "--pr must be a numeric pull request number"
fi

if [ -n "$ISSUE_NUMBER" ] && ! printf '%s' "$ISSUE_NUMBER" | grep -Eq '^[0-9]+$'; then
  fail "--issue must be numeric when provided"
fi

case "$MERGE_METHOD" in
  merge|squash|rebase)
    pass "merge method is ${MERGE_METHOD}"
    ;;
  *)
    fail "--merge-method must be merge, squash, or rebase"
    ;;
esac

if [ "$FAILURES" -gt 0 ]; then
  echo "CHECK FAILED: ${FAILURES} issue(s) found"
  exit 1
fi

echo "Ship Workflow Dry Run"
echo "PR: #${PR_NUMBER}"
if [ -n "$ISSUE_NUMBER" ]; then
  echo "Linked issue: #${ISSUE_NUMBER}"
else
  echo "Linked issue: not provided"
fi
echo "Merge method: ${MERGE_METHOD}"
echo ""

echo "Preflight commands:"
echo "gh pr view ${PR_NUMBER} --json title,state,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup,body"
echo "gh pr checks ${PR_NUMBER}"

if [ "$RUN_CHECKS" = "1" ]; then
  if command -v gh >/dev/null 2>&1; then
    echo ""
    echo "PR state:"
    gh pr view "$PR_NUMBER" --json title,state,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup,body || fail "gh pr view failed"
    echo ""
    echo "PR checks:"
    gh pr checks "$PR_NUMBER" || fail "gh pr checks failed"
  else
    fail "gh CLI is required for --run-checks"
  fi
fi

echo ""
echo "Safety gates before merge:"
echo "- PR state must be OPEN."
echo "- PR must not be draft."
echo "- Required checks must pass."
echo "- Review decision must be APPROVED when the repository requires review."
echo "- Linked issue should be present or explicitly waived by the user."

if [ -z "$ISSUE_NUMBER" ]; then
  warn "linked issue was not provided; do not close an issue automatically"
fi

case "$MERGE_METHOD" in
  merge)
    MERGE_FLAG="--merge"
    ;;
  squash)
    MERGE_FLAG="--squash"
    ;;
  rebase)
    MERGE_FLAG="--rebase"
    ;;
esac

echo ""
echo "Merge command preview:"
echo "gh pr merge ${PR_NUMBER} ${MERGE_FLAG} --delete-branch"

if [ -n "$ISSUE_NUMBER" ]; then
  CLOSE_COMMENT="Closed by PR #${PR_NUMBER}"
  echo ""
  echo "Issue close preview:"
  echo "gh issue close ${ISSUE_NUMBER} --comment $(shell_quote "$CLOSE_COMMENT")"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "CHECK OK"
  echo "No GitHub mutation was executed. Run merge/close commands only after user approval."
  exit 0
fi

echo "CHECK FAILED: ${FAILURES} issue(s) found"
exit 1