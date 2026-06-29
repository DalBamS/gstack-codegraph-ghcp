# 브라우저 데모 단계 (Playwright MCP)

login-app 페이지를 띄우고 Playwright MCP로 로그인 플로우를 검증하는 절차입니다. 브라우저 코드는 직접 작성하지 않고 Playwright MCP tool로 처리합니다.

## 1. 데모 서버 실행

```bash
cd examples/login-app
node serve.js              # http://localhost:4173
```

페이지는 `auth.js`/`service.js`와 동일한 로직(`browser.js`)을 사용합니다. 데모 사용자: `a@b.com` / `pw`, 6회 이상 실패 시 `locked`.

## 2. QA 워크플로우로 검증 계획 생성

```bash
bash scripts/qa-workflow.sh http://localhost:4173
```

URL을 주면 Playwright MCP가 실행할 브라우저 검증 계획(title, visible state, accessibility, screenshot)을 출력합니다.

## 3. Playwright MCP 시연 시나리오

`data-testid`로 요소를 잡아 다음 흐름을 보여줍니다.

1. 페이지 열기 → 제목 `Login` 확인 + screenshot
2. `password=pw` 입력, submit → `result`가 `ok`(초록)
3. `password=bad` 입력, submit → `result`가 `denied`(빨강)
4. 6회 연속 시도 → `result`가 `locked`(주황) — rate limit 동작
5. accessibility snapshot으로 폼 라벨 검증

같은 인증 규칙이 Node 테스트와 브라우저에서 동일하게 검증되는 것을 강조합니다.
