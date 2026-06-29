#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: autoplan-workflow.sh --idea <idea> [--target <path>] [--mode <mode>] [--report <path>]

Modes:
  quick      Minimal tracer-bullet plan.
  standard   Plan, review, QA, and ship gates. Default.
  thorough   Adds risk register, docs, and memory follow-up.

Examples:
  autoplan-workflow.sh --idea "email login" --target .
  autoplan-workflow.sh --idea "dashboard performance" --target src/dashboard --mode thorough
USAGE
}

IDEA=""
TARGET="."
MODE="standard"
REPORT_PATH=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --idea)
      IDEA="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
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

if [ -z "$IDEA" ]; then
  usage
  exit 1
fi

case "$MODE" in
  quick|standard|thorough)
    ;;
  *)
    echo "Error: unknown mode: ${MODE}"
    usage
    exit 1
    ;;
esac

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not inside a git repository."
  exit 1
fi

cd "$REPO_ROOT"

if [ ! -e "$TARGET" ]; then
  echo "Error: target path not found: ${TARGET}"
  exit 1
fi

shell_quote() {
  printf "%s" "$1" | sed "s/'/'\\''/g; s/^/'/; s/$/'/"
}

slugify() {
  printf "%s" "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' |
    cut -c 1-48
}

emit_report() {
  if [ -n "$REPORT_PATH" ]; then
    mkdir -p "$(dirname "$REPORT_PATH")"
    tee "$REPORT_PATH"
  else
    cat
  fi
}

count_target_files() {
  find "$TARGET" -type f "$@" -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' '
}

detect_target_profile() {
  code_files=$(count_target_files \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name '*.mjs' -o -name '*.cjs' \))
  docs_files=$(count_target_files \( -name '*.md' -o -name '*.mdx' \))

  if [ "$code_files" -eq 0 ] && [ "$docs_files" -gt 0 ]; then
    echo "docs"
  elif [ "$code_files" -gt 0 ] && [ "$docs_files" -gt 0 ]; then
    echo "hybrid"
  elif [ "$code_files" -gt 0 ]; then
    echo "code"
  else
    echo "unknown"
  fi
}

IDEA_SLUG="$(slugify "$IDEA")"
if [ -z "$IDEA_SLUG" ]; then
  IDEA_SLUG="feature"
fi

BRANCH="$(git branch --show-current 2>/dev/null || echo unknown)"
DIRTY_COUNT="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
SPEC_PATH="docs/${IDEA_SLUG}-spec.md"
WORKTREE_NAME="feature-${IDEA_SLUG}"
TARGET_PROFILE="$(detect_target_profile)"

HAS_TESTS="no"
if find . -path ./.git -prune -o -type f \( -name '*test.*' -o -name '*spec.*' \) -print -quit | grep -q .; then
  HAS_TESTS="yes"
fi

HAS_CI="no"
if [ -d .github/workflows ] && find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print -quit | grep -q .; then
  HAS_CI="yes"
fi

HAS_PACKAGE="no"
if [ -f package.json ]; then
  HAS_PACKAGE="yes"
fi

{
  echo "# Autoplan Workflow Report"
  echo ""
  echo "Idea: ${IDEA}"
  echo "Target: ${TARGET}"
  echo "Mode: ${MODE}"
  echo "Branch: ${BRANCH}"
  echo "Uncommitted file count: ${DIRTY_COUNT}"
  echo ""
  echo "## Repo Signals"
  echo "- package.json: ${HAS_PACKAGE}"
  echo "- tests/spec files: ${HAS_TESTS}"
  echo "- GitHub Actions workflows: ${HAS_CI}"
  echo "- target profile: ${TARGET_PROFILE}"
  echo ""
  echo "## Sprint Chain"
  echo "1. Think: run office-hours to challenge the framing before writing code."
  echo "2. Plan: write a spec with scope, non-goals, technical requirements, and acceptance criteria."
  echo "3. Build: use a focused branch or worktree for the smallest vertical slice."
  echo "4. Review: run diff review before QA, including PR or issue context when available."
  echo "5. Test: run QA score and Playwright MCP smoke for browser-facing changes."
  echo "6. Ship: preview merge and issue-close commands, then ask for approval."
  echo "7. Reflect: save durable decisions and pitfalls to memory."
  echo ""
  echo "## Review Gate"
  echo "- CEO review: confirm the user, wedge, non-goals, and success signal still match the idea."
  echo "- Design review: confirm the proposed flow, API, or document structure is coherent."
  echo "- Engineering review: inspect changed files, compatibility/API surface, failure modes, and rollback path."
  echo "- DevEx review: confirm setup, commands, docs, and examples are easy to run."
  echo "- Security review: check secret exposure, shell command safety, and GitHub mutation previews."
  echo "- Evidence: review-workflow output, changed-file inventory, and unresolved risk list."
  echo ""
  echo "## QA Gate"
  echo "- Profile: ${TARGET_PROFILE}"
  echo "- Score command: ./scripts/qa-score.sh $(shell_quote "$TARGET")"
  echo "- Docs targets: require documentation structure, examples, links, freshness, and workflow coverage."
  echo "- Code targets: require tests or coverage signal, lint/build signal, complexity, type safety, and docs."
  echo "- Browser-facing targets: add Playwright MCP smoke validation instead of a bespoke harness."
  echo ""
  echo "## Suggested Command Plan"
  echo '```bash'
  echo "./scripts/office-hours-workflow.sh --idea $(shell_quote "$IDEA")"
  echo "# Write the clarified spec to ${SPEC_PATH}, then validate it:"
  echo "./scripts/spec-workflow.sh --title $(shell_quote "$IDEA") --body $(shell_quote "$SPEC_PATH") --label feature"
  echo "./scripts/setup-worktree.sh ${WORKTREE_NAME}"
  echo "./scripts/review-workflow.sh --base origin/main --target HEAD"
  echo "./scripts/qa-workflow.sh $(shell_quote "$TARGET")"
  echo "./scripts/ship-workflow.sh --pr <PR_NUMBER> --issue <ISSUE_NUMBER>"
  echo "./scripts/memory-workflow.sh save --type pattern --title $(shell_quote "$IDEA") --note <LESSON>"
  echo '```'
  echo ""
  echo "## Risk Register"
  echo "- Scope risk: unresolved user, workflow, or non-goal decisions should block implementation."
  echo "- Test risk: if source changes ship without tests/spec updates, review must record the rationale."
  echo "- Release risk: PR merge and issue close stay preview-only until user approval."
  echo "- Browser risk: use Playwright MCP for UI validation; do not add a bespoke browser harness."
  if [ "$MODE" = "quick" ]; then
    echo "- Mode risk: quick mode should only be used for low-risk tracer bullets."
  elif [ "$MODE" = "standard" ]; then
    echo "- Standard mode: include review and QA owners before implementation starts."
  elif [ "$MODE" = "thorough" ]; then
    echo "- Thorough mode: include explicit docs, memory, rollback, and post-ship follow-up owners."
  fi
  echo ""
  echo "## Minimum Exit Criteria"
  echo "- Spec passes spec-workflow."
  echo "- Review report has no unexplained high-signal findings."
  echo "- QA workflow gives a release decision for the touched path."
  echo "- Ship workflow previews the exact GitHub commands before mutation."
  echo ""
  echo "CHECK OK"
  echo "No files, branches, GitHub issues, PRs, or browser sessions were created."
} | emit_report
