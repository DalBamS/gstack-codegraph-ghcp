# Demo Guide

이 문서는 `gstack-ghcp`를 10~15분 안에 시연할 수 있도록 최소 경로를 정리한 통합 가이드입니다.

## 목표

- 예제 로그인 앱의 핵심 동작 확인 (`ok` / `denied` / `locked`)
- 코드/문서 품질 점수 확인
- CodeGraph로 호출 관계와 영향 범위 확인
- Playwright MCP 기반 브라우저 검증 흐름 확인

## 사전 준비

- 현재 위치: 저장소 루트
- 필수 도구: `node`, `bash`, `git`
- 브라우저 검증이 필요한 경우: `npx playwright install chrome` (최초 1회)

```bash
node -v
bash --version
```

## 1) 기본 구조 검증 (1분)

```bash
bash scripts/validate-ghcp.sh
```

기대 결과:

- `CHECK OK`

## 2) 로그인 로직 단위 테스트 (1분)

```bash
node examples/login-app/auth.test.js
node examples/login-app/service.test.js
```

기대 결과:

- `auth tests passed`
- `service tests passed`

## 3) QA 점수/리포트 확인 (2분)

```bash
bash scripts/qa-score.sh examples/login-app
bash scripts/qa-workflow.sh examples/login-app
```

기대 결과:

- `QA Score: <n>/100`
- 개선 항목과 출시 판단 리포트 출력

## 4) CodeGraph 데모 (3분)

CodeGraph CLI가 없다면 설치 후 인덱스를 생성합니다.

```bash
npm i -g @colbymchenry/codegraph
cd examples/login-app
codegraph init
codegraph status
codegraph callers login
codegraph callees authenticate
codegraph impact login
cd ../..
```

시연 포인트:

- 호출 흐름: `authenticate -> login`, `authenticate -> rateLimit`
- 변경 영향 범위: `login` 변경 시 테스트/서비스 레이어까지 확산

## 5) 브라우저 로그인 데모 (Playwright MCP) (5~7분)

### 5-1. 데모 서버 실행

```bash
cd examples/login-app
node serve.js
```

기본 URL:

- `http://localhost:4173`

데모 사용자:

- email: `a@b.com`
- password: `pw`

### 5-2. QA 브라우저 검증 계획 출력

새 터미널에서 저장소 루트로 이동 후 실행:

```bash
cd /workspaces/gstack-codegraph-ghcp
bash scripts/qa-workflow.sh http://localhost:4173
```

### 5-3. 수동 브라우저 확인 포인트

- 올바른 비밀번호(`pw`) 제출 -> `ok`
- 잘못된 비밀번호(`bad`) 제출 -> `denied`
- 실패 누적 6회 이상 -> `locked`
- 폼 라벨(Email/Password) 표시 확인

## 문제 해결

- `EADDRINUSE: 4173`:
  - 이미 서버가 실행 중입니다. 기존 서버를 사용하거나 기존 프로세스를 정리 후 재실행하세요.
- Playwright MCP에서 Chrome 미탐지:

```bash
npx playwright install chrome
```

- `codegraph` 명령을 찾을 수 없음:

```bash
npm i -g @colbymchenry/codegraph
```

## 데모 체크리스트

- [ ] `validate-ghcp.sh`가 `CHECK OK`를 출력했다.
- [ ] `auth.test.js`, `service.test.js`가 통과했다.
- [ ] `qa-score.sh` 점수와 개선 항목을 확인했다.
- [ ] `codegraph callers/callees/impact` 결과를 확인했다.
- [ ] 브라우저에서 `ok`, `denied`, `locked` 상태를 확인했다.
