---
name: qa
description: 테스트 계획 수립, Playwright MCP 브라우저 검증, qa-score.sh 기반 0-100 품질 점수 계산
---

# /qa 스킬: 실행형 품질 검증

**목적:** 사양, PR, 코드 경로, URL을 입력받아 테스트 계획을 만들고, 가능한 검증은 실제 명령으로 실행하며, 브라우저 검증은 Playwright MCP로 수행합니다.

---

## 입력과 출력

**입력:**
- 코드 경로: `.`, `src/auth`, `scripts/qa-score.sh`
- URL: `https://example.com`
- PR 또는 이슈: `PR #42`, `issue #42`
- 사양 문서: `docs/auth-spec.md`
- 선택 입력: 검증할 사용자 흐름, 품질 목표, 출시 기준

**출력:**
- 테스트 계획
- 실행한 명령과 결과
- Playwright MCP 브라우저 검증 결과 또는 실행 계획
- QA Score와 개선 항목
- 출시 판단

---

## 입력 라우팅

| 입력 | 실행 방식 | 실제 명령 또는 도구 |
|------|-----------|---------------------|
| 기존 코드 경로 | QA 점수와 리포트 생성 | `./scripts/qa-workflow.sh <TARGET_PATH>` |
| URL | Playwright MCP 브라우저 검증 계획 출력 후 MCP 실행 | `./scripts/qa-workflow.sh <URL>` + Playwright MCP |
| PR 번호 | 변경 파일을 확인한 뒤 관련 경로 QA | `gh pr view <PR> --json files,title,body` 후 경로별 QA |
| 이슈 번호 | 인수 기준을 테스트 항목으로 변환 | `gh issue view <ISSUE> --json title,body,labels` |
| 사양 문서 | 인수 기준을 테스트 항목으로 변환 | 문서 읽기 후 관련 경로 QA |

---

## 0-100 점수 스케일

PLAN.md와 동일한 스케일을 사용합니다.

- **90-100**: 우수, 출시 가능
- **80-89**: 양호, 경고 조건 있음
- **70-79**: 미흡, 출시 전 개선 필수
- **60-69**: 부족, 리뷰 필요
- **0-59**: 불충분, 재작업

---

## 실행 계약

### 0단계: 사전 점검

- repo 루트에서 실행합니다.
- `./scripts/validate-ghcp.sh`가 있으면 먼저 실행해 Copilot 변환본 구조를 확인합니다.
- 코드 경로 입력이면 대상이 존재하는지 확인합니다.
- URL 입력이면 `.vscode/mcp.json`의 `servers.playwright` 설정을 확인합니다.
- `gh` 명령이 필요한 PR/이슈 입력은 실행 전에 조회 명령을 사용자에게 보여줍니다.

### 1단계: 입력 분류

입력을 다음 중 하나로 분류합니다.

- `code-path`: 존재하는 파일 또는 디렉터리
- `browser-url`: `http://` 또는 `https://` URL
- `pull-request`: `PR #<number>` 또는 `#<number>` 문맥상 PR
- `issue`: `issue #<number>`
- `spec-doc`: 마크다운 사양 문서

분류가 모호하면 필요한 최소 질문만 합니다.

### 2단계: 테스트 계획 수립

- 사양이 있으면 인수 기준을 테스트 항목으로 변환합니다.
다음 범주로 테스트를 나눕니다.

- 단위 테스트: 핵심 로직과 예외 처리
- 통합 테스트: API, 파일 시스템, 데이터 흐름
- 브라우저 테스트: 실제 사용자 흐름, 화면 상태, 접근성
- 회귀 테스트: 이전에 깨졌던 동작

### 3단계: 실행

#### 코드 경로

코드 경로가 있으면 다음 명령을 실행합니다.

```bash
./scripts/qa-workflow.sh <TARGET_PATH>
```

리포트 파일이 필요하면 다음처럼 실행합니다.

```bash
./scripts/qa-workflow.sh <TARGET_PATH> --report /tmp/gstack-ghcp-qa.md
```

`qa-workflow.sh`는 내부에서 `./scripts/qa-score.sh <TARGET_PATH>`를 호출하고, 테스트 계획, 원본 점수 출력, 출시 판단을 하나의 QA Workflow Report로 묶습니다.

#### URL

UI, E2E, 스크린샷, 사용자 상호작용 검증이 필요하면 직접 브라우저 자동화 코드를 작성하지 않고 Playwright MCP를 사용합니다.

MCP 설정은 `.vscode/mcp.json`의 다음 서버를 기준으로 합니다.

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

브라우저 검증 전에는 다음을 사용자에게 보여줍니다.

- 대상 URL
- 검증할 사용자 흐름
- 수집할 결과: title, visible state, accessibility snapshot, screenshot 등
- 실행할 Playwright MCP 작업

URL 입력만으로는 shell script가 브라우저를 직접 실행하지 않습니다. 먼저 다음 명령으로 검증 계획을 출력하고, 이후 Playwright MCP를 사용합니다.

```bash
./scripts/qa-workflow.sh <URL>
```

#### PR 또는 이슈

GitHub CLI가 필요한 조회 명령은 먼저 사용자에게 보여준 뒤 실행합니다.

```bash
gh pr view <PR_NUMBER> --json title,body,files,reviewDecision,statusCheckRollup
gh issue view <ISSUE_NUMBER> --json title,body,labels,state
```

조회 결과에서 변경 파일이나 인수 기준을 추출한 뒤 관련 코드 경로에 `qa-workflow.sh`를 실행합니다.

### 4단계: 출시 판단

점수와 테스트 결과를 결합해서 다음 중 하나로 결론을 냅니다.

- 출시 가능
- 경고 조건부 출시 가능
- 출시 전 수정 필요
- 재작업 필요

### 5단계: 실패 처리

| 상황 | 동작 |
|------|------|
| 대상 경로 없음 | `qa-score.sh`가 0점 리포트와 개선 항목을 출력하고 종료 코드 0으로 graceful 처리 |
| `gh` 미설치 또는 미로그인 | PR/이슈 조회를 멈추고 필요한 인증 명령 안내 |
| Playwright MCP 설정 없음 | `.vscode/mcp.json` 수정 필요 항목 표시 |
| 브라우저 검증 실패 | 실패한 흐름, 관찰 결과, 재현 절차를 QA report에 기록 |
| 점수 70점 미만 | 출시 금지, 수정 또는 재작업 권고 |

---

## qa-score.sh 평가 항목

`scripts/qa-score.sh`는 다음 항목을 합산해 0-100점을 계산합니다. `scripts/qa-workflow.sh`는 이 결과를 테스트 계획과 출시 판단으로 감쌉니다.

- 테스트 커버리지: 25점
- 린트 상태: 10점
- 코드 복잡도: 20점
- 타입 안정성: 20점
- 문서화: 15점
- 성능/빌드 신호: 10점

각 항목은 개선 항목을 함께 출력해야 합니다.

---

## 사용 예시

### 사양 기반 QA

```text
/qa docs/auth-spec.md
```

동작:

1. 사양의 인수 기준을 테스트 계획으로 변환
2. 브라우저 흐름이 있으면 Playwright MCP로 검증 계획 수립
3. 관련 코드 경로에 대해 `./scripts/qa-workflow.sh` 실행
4. 점수와 개선 항목 출력

### 코드 경로 기반 QA

```text
/qa .
```

동작:

1. repo 루트를 검증 범위로 확정
2. `./scripts/validate-ghcp.sh` 실행 가능 여부 확인
3. `./scripts/qa-workflow.sh .` 실행
4. QA Workflow Report 출력

### URL 기반 QA

```text
/qa https://example.com "title 확인"
```

동작:

1. URL과 사용자 흐름을 보여주고 확인 요청
2. `./scripts/qa-workflow.sh https://example.com`으로 브라우저 검증 계획 출력
3. Playwright MCP로 페이지 열기
4. title, visible state, 필요한 snapshot을 확인
5. 브라우저 결과와 출시 판단 출력

### PR 기반 QA

```text
/qa PR #42
```

동작:

1. PR 변경 파일 확인
2. 테스트 계획 작성
3. 필요한 브라우저 검증 수행
4. 관련 코드 경로에 `qa-workflow.sh` 실행

---

## 중요 원칙

- 브라우저 작업은 Playwright MCP를 사용합니다.
- 직접 브라우저 하니스나 별도 E2E 프레임워크 코드를 새로 만들지 않습니다.
- `qa-score.sh`는 항상 0-100 스케일로 결과를 보고합니다.
- `qa-workflow.sh`는 테스트 계획, QA Score 원문, 출시 판단을 함께 출력합니다.
- 도구가 설치되어 있지 않아도 graceful하게 처리하고 개선 항목에 기록합니다.
- GitHub CLI, 브라우저 검증, 긴 실행 명령은 실행 전 사용자에게 확인합니다.

---

**스킬 이름**: qa
**버전**: 1.0
**마지막 업데이트**: 2026-06-19