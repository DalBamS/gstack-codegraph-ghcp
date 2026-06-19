#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <target-path-or-url> [--report <report-path>]"
  echo "Example: $0 ."
  echo "Example: $0 . --report /tmp/gstack-ghcp-qa.md"
  echo "Example: $0 https://example.com"
}

TARGET="${1:-.}"
REPORT_PATH="${QA_REPORT_PATH:-}"

shift $(( $# > 0 ? 1 : 0 ))

while [ "$#" -gt 0 ]; do
  case "$1" in
    --report)
      if [ "${2:-}" = "" ]; then
        echo "Error: --report requires a path."
        usage
        exit 1
      fi
      REPORT_PATH="$2"
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

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not inside a git repository."
  exit 1
fi

cd "$REPO_ROOT"

emit_report() {
  if [ -n "$REPORT_PATH" ]; then
    mkdir -p "$(dirname "$REPORT_PATH")"
    tee "$REPORT_PATH"
  else
    cat
  fi
}

rating_to_decision() {
  score="$1"

  if [ "$score" -ge 90 ]; then
    echo "Release decision: ready to ship"
  elif [ "$score" -ge 80 ]; then
    echo "Release decision: ship with warnings"
  elif [ "$score" -ge 70 ]; then
    echo "Release decision: improve before release"
  elif [ "$score" -ge 60 ]; then
    echo "Release decision: review required"
  else
    echo "Release decision: rework required"
  fi
}

case "$TARGET" in
  http://*|https://*)
    cat <<REPORT | emit_report
# QA Workflow Report

Target: ${TARGET}
Mode: browser-url

## Preflight

- Use Playwright MCP from .vscode/mcp.json.
- Do not create a bespoke browser harness.
- Show the URL and browser flow to the user before interacting with the page.

## Browser Smoke Checklist

- Open ${TARGET} with Playwright MCP.
- Confirm the page title.
- Capture the visible page state or accessibility snapshot when useful.
- Exercise the requested user flow if one was provided.
- Report pass/fail findings and screenshots/snapshots that were collected by MCP.

## Release Decision

Release decision: browser validation pending Playwright MCP execution
REPORT
    ;;
  *)
    QA_OUTPUT="$(./scripts/qa-score.sh "$TARGET")"
    QA_SCORE="$(printf '%s\n' "$QA_OUTPUT" | sed -n 's/^QA Score: \([0-9][0-9]*\)\/100$/\1/p' | tail -n 1)"

    if [ -z "$QA_SCORE" ]; then
      QA_SCORE=0
    fi

    RELEASE_DECISION="$(rating_to_decision "$QA_SCORE")"

    cat <<REPORT | emit_report
# QA Workflow Report

Target: ${TARGET}
Mode: code-path

## Test Plan

- Unit: verify core logic and edge cases for changed code.
- Integration: verify file, API, or data-flow boundaries touched by the target.
- Regression: rerun checks related to previous failures when known.
- Browser: use Playwright MCP only when the target includes a UI or user flow.

## QA Score Output

\`\`\`text
${QA_OUTPUT}
\`\`\`

## Release Decision

${RELEASE_DECISION}
REPORT
    ;;
esac

if [ -n "$REPORT_PATH" ]; then
  echo ""
  echo "Wrote QA workflow report: ${REPORT_PATH}"
fi