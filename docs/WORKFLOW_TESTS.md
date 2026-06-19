# Workflow Tests

이 문서는 `gstack-ghcp`가 GitHub Copilot 변환본으로서 반복 실행 가능한지 확인하는 수동/자동 검증 시나리오입니다.

## 1. Customization 구조 검증

목적: agents, skills, MCP 설정, script 권한이 Copilot 변환본 규칙을 만족하는지 확인합니다.

실행:

```bash
./scripts/validate-ghcp.sh
```

기대 결과:

```text
CHECK OK
```

실패 시 확인할 파일:

- `.github/agents/*.agent.md`
- `.github/skills/*/SKILL.md`
- `.vscode/mcp.json`
- `scripts/*.sh`
- `.gitignore`

## 2. QA Score 실행

목적: 코드 경로를 대상으로 0-100 품질 점수를 계산할 수 있는지 확인합니다.

실행:

```bash
./scripts/qa-score.sh .
```

기대 결과:

- `QA Score: <number>/100` 출력
- `Rating:` 출력
- `Improvements:` 출력
- 명령 종료 코드 `0`

실패 시 확인할 파일:

- `scripts/qa-score.sh`
- `README.md`

## 3. QA Workflow Report 실행

목적: 코드 경로를 대상으로 테스트 계획, QA Score 원문, 출시 판단이 하나의 리포트로 묶이는지 확인합니다.

실행:

```bash
./scripts/qa-workflow.sh .
```

리포트 파일 생성 확인:

```bash
./scripts/qa-workflow.sh . --report /tmp/gstack-ghcp-qa.md
test -s /tmp/gstack-ghcp-qa.md
```

URL 계획 확인:

```bash
./scripts/qa-workflow.sh https://example.com
```

기대 결과:

- `# QA Workflow Report` 출력
- 코드 경로 입력 시 `QA Score Output`과 `Release Decision` 출력
- URL 입력 시 Playwright MCP browser smoke checklist 출력
- URL 입력 시 별도 브라우저 하니스 코드 생성 없음

실패 시 확인할 파일:

- `scripts/qa-workflow.sh`
- `.github/skills/qa/SKILL.md`

## 4. /spec Dry Run

목적: 모호한 기능 요청을 이슈 생성 전 검토 가능한 사양으로 바꾸는지 확인합니다.

프롬프트:

```text
/spec "사용자가 이메일로 로그인할 수 있어야 함"
```

기대 결과:

- 기능 목표와 성공 기준 질문
- 사용자 스토리 3-5개
- 기술 요구사항
- Given/When/Then 인수 기준
- `gh issue create` 명령 미리보기
- 사용자 승인 전에는 GitHub 이슈를 만들지 않음

실패 시 확인할 파일:

- `.github/skills/spec/SKILL.md`

## 5. Spec Workflow Gate 실행

목적: GitHub 이슈 생성 전에 사양 문서의 필수 섹션, secret 패턴, 중복 검색/생성 명령 preview를 검증합니다.

실행:

```bash
cat > /tmp/gstack-ghcp-spec.md <<'SPEC'
# Email login

## Summary
사용자가 이메일과 비밀번호로 로그인할 수 있게 합니다.

## Scope
- 포함: 로그인 요청, 성공/실패 응답, 기본 오류 메시지
- 제외: OAuth, 2FA, 비밀번호 재설정

## User Stories
- As a user, I want to log in with email, so that I can access my account.

## Technical Requirements
- 로그인 요청을 처리하는 서버 엔드포인트가 필요합니다.
- 실패 응답은 사용자에게 안전한 메시지를 반환합니다.

## Acceptance Criteria
- Given 등록된 사용자, When 올바른 이메일과 비밀번호를 입력하면, Then 로그인에 성공합니다.
- Given 잘못된 비밀번호, When 로그인을 시도하면, Then 오류 메시지를 표시합니다.
SPEC

./scripts/spec-workflow.sh \
	--title "Email login" \
	--body /tmp/gstack-ghcp-spec.md \
	--label feature
```

기대 결과:

- `CHECK OK` 출력
- `gh issue list --search ...` preview 출력
- `gh issue create --title ... --body-file ...` preview 출력
- 실제 GitHub 이슈 생성 없음

실패 시 확인할 파일:

- `scripts/spec-workflow.sh`
- `.github/skills/spec/SKILL.md`

## 6. /qa 코드 경로 실행

목적: 코드 경로 또는 repo root를 대상으로 테스트 계획과 QA 점수를 연결하는지 확인합니다.

프롬프트:

```text
/qa .
```

기대 결과:

- 검증 범위 확인
- 테스트 계획 출력
- `./scripts/qa-workflow.sh .` 실행 또는 실행 전 확인
- QA Score와 출시 판단 출력

실패 시 확인할 파일:

- `.github/skills/qa/SKILL.md`
- `scripts/qa-score.sh`
- `scripts/qa-workflow.sh`

## 7. Playwright MCP Smoke Test

목적: 브라우저 검증이 bespoke browser harness가 아니라 Playwright MCP로 수행되는지 확인합니다.

프롬프트:

```text
Playwright MCP로 https://example.com 을 열고 title을 확인해줘.
```

기대 결과:

- `.vscode/mcp.json`의 `servers.playwright` 사용
- 페이지 title이 `Example Domain`으로 확인됨
- visible page state 또는 accessibility snapshot 확인
- 필요 시 screenshot 수집 가능 여부 확인
- 별도 브라우저 하니스 코드 생성 없음
- `$B`, `browse/dist/browse`, persistent Chromium daemon을 사용하지 않음

실패 시 확인할 파일:

- `.vscode/mcp.json`
- `.github/skills/qa/SKILL.md`

## 8. Review Workflow 실행

목적: diff 기반 review report가 변경 파일, whitespace, 위험 패턴, 테스트 공백을 출력하는지 확인합니다.

실행:

```bash
./scripts/review-workflow.sh --base HEAD --target HEAD
./scripts/review-workflow.sh --base HEAD --target HEAD --report /tmp/gstack-review.md
test -s /tmp/gstack-review.md
```

기대 결과:

- `# Review Workflow Report` 출력
- changed files, whitespace check, risk scan, test gap 섹션 출력
- 변경이 없어도 성공

실패 시 확인할 파일:

- `scripts/review-workflow.sh`
- `.github/skills/review/SKILL.md`

## 9. /review Dry Run

목적: Copilot `/review` 스킬이 실제 mutation 없이 review workflow로 연결되는지 확인합니다.

프롬프트:

```text
/review 현재 브랜치
```

기대 결과:

- base/target ref 확인
- `./scripts/review-workflow.sh --base origin/main --target HEAD` 실행 또는 preview
- findings가 있으면 severity와 근거를 먼저 표시
- merge/push/close 같은 mutation 없음

실패 시 확인할 파일:

- `.github/skills/review/SKILL.md`

## 10. Investigate Workflow 실행

목적: 원인 조사 리포트가 재현, 최소화, 가설, 계측, 회귀 검증 순서로 출력되는지 확인합니다.

실행:

```bash
./scripts/investigate-workflow.sh --symptom "workflow smoke test" --target .
./scripts/investigate-workflow.sh --symptom "workflow smoke test" --target . --report /tmp/gstack-investigate.md
test -s /tmp/gstack-investigate.md
```

기대 결과:

- `# Investigate Workflow Report` 출력
- reproduce, minimize, current signals, hypotheses, instrumentation, regression gate 섹션 출력
- `--command`만 주면 preview만 출력하고 실행하지 않음

실패 시 확인할 파일:

- `scripts/investigate-workflow.sh`
- `.github/skills/investigate/SKILL.md`

## 11. /investigate Dry Run

목적: Copilot `/investigate` 스킬이 원인 없이 바로 수정하지 않고 조사 루프로 들어가는지 확인합니다.

프롬프트:

```text
/investigate "validate-ghcp가 실패함"
```

기대 결과:

- 증상과 target path 확인
- 재현 명령이 있으면 승인 전 preview만 출력
- root cause 전 수정 금지
- 마지막에 `qa-workflow.sh` 회귀 검증 계획 제시

실패 시 확인할 파일:

- `.github/skills/investigate/SKILL.md`

## 12. /memory 저장, 검색, Prune Dry Run

목적: 결정, 패턴, 남은 작업을 `.github/memory/` 아래에 저장하고 정리 전 승인을 받는지 확인합니다.

프롬프트:

```text
/memory "gh CLI 명령은 실행 전에 사용자 확인을 받는다"
```

검색 프롬프트:

```text
/memory search "gh CLI"
```

Prune 프롬프트:

```text
/memory prune
```

기대 결과:

- 저장 전 기존 메모리 중복 확인
- 적절한 파일에 짧은 항목 저장
- 검색 시 관련 항목 요약
- prune은 삭제 후보를 먼저 보여주고 승인 전에는 수정하지 않음

실패 시 확인할 파일:

- `.github/skills/memory/SKILL.md`
- `.github/memory/decisions.md`
- `.github/memory/patterns.md`
- `.github/memory/backlog.md`

## 13. Memory Workflow Dry Run 실행

목적: 저장 전 중복 검색과 secret 검사를 수행하고, 승인 전에는 파일을 수정하지 않는지 확인합니다.

실행:

```bash
./scripts/memory-workflow.sh save \
	--type pattern \
	--title "gh approval" \
	--note "Show gh mutation commands before running."

./scripts/memory-workflow.sh search --query "gh approval"
./scripts/memory-workflow.sh prune --type backlog
```

기대 결과:

- save는 `CHECK OK`와 entry preview를 출력
- `--apply`가 없으면 `.github/memory/` 파일을 수정하지 않음
- search는 `rg` 또는 `grep` fallback으로 검색
- prune은 후보만 보여주고 파일을 수정하지 않음

실패 시 확인할 파일:

- `scripts/memory-workflow.sh`
- `.github/skills/memory/SKILL.md`

## 14. Ship Workflow Dry Run 실행

목적: 실제 merge 없이 PR 상태 확인 명령, 안전 게이트, merge/issue close preview를 출력하는지 확인합니다.

실행:

```bash
./scripts/ship-workflow.sh --pr 123 --issue 42
```

기대 결과:

- `CHECK OK` 출력
- `gh pr view 123 ...` preview 출력
- `gh pr checks 123` preview 출력
- `gh pr merge 123 --merge --delete-branch` preview 출력
- `gh issue close 42 ...` preview 출력
- 실제 GitHub merge/close 실행 없음

실패 시 확인할 파일:

- `scripts/ship-workflow.sh`
- `.github/skills/ship/SKILL.md`

## 15. /ship PR Dry Run

목적: PR 머지와 이슈 종료가 사용자 승인 게이트 뒤에 있는지 확인합니다.

프롬프트:

```text
/ship #123
```

기대 결과:

- `gh pr view #123` 명령 또는 결과 확인
- PR 제목, 상태, 연결 이슈 표시
- CI/check 실패 시 merge 중단
- `gh pr merge` 명령 미리보기
- `gh issue close` 명령 미리보기
- 사용자 승인 전에는 merge/close 실행 없음

실패 시 확인할 파일:

- `.github/skills/ship/SKILL.md`

## 16. Office Hours Workflow 실행

목적: 구현 전에 제품 아이디어를 실제 사용자 고통, 좁은 wedge, 성공 신호로 재정의하는지 확인합니다.

실행:

```bash
./scripts/office-hours-workflow.sh --idea "daily briefing app" --audience "busy founders"
./scripts/office-hours-workflow.sh --idea "daily briefing app" --report /tmp/gstack-office-hours.md
test -s /tmp/gstack-office-hours.md
```

기대 결과:

- `# Office Hours Workflow Report` 출력
- `Six Forcing Questions`, `Premise Checks`, `Candidate Paths`, `Downstream Commands` 섹션 출력
- `CHECK OK` 출력
- 파일, 브랜치, GitHub issue, 브라우저 세션 생성 없음

실패 시 확인할 파일:

- `scripts/office-hours-workflow.sh`
- `.github/skills/office-hours/SKILL.md`

## 17. Autoplan Workflow 실행

목적: gstack식 Think → Plan → Build → Review → Test → Ship → Reflect 체인을 Copilot dry-run 계획으로 생성하는지 확인합니다.

실행:

```bash
./scripts/autoplan-workflow.sh --idea "daily briefing app" --target .
./scripts/autoplan-workflow.sh --idea "daily briefing app" --target . --report /tmp/gstack-autoplan.md
test -s /tmp/gstack-autoplan.md
```

기대 결과:

- `# Autoplan Workflow Report` 출력
- `Repo Signals`, `Sprint Chain`, `Suggested Command Plan`, `Risk Register`, `Minimum Exit Criteria` 섹션 출력
- `CHECK OK` 출력
- 실제 worktree 생성, GitHub mutation, 브라우저 세션 생성 없음

실패 시 확인할 파일:

- `scripts/autoplan-workflow.sh`
- `.github/skills/autoplan/SKILL.md`

## 18. Review GitHub Context Preview 실행

목적: `/review`가 PR/issue 문맥을 mutation 없이 preview하고 diff review와 연결하는지 확인합니다.

실행:

```bash
./scripts/review-workflow.sh --base HEAD --target HEAD --pr 123 --issue 42
```

기대 결과:

- `GitHub Context` 섹션 출력
- `gh pr view 123 ...` preview 출력
- `gh issue view 42 ...` preview 출력
- `--run-gh` 없이 GitHub 조회 실행 없음
- merge, push, close 같은 mutation 없음

실패 시 확인할 파일:

- `scripts/review-workflow.sh`
- `.github/skills/review/SKILL.md`
