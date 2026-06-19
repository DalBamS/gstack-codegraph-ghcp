#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: investigate-workflow.sh --symptom <text> [--target <path>] [--command <command>] [--run-command] [--report <path>]

Examples:
  investigate-workflow.sh --symptom "qa score dropped" --target .
  investigate-workflow.sh --symptom "login returns 500" --target src/auth --command "npm test -- auth"
USAGE
}

SYMPTOM=""
TARGET_PATH="."
COMMAND_TEXT=""
RUN_COMMAND=0
REPORT_PATH=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --symptom)
      SYMPTOM="${2:-}"
      shift 2
      ;;
    --target)
      TARGET_PATH="${2:-}"
      shift 2
      ;;
    --command)
      COMMAND_TEXT="${2:-}"
      shift 2
      ;;
    --run-command)
      RUN_COMMAND=1
      shift
      ;;
    --report)
      REPORT_PATH="${2:-}"
      shift 2
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

if [ -z "$SYMPTOM" ]; then
  echo "Error: --symptom is required."
  usage
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not inside a git repository."
  exit 1
fi

cd "$REPO_ROOT"

if [ ! -e "$TARGET_PATH" ]; then
  echo "Error: target path not found: ${TARGET_PATH}"
  exit 1
fi

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t gstack-investigate)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

STATUS_FILE="${TMP_DIR}/status.txt"
RECENT_FILE="${TMP_DIR}/recent.txt"
SEARCH_FILE="${TMP_DIR}/search.txt"
COMMAND_FILE="${TMP_DIR}/command.txt"

git status --short > "$STATUS_FILE" || true
git log --oneline -5 > "$RECENT_FILE" || true

FIRST_TOKEN="$(printf '%s' "$SYMPTOM" | tr -cs '[:alnum:]_-' '\n' | awk 'length($0) >= 4 { print; exit }')"
if [ -n "$FIRST_TOKEN" ]; then
  if command -v rg >/dev/null 2>&1; then
    rg -n --fixed-strings "$FIRST_TOKEN" "$TARGET_PATH" > "$SEARCH_FILE" 2>/dev/null || true
  else
    grep -RIn --fixed-strings "$FIRST_TOKEN" "$TARGET_PATH" > "$SEARCH_FILE" 2>/dev/null || true
  fi
fi

if [ -n "$COMMAND_TEXT" ]; then
  if [ "$RUN_COMMAND" = "1" ]; then
    bash -lc "$COMMAND_TEXT" > "$COMMAND_FILE" 2>&1 || true
  else
    echo "Command preview only: ${COMMAND_TEXT}" > "$COMMAND_FILE"
    echo "Add --run-command after user approval to execute it." >> "$COMMAND_FILE"
  fi
else
  echo "No reproduction command provided." > "$COMMAND_FILE"
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
  echo "# Investigate Workflow Report"
  echo ""
  echo "Symptom: ${SYMPTOM}"
  echo "Target: ${TARGET_PATH}"
  echo ""
  echo "## 1. Reproduce"
  echo "- Capture exact command, URL, input, or user flow that shows the symptom."
  echo "- Do not propose a fix until the symptom is reproduced or clearly bounded."
  echo ""
  echo '```text'
  cat "$COMMAND_FILE"
  echo '```'
  echo ""
  echo "## 2. Minimize"
  echo "- Reduce the symptom to the smallest file, command, route, or state transition."
  echo "- Prefer one cheap disconfirming check before broad exploration."
  echo ""
  echo "## 3. Current Signals"
  echo "Git status:"
  echo '```text'
  if [ -s "$STATUS_FILE" ]; then cat "$STATUS_FILE"; else echo "clean"; fi
  echo '```'
  echo "Recent commits:"
  echo '```text'
  cat "$RECENT_FILE"
  echo '```'
  echo "Search signal for first symptom token (${FIRST_TOKEN:-none}):"
  echo '```text'
  if [ -s "$SEARCH_FILE" ]; then cat "$SEARCH_FILE"; else echo "No local matches found."; fi
  echo '```'
  echo ""
  echo "## 4. Hypotheses"
  echo "- H1: Recent change in the target path changed behavior."
  echo "- H2: Missing setup, environment, or external service state explains the symptom."
  echo "- H3: The test or observation is incomplete and needs a smaller reproduction."
  echo ""
  echo "## 5. Instrumentation Plan"
  echo "- Add the smallest temporary log, assertion, or focused test that separates H1/H2/H3."
  echo "- Remove temporary instrumentation before shipping."
  echo ""
  echo "## 6. Fix And Regression Gate"
  echo "- Fix only after root cause is identified."
  echo "- Add or update a regression test, then run ./scripts/qa-workflow.sh ${TARGET_PATH}."
} | emit_report

exit 0