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

## 5. /qa 코드 경로 실행

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

## 6. Playwright MCP Smoke Test

목적: 브라우저 검증이 bespoke browser harness가 아니라 Playwright MCP로 수행되는지 확인합니다.

프롬프트:

```text
Playwright MCP로 https://example.com 을 열고 title을 확인해줘.
```

기대 결과:

- `.vscode/mcp.json`의 `servers.playwright` 사용
- 페이지 title이 `Example Domain`으로 확인됨
- 별도 브라우저 하니스 코드 생성 없음

실패 시 확인할 파일:

- `.vscode/mcp.json`
- `.github/skills/qa/SKILL.md`

## 7. /memory 저장, 검색, Prune Dry Run

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

## 8. /ship PR Dry Run

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
