#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  memory-workflow.sh save --type decision|pattern|backlog --title <title> --note <note> [--apply]
  memory-workflow.sh search --query <query>
  memory-workflow.sh prune [--type decision|pattern|backlog]

Examples:
  memory-workflow.sh save --type pattern --title "gh approval" --note "Show gh mutation commands before running."
  memory-workflow.sh save --type pattern --title "gh approval" --note "Show gh mutation commands before running." --apply
  memory-workflow.sh search --query "Playwright"
  memory-workflow.sh prune --type backlog
USAGE
}

COMMAND="${1:-}"
if [ -z "$COMMAND" ]; then
  usage
  exit 1
fi
shift

TYPE=""
TITLE=""
NOTE=""
QUERY=""
APPLY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --type)
      TYPE="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --note)
      NOTE="${2:-}"
      shift 2
      ;;
    --query)
      QUERY="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY=1
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

MEMORY_DIR=".github/memory"

type_to_file() {
  case "$1" in
    decision|decisions)
      echo "${MEMORY_DIR}/decisions.md"
      ;;
    pattern|patterns)
      echo "${MEMORY_DIR}/patterns.md"
      ;;
    backlog|todo|todos)
      echo "${MEMORY_DIR}/backlog.md"
      ;;
    *)
      return 1
      ;;
  esac
}

contains_sensitive_value() {
  printf '%s\n%s\n' "$TITLE" "$NOTE" | grep -Eiq 'ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]+|AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|(^|[^A-Za-z])(password|passwd|api[_-]?key|secret|token)[[:space:]]*[:=][[:space:]]*[^[:space:]<\[]+'
}

search_memory() {
  if [ ! -d "$MEMORY_DIR" ]; then
    echo "No memory directory yet: ${MEMORY_DIR}"
    return 0
  fi

  if command -v rg >/dev/null 2>&1; then
    rg -n --fixed-strings "$1" "$MEMORY_DIR" || true
  else
    grep -RIn --fixed-strings "$1" "$MEMORY_DIR" 2>/dev/null || true
  fi
}

case "$COMMAND" in
  save)
    if [ -z "$TYPE" ] || [ -z "$TITLE" ] || [ -z "$NOTE" ]; then
      echo "Error: save requires --type, --title, and --note."
      usage
      exit 1
    fi

    if ! TARGET_FILE="$(type_to_file "$TYPE")"; then
      echo "Error: --type must be decision, pattern, or backlog."
      exit 1
    fi

    if contains_sensitive_value; then
      echo "CHECK FAILED: memory entry may contain secrets or credentials."
      exit 1
    fi

    TODAY="$(date +%F)"
    ENTRY="## ${TODAY} - ${TITLE}

- Context: gstack-ghcp workflow memory
- Note: ${NOTE}
- Source: local memory-workflow dry run"

    echo "Memory Save Dry Run"
    echo "Target: ${TARGET_FILE}"
    echo ""
    echo "Duplicate search:"
    search_memory "$TITLE"
    echo ""
    echo "Entry preview:"
    printf '%s\n' "$ENTRY"

    if [ "$APPLY" = "1" ]; then
      mkdir -p "$MEMORY_DIR"
      if [ ! -f "$TARGET_FILE" ]; then
        printf '# %s\n\n' "$(basename "$TARGET_FILE" .md)" > "$TARGET_FILE"
      fi
      printf '\n%s\n' "$ENTRY" >> "$TARGET_FILE"
      echo ""
      echo "Wrote memory entry: ${TARGET_FILE}"
    else
      echo ""
      echo "CHECK OK"
      echo "No file was modified. Add --apply after user approval to write this entry."
    fi
    ;;
  search)
    if [ -z "$QUERY" ]; then
      echo "Error: search requires --query."
      usage
      exit 1
    fi

    echo "Memory Search"
    echo "Query: ${QUERY}"
    echo ""
    search_memory "$QUERY"
    echo ""
    echo "CHECK OK"
    ;;
  prune)
    echo "Memory Prune Preview"
    if [ -n "$TYPE" ]; then
      if ! TARGET_FILE="$(type_to_file "$TYPE")"; then
        echo "Error: --type must be decision, pattern, or backlog."
        exit 1
      fi
      TARGETS="$TARGET_FILE"
    else
      TARGETS="${MEMORY_DIR}/decisions.md ${MEMORY_DIR}/patterns.md ${MEMORY_DIR}/backlog.md"
    fi

    echo "Candidates containing DONE, 완료, obsolete, or deprecated:"
    for target in $TARGETS; do
      [ -f "$target" ] || continue
      grep -Eni 'DONE|완료|obsolete|deprecated' "$target" || true
    done
    echo ""
    echo "CHECK OK"
    echo "No file was modified. Delete or rewrite candidates only after user approval."
    ;;
  *)
    echo "Error: unknown command: ${COMMAND}"
    usage
    exit 1
    ;;
esac