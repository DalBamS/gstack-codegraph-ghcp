#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --title <issue-title> --body <spec-file> [--label <label>] [--run-search]"
  echo "Example: $0 --title 'Email login' --body docs/auth-spec.md"
}

TITLE=""
BODY_FILE=""
LABEL="feature"
RUN_SEARCH=0
FAILURES=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --body|--body-file)
      BODY_FILE="${2:-}"
      shift 2
      ;;
    --label)
      LABEL="${2:-}"
      shift 2
      ;;
    --run-search)
      RUN_SEARCH=1
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

pass() {
  echo "PASS $1"
}

fail() {
  echo "FAIL $1"
  FAILURES=$((FAILURES + 1))
}

shell_quote() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g; s/^/'/; s/$/'/"
}

require_heading() {
  label="$1"
  pattern="$2"

  if grep -Eiq "^#{1,3}[[:space:]].*(${pattern})" "$BODY_FILE"; then
    pass "spec includes ${label}"
  else
    fail "spec is missing ${label} heading"
  fi
}

scan_secrets() {
  secret_log="$(mktemp 2>/dev/null || echo /tmp/spec-workflow-secrets.$$)"
  trap 'rm -f "$secret_log"' EXIT

  grep -Eni \
    'ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]+|AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|(^|[^A-Za-z])(password|passwd|api[_-]?key|secret|token)[[:space:]]*[:=][[:space:]]*[^[:space:]<\[]+' \
    "$BODY_FILE" > "$secret_log" || true

  if [ -s "$secret_log" ]; then
    fail "spec may contain secrets or credentials"
    sed 's/^/  /' "$secret_log"
  else
    pass "spec secret scan is clean"
  fi
}

if [ -z "$TITLE" ] || [ -z "$BODY_FILE" ]; then
  usage
  exit 1
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "Error: spec body file not found: ${BODY_FILE}"
  exit 1
fi

echo "Spec Workflow Dry Run"
echo "Title: ${TITLE}"
echo "Body: ${BODY_FILE}"
echo "Label: ${LABEL}"
echo ""

require_heading "why/summary" 'Why|목표|요약|Summary|Problem'
require_heading "scope" 'Scope|범위'
require_heading "user stories" 'User Stories|사용자 스토리|사용자 관점'
require_heading "technical requirements" 'Technical Requirements|기술 요구사항'
require_heading "acceptance criteria" 'Acceptance Criteria|인수 기준'
scan_secrets

echo ""
echo "Duplicate issue search preview:"
SEARCH_QUERY="${TITLE} in:title,body"
echo "gh issue list --search $(shell_quote "$SEARCH_QUERY") --state open"

if [ "$RUN_SEARCH" = "1" ]; then
  if command -v gh >/dev/null 2>&1; then
    echo ""
    echo "Duplicate issue search result:"
    gh issue list --search "$SEARCH_QUERY" --state open || fail "gh issue list failed"
  else
    fail "gh CLI is required for --run-search"
  fi
fi

echo ""
echo "Issue create preview:"
echo "gh issue create --title $(shell_quote "$TITLE") --body-file $(shell_quote "$BODY_FILE") --label $(shell_quote "$LABEL")"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "CHECK OK"
  echo "No GitHub mutation was executed. Run the previewed gh issue create command only after user approval."
  exit 0
fi

echo "CHECK FAILED: ${FAILURES} issue(s) found"
exit 1