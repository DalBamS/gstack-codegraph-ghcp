#!/usr/bin/env bash

set -u

TARGET_PATH="${1:-.}"
MAX_SCORE=100
TOTAL_SCORE=0
IMPROVEMENTS_FILE="$(mktemp 2>/dev/null || echo /tmp/qa-score-improvements.$$)"

cleanup() {
  rm -f "$IMPROVEMENTS_FILE"
}

trap cleanup EXIT

add_improvement() {
  echo "- $1" >> "$IMPROVEMENTS_FILE"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

has_package_script() {
  script_name="$1"
  if [ ! -f package.json ] || ! command_exists node; then
    return 1
  fi

  node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$script_name'] ? 0 : 1)" >/dev/null 2>&1
}

run_package_script() {
  script_name="$1"
  if command_exists npm && has_package_script "$script_name"; then
    npm run "$script_name" --silent >/tmp/qa-score-${script_name}.log 2>&1
    return $?
  fi

  return 127
}

count_files() {
  find "$TARGET_PATH" -type f \
    \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name '*.mjs' -o -name '*.cjs' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' '
}

count_matches() {
  pattern="$1"
  find "$TARGET_PATH" -type f \
    \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name '*.mjs' -o -name '*.cjs' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' \
    -exec grep -E "$pattern" {} + 2>/dev/null | wc -l | tr -d ' '
}

score_coverage() {
  if run_package_script "test:coverage" || run_package_script "coverage"; then
    echo 25
    echo "Test Coverage: available and passing (25/25)"
    return
  fi

  test_files=$(find "$TARGET_PATH" -type f \
    \( -name '*.test.*' -o -name '*.spec.*' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
  source_files=$(count_files)

  if [ "$source_files" -eq 0 ]; then
    echo 20
    echo "Test Coverage: no source files detected (20/25)"
    return
  fi

  ratio=$(( test_files * 100 / source_files ))
  if [ "$ratio" -ge 30 ]; then
    echo 20
    echo "Test Coverage: test files present, coverage tool unavailable (20/25)"
  elif [ "$test_files" -gt 0 ]; then
    echo 15
    echo "Test Coverage: limited tests detected, coverage tool unavailable (15/25)"
    add_improvement "Add coverage reporting or more test files for ${TARGET_PATH}."
  else
    echo 8
    echo "Test Coverage: no tests detected and coverage tool unavailable (8/25)"
    add_improvement "Add tests and a coverage script for ${TARGET_PATH}."
  fi
}

score_lint() {
  if run_package_script "lint"; then
    echo 10
    echo "Lint Issues: lint script passed (10/10)"
  else
    status=$?
    if [ "$status" -eq 127 ]; then
      echo 7
      echo "Lint Issues: lint script unavailable (7/10)"
      add_improvement "Add a lint script so QA can detect style and correctness issues."
    else
      echo 3
      echo "Lint Issues: lint script failed (3/10)"
      add_improvement "Fix lint failures before shipping."
    fi
  fi
}

score_complexity() {
  source_files=$(count_files)
  if [ "$source_files" -eq 0 ]; then
    echo 20
    echo "Complexity: no source files detected (20/20)"
    return
  fi

  branches=$(count_matches "\b(if|for|while|switch|case|catch)\b|&&|\|\||\?")
  avg=$(( branches / source_files ))

  if [ "$avg" -le 8 ]; then
    echo 20
    echo "Complexity: Low (${avg} branch markers/file, 20/20)"
  elif [ "$avg" -le 18 ]; then
    echo 15
    echo "Complexity: Medium (${avg} branch markers/file, 15/20)"
    add_improvement "Review complex files and split dense control flow where practical."
  else
    echo 5
    echo "Complexity: High (${avg} branch markers/file, 5/20)"
    add_improvement "Reduce branching and split high-complexity modules before release."
  fi
}

score_type_safety() {
  typed_files=$(find "$TARGET_PATH" -type f \( -name '*.ts' -o -name '*.tsx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
  source_files=$(count_files)
  any_count=$(count_matches "\bany\b|@ts-ignore|@ts-expect-error")

  if [ "$source_files" -eq 0 ]; then
    echo 20
    echo "Type Safety: no source files detected (20/20)"
  elif [ "$typed_files" -eq 0 ]; then
    echo 8
    echo "Type Safety: no TypeScript files detected (8/20)"
    add_improvement "Use TypeScript or another type-checking strategy for safer changes."
  elif [ "$any_count" -eq 0 ]; then
    echo 20
    echo "Type Safety: TypeScript present with no obvious suppressions (20/20)"
  elif [ "$any_count" -le 5 ]; then
    echo 16
    echo "Type Safety: minor any/suppression usage (${any_count}, 16/20)"
    add_improvement "Reduce any and TypeScript suppressions."
  else
    echo 10
    echo "Type Safety: frequent any/suppression usage (${any_count}, 10/20)"
    add_improvement "Replace broad any usage and remove TypeScript suppressions."
  fi
}

score_documentation() {
  source_files=$(count_files)
  docs_files=$(find "$TARGET_PATH" -type f \( -name '*.md' -o -name '*.mdx' \) -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')
  comments=$(count_matches "^\s*(//|/\*|\*|#)")

  if [ "$source_files" -eq 0 ] || [ "$docs_files" -gt 0 ] || [ "$comments" -ge "$source_files" ]; then
    echo 15
    echo "Documentation: docs or comments present (15/15)"
  else
    echo 8
    echo "Documentation: sparse docs/comments (8/15)"
    add_improvement "Document public behavior, setup, or non-obvious implementation choices."
  fi
}

score_performance() {
  if has_package_script "build" && command_exists npm; then
    start_time=$(date +%s)
    if npm run build --silent >/tmp/qa-score-build.log 2>&1; then
      end_time=$(date +%s)
      elapsed=$(( end_time - start_time ))
      if [ "$elapsed" -le 30 ]; then
        echo 10
        echo "Performance: build passed in ${elapsed}s (10/10)"
      else
        echo 7
        echo "Performance: build passed in ${elapsed}s (7/10)"
        add_improvement "Investigate build time over 30 seconds."
      fi
    else
      echo 4
      echo "Performance: build failed (4/10)"
      add_improvement "Fix build failures before release."
    fi
  else
    echo 8
    echo "Performance: build script unavailable, static score used (8/10)"
    add_improvement "Add a build script or performance check for release confidence."
  fi
}

if [ ! -e "$TARGET_PATH" ]; then
  echo "QA Score: 0/${MAX_SCORE}"
  echo "Target path not found: ${TARGET_PATH}"
  echo "Improvements:"
  echo "- Pass an existing file or directory path."
  exit 0
fi

echo "QA Score Report"
echo "Target: ${TARGET_PATH}"
echo ""

coverage_output=$(score_coverage)
coverage_score=$(printf '%s\n' "$coverage_output" | sed -n '1p')
coverage_line=$(printf '%s\n' "$coverage_output" | sed -n '2p')
TOTAL_SCORE=$(( TOTAL_SCORE + coverage_score ))
echo "- ${coverage_line}"

lint_output=$(score_lint)
lint_score=$(printf '%s\n' "$lint_output" | sed -n '1p')
lint_line=$(printf '%s\n' "$lint_output" | sed -n '2p')
TOTAL_SCORE=$(( TOTAL_SCORE + lint_score ))
echo "- ${lint_line}"

complexity_output=$(score_complexity)
complexity_score=$(printf '%s\n' "$complexity_output" | sed -n '1p')
complexity_line=$(printf '%s\n' "$complexity_output" | sed -n '2p')
TOTAL_SCORE=$(( TOTAL_SCORE + complexity_score ))
echo "- ${complexity_line}"

type_output=$(score_type_safety)
type_score=$(printf '%s\n' "$type_output" | sed -n '1p')
type_line=$(printf '%s\n' "$type_output" | sed -n '2p')
TOTAL_SCORE=$(( TOTAL_SCORE + type_score ))
echo "- ${type_line}"

docs_output=$(score_documentation)
docs_score=$(printf '%s\n' "$docs_output" | sed -n '1p')
docs_line=$(printf '%s\n' "$docs_output" | sed -n '2p')
TOTAL_SCORE=$(( TOTAL_SCORE + docs_score ))
echo "- ${docs_line}"

performance_output=$(score_performance)
performance_score=$(printf '%s\n' "$performance_output" | sed -n '1p')
performance_line=$(printf '%s\n' "$performance_output" | sed -n '2p')
TOTAL_SCORE=$(( TOTAL_SCORE + performance_score ))
echo "- ${performance_line}"

if [ "$TOTAL_SCORE" -gt "$MAX_SCORE" ]; then
  TOTAL_SCORE=$MAX_SCORE
fi

echo ""
echo "QA Score: ${TOTAL_SCORE}/${MAX_SCORE}"

if [ "$TOTAL_SCORE" -ge 90 ]; then
  echo "Rating: Excellent - ready to ship"
elif [ "$TOTAL_SCORE" -ge 80 ]; then
  echo "Rating: Good - ship with warnings"
elif [ "$TOTAL_SCORE" -ge 70 ]; then
  echo "Rating: Needs improvement before release"
elif [ "$TOTAL_SCORE" -ge 60 ]; then
  echo "Rating: Review required"
else
  echo "Rating: Rework required"
fi

echo ""
echo "Improvements:"
if [ -s "$IMPROVEMENTS_FILE" ]; then
  cat "$IMPROVEMENTS_FILE"
else
  echo "- No immediate improvements detected."
fi

exit 0