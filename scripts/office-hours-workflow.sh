#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: office-hours-workflow.sh --idea <idea> [--audience <audience>] [--mode <mode>] [--report <path>]

Modes:
  expansion             Explore the larger product hiding behind the request.
  selective-expansion   Expand only where user pain supports it. Default.
  hold-scope            Keep the original scope and sharpen execution.
  reduction             Find the narrowest useful wedge.

Examples:
  office-hours-workflow.sh --idea "daily briefing app"
  office-hours-workflow.sh --idea "email login" --audience "first-time users" --mode reduction
USAGE
}

IDEA=""
AUDIENCE="not specified"
MODE="selective-expansion"
REPORT_PATH=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --idea)
      IDEA="${2:-}"
      shift 2
      ;;
    --audience)
      AUDIENCE="${2:-}"
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
  expansion|selective-expansion|hold-scope|reduction)
    ;;
  *)
    echo "Error: unknown mode: ${MODE}"
    usage
    exit 1
    ;;
esac

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

IDEA_SLUG="$(slugify "$IDEA")"
if [ -z "$IDEA_SLUG" ]; then
  IDEA_SLUG="feature"
fi

SPEC_PATH="docs/${IDEA_SLUG}-spec.md"

{
  echo "# Office Hours Workflow Report"
  echo ""
  echo "Idea: ${IDEA}"
  echo "Audience: ${AUDIENCE}"
  echo "Mode: ${MODE}"
  echo ""
  echo "## Six Forcing Questions"
  echo "1. What specific painful moment caused this request? Name the user, context, and failed workaround."
  echo "2. What would this user do today if we shipped nothing?"
  echo "3. Who is the narrowest first user segment that would care immediately?"
  echo "4. What is the 10-star outcome, and which part can be delivered first?"
  echo "5. What should be explicitly out of scope for the first pass?"
  echo "6. What evidence will prove this worked: usage, time saved, fewer errors, revenue, retention, or support load?"
  echo ""
  echo "## Premise Checks"
  echo "- Problem: restate the pain in the user's words, not as an implementation task."
  echo "- Audience: identify the smallest group that would notice the improvement immediately."
  echo "- Frequency: confirm whether the pain is daily, weekly, rare, or only hypothetical."
  echo "- Substitution: list the workaround users already tolerate."
  echo "- Scope risk: name the easiest way this could become too broad too early."
  echo ""
  echo "## Candidate Paths"
  echo "- Reduction: cut the request to one user, one workflow, one measurable outcome."
  echo "- Hold scope: keep the request intact, but define strict acceptance criteria and non-goals."
  echo "- Selective expansion: add only the missing capability that makes the feature useful."
  echo "- Expansion: capture the broader product idea as backlog, not as first-pass scope."
  echo ""
  echo "## Downstream Commands"
  echo '```bash'
  echo "# After answering the questions, write the clarified spec to ${SPEC_PATH}."
  echo "./scripts/spec-workflow.sh --title $(shell_quote "$IDEA") --body $(shell_quote "$SPEC_PATH") --label feature"
  echo "./scripts/autoplan-workflow.sh --idea $(shell_quote "$IDEA") --target ."
  echo '```'
  echo ""
  echo "CHECK OK"
  echo "No files, branches, GitHub issues, or browser sessions were created."
} | emit_report
