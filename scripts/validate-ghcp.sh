#!/usr/bin/env bash

set -u

FAILURES=0

pass() {
  echo "PASS $1"
}

fail() {
  echo "FAIL $1"
  FAILURES=$((FAILURES + 1))
}

require_file() {
  if [ -f "$1" ]; then
    pass "$1 exists"
  else
    fail "$1 is missing"
  fi
}

frontmatter_has_key() {
  file_path="$1"
  key="$2"

  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter { print }
  ' "$file_path" | grep -Eq "^${key}:[[:space:]]*[^[:space:]].*"
}

validate_skill() {
  skill_name="$1"
  skill_file=".github/skills/${skill_name}/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    fail "$skill_file is missing"
    return
  fi

  if frontmatter_has_key "$skill_file" "name"; then
    declared_name="$(awk '
      NR == 1 && $0 == "---" { in_frontmatter = 1; next }
      in_frontmatter && $0 == "---" { exit }
      in_frontmatter && /^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }
    ' "$skill_file")"

    case "$declared_name" in
      /*|*/*)
        fail "$skill_file name must not include a namespace or slash: ${declared_name}"
        ;;
      "$skill_name")
        pass "$skill_file name is ${declared_name}"
        ;;
      *)
        fail "$skill_file name should be ${skill_name}, got ${declared_name}"
        ;;
    esac
  else
    fail "$skill_file frontmatter is missing name"
  fi

  if frontmatter_has_key "$skill_file" "description"; then
    pass "$skill_file has description"
  else
    fail "$skill_file frontmatter is missing description"
  fi
}

validate_agent() {
  agent_file="$1"

  if frontmatter_has_key "$agent_file" "name"; then
    pass "$agent_file has name"
  else
    fail "$agent_file frontmatter is missing name"
  fi

  if frontmatter_has_key "$agent_file" "description"; then
    pass "$agent_file has description"
  else
    fail "$agent_file frontmatter is missing description"
  fi
}

validate_mcp() {
  mcp_file=".vscode/mcp.json"
  require_file "$mcp_file"

  if [ ! -f "$mcp_file" ]; then
    return
  fi

  if ! command -v node >/dev/null 2>&1; then
    compact_json="$(tr -d '[:space:]' < "$mcp_file")"

    case "$compact_json" in
      *'"mcpServers"'*)
        fail "${mcp_file} must use top-level key \"servers\", not \"mcpServers\""
        ;;
      *'"servers"'*)
        pass "${mcp_file} has top-level servers object"
        ;;
      *)
        fail "${mcp_file} is missing top-level \"servers\" object"
        ;;
    esac

    case "$compact_json" in
      *'"playwright"'*)
        pass "${mcp_file} has servers.playwright"
        ;;
      *)
        fail "${mcp_file} is missing servers.playwright"
        ;;
    esac

    case "$compact_json" in
      *'"command":"npx"'*)
        pass "${mcp_file} playwright command is npx"
        ;;
      *)
        fail "${mcp_file} playwright command should be npx"
        ;;
    esac

    case "$compact_json" in
      *'"args":["@playwright/mcp@latest"]'*)
        pass "${mcp_file} playwright args are correct"
        ;;
      *)
        fail "${mcp_file} playwright args should be [\"@playwright/mcp@latest\"]"
        ;;
    esac

    case "$compact_json" in
      *'"codegraph"'*)
        pass "${mcp_file} has servers.codegraph"
        ;;
      *)
        fail "${mcp_file} is missing servers.codegraph"
        ;;
    esac

    return
  fi

  node <<'NODE'
const fs = require('fs');
const filePath = '.vscode/mcp.json';

function fail(message) {
  console.log(`FAIL ${message}`);
  process.exitCode = 1;
}

function pass(message) {
  console.log(`PASS ${message}`);
}

let data;
try {
  data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
} catch (error) {
  fail(`${filePath} is not valid JSON: ${error.message}`);
  process.exit();
}

if (Object.prototype.hasOwnProperty.call(data, 'mcpServers')) {
  fail(`${filePath} must use top-level key "servers", not "mcpServers"`);
}

if (!data.servers || typeof data.servers !== 'object') {
  fail(`${filePath} is missing top-level "servers" object`);
} else {
  pass(`${filePath} has top-level servers object`);
}

const playwright = data.servers && data.servers.playwright;
if (!playwright) {
  fail(`${filePath} is missing servers.playwright`);
} else {
  pass(`${filePath} has servers.playwright`);

  if (playwright.command === 'npx') {
    pass(`${filePath} playwright command is npx`);
  } else {
    fail(`${filePath} playwright command should be npx`);
  }

  const expectedArgs = ['@playwright/mcp@latest'];
  if (JSON.stringify(playwright.args) === JSON.stringify(expectedArgs)) {
    pass(`${filePath} playwright args are correct`);
  } else {
    fail(`${filePath} playwright args should be ${JSON.stringify(expectedArgs)}`);
  }
}

const codegraph = data.servers && data.servers.codegraph;
if (!codegraph) {
  fail(`${filePath} is missing servers.codegraph`);
} else {
  pass(`${filePath} has servers.codegraph`);
}
NODE

  if [ "$?" -ne 0 ]; then
    FAILURES=$((FAILURES + 1))
  fi
}

validate_script_permissions() {
  for script_file in scripts/*.sh; do
    [ -e "$script_file" ] || continue

    tracked_mode="$(git ls-files --stage -- "$script_file" | awk '{ print $1 }')"
    if [ -n "$tracked_mode" ]; then
      if [ "$tracked_mode" = "100755" ]; then
        pass "$script_file is executable in git index"
      else
        fail "$script_file should be executable in git index, got ${tracked_mode}"
      fi
    elif [ -x "$script_file" ]; then
      pass "$script_file is executable on disk"
    else
      fail "$script_file should be executable"
    fi
  done
}

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "FAIL not inside a git repository"
  exit 1
fi

cd "$REPO_ROOT" || exit 1

echo "gstack-ghcp validation"
echo "Repository: ${REPO_ROOT}"
echo ""

validate_mcp

echo ""
for skill_name in office-hours autoplan spec ship qa memory review investigate codegraph; do
  validate_skill "$skill_name"
done

echo ""
agent_count="$(find .github/agents -maxdepth 1 -type f -name '*.agent.md' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$agent_count" = "6" ]; then
  pass ".github/agents contains 6 agent files"
else
  fail ".github/agents should contain 6 agent files, got ${agent_count}"
fi

for agent_file in .github/agents/*.agent.md; do
  [ -e "$agent_file" ] || continue
  validate_agent "$agent_file"
done

echo ""
validate_script_permissions

echo ""
if grep -Eq '^worktrees/$' .gitignore 2>/dev/null; then
  pass ".gitignore ignores worktrees/"
else
  fail ".gitignore should include worktrees/"
fi

if grep -Eq '^\.codegraph/$' .gitignore 2>/dev/null; then
  pass ".gitignore ignores .codegraph/"
else
  fail ".gitignore should include .codegraph/"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "CHECK OK"
  exit 0
fi

echo "CHECK FAILED: ${FAILURES} issue(s) found"
exit 1