#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: review-workflow.sh [--base <ref>] [--target <ref>] [--report <path>] [--fail-on-risk]

Examples:
  review-workflow.sh
  review-workflow.sh --base origin/main --target HEAD
  review-workflow.sh --base HEAD --target HEAD --report /tmp/review.md
USAGE
}

BASE_REF="${REVIEW_BASE_REF:-origin/main}"
TARGET_REF="${REVIEW_TARGET_REF:-HEAD}"
REPORT_PATH=""
FAIL_ON_RISK=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      BASE_REF="${2:-}"
      shift 2
      ;;
    --target)
      TARGET_REF="${2:-}"
      shift 2
      ;;
    --report)
      REPORT_PATH="${2:-}"
      shift 2
      ;;
    --fail-on-risk)
      FAIL_ON_RISK=1
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

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not inside a git repository."
  exit 1
fi

cd "$REPO_ROOT"

if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
  if git rev-parse --verify --quiet main >/dev/null; then
    BASE_REF="main"
  else
    BASE_REF="HEAD"
  fi
fi

if ! git rev-parse --verify --quiet "$TARGET_REF" >/dev/null; then
  echo "Error: target ref not found: ${TARGET_REF}"
  exit 1
fi

DIFF_RANGE="${BASE_REF}...${TARGET_REF}"
if ! git diff --quiet "$DIFF_RANGE" >/dev/null 2>&1 && [ "$?" -gt 1 ]; then
  DIFF_RANGE="${BASE_REF} ${TARGET_REF}"
fi

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t gstack-review)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

CHANGED_FILES_FILE="${TMP_DIR}/changed-files.txt"
WHITESPACE_FILE="${TMP_DIR}/whitespace.txt"
RISK_FILE="${TMP_DIR}/risk.txt"
TEST_GAP_FILE="${TMP_DIR}/test-gap.txt"

if printf '%s' "$DIFF_RANGE" | grep -q ' '; then
  git diff --name-only "$BASE_REF" "$TARGET_REF" > "$CHANGED_FILES_FILE" || true
  git diff --check "$BASE_REF" "$TARGET_REF" > "$WHITESPACE_FILE" 2>&1 || true
  git diff --unified=0 "$BASE_REF" "$TARGET_REF" > "${TMP_DIR}/diff.txt" || true
else
  git diff --name-only "$DIFF_RANGE" > "$CHANGED_FILES_FILE" || true
  git diff --check "$DIFF_RANGE" > "$WHITESPACE_FILE" 2>&1 || true
  git diff --unified=0 "$DIFF_RANGE" > "${TMP_DIR}/diff.txt" || true
fi

grep -En '\+.*(ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]+|AKIA[0-9A-Z]{16}|password[[:space:]]*=|token[[:space:]]*=|api[_-]?key[[:space:]]*=|secret[[:space:]]*=)' "${TMP_DIR}/diff.txt" > "$RISK_FILE" || true
grep -En '\+.*(eval\(|new Function\(|innerHTML|dangerouslySetInnerHTML|document\.write|--admin|--force|git reset --hard|git clean -fd)' "${TMP_DIR}/diff.txt" >> "$RISK_FILE" || true
grep -En '\+.*(SELECT|UPDATE|DELETE|INSERT).*(\$\{|\+)' "${TMP_DIR}/diff.txt" >> "$RISK_FILE" || true

SOURCE_CHANGED="no"
TEST_CHANGED="no"
if grep -Eiq '\.(js|jsx|ts|tsx|mjs|cjs|sh)$' "$CHANGED_FILES_FILE"; then
  SOURCE_CHANGED="yes"
fi
if grep -Eiq '(test|spec)\.|(^|/)(test|tests|spec|specs)/' "$CHANGED_FILES_FILE"; then
  TEST_CHANGED="yes"
fi

if [ "$SOURCE_CHANGED" = "yes" ] && [ "$TEST_CHANGED" = "no" ]; then
  echo "Changed source files without matching test/spec file changes." > "$TEST_GAP_FILE"
fi

WHITESPACE_STATUS="PASS"
if [ -s "$WHITESPACE_FILE" ]; then
  WHITESPACE_STATUS="FAIL"
fi

RISK_STATUS="PASS"
if [ -s "$RISK_FILE" ]; then
  RISK_STATUS="WARN"
fi

emit_report() {
  if [ -n "$REPORT_PATH" ]; then
    mkdir -p "$(dirname "$REPORT_PATH")"
    tee "$REPORT_PATH"
  else
    cat
  fi
}

{
  echo "# Review Workflow Report"
  echo ""
  echo "Base: ${BASE_REF}"
  echo "Target: ${TARGET_REF}"
  echo "Diff: ${DIFF_RANGE}"
  echo ""
  echo "## Changed Files"
  if [ -s "$CHANGED_FILES_FILE" ]; then
    sed 's/^/- /' "$CHANGED_FILES_FILE"
  else
    echo "- No changed files in this comparison."
  fi
  echo ""
  echo "## Whitespace Check"
  echo "Status: ${WHITESPACE_STATUS}"
  if [ -s "$WHITESPACE_FILE" ]; then
    echo ""
    echo '```text'
    cat "$WHITESPACE_FILE"
    echo '```'
  fi
  echo ""
  echo "## Risk Scan"
  echo "Status: ${RISK_STATUS}"
  if [ -s "$RISK_FILE" ]; then
    echo ""
    echo '```text'
    cat "$RISK_FILE"
    echo '```'
  else
    echo "No high-signal risk patterns found in the diff."
  fi
  echo ""
  echo "## Test Gap"
  if [ -s "$TEST_GAP_FILE" ]; then
    cat "$TEST_GAP_FILE"
  else
    echo "No automatic test gap detected."
  fi
  echo ""
  echo "## Review Checklist"
  echo "- Confirm behavioral intent matches the originating spec or issue."
  echo "- Inspect security boundaries, especially secrets, SQL, shell, browser, and LLM trust boundaries."
  echo "- Confirm tests or explicit rationale cover changed behavior."
  echo "- Run /qa or ./scripts/qa-workflow.sh on the touched path before /ship."
} | emit_report

if [ "$WHITESPACE_STATUS" = "FAIL" ]; then
  exit 1
fi

if [ "$FAIL_ON_RISK" = "1" ] && [ "$RISK_STATUS" = "WARN" ]; then
  exit 1
fi

exit 0