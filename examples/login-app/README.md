# login-app (워크플로우 데모 샘플)

gstack-ghcp 스킬/스크립트 흐름을 실제로 돌려보기 위한 최소 예제입니다.

- `auth.js`: 이메일/비밀번호 로그인 로직
- `service.js`: rate limit + authenticate (login 호출)
- `auth.test.js`, `service.test.js`: `node *.test.js`로 실행하는 테스트
- `index.html` + `browser.js` + `serve.js`: 브라우저 로그인 데모 (Playwright MCP)

`./scripts/qa-score.sh examples/login-app`로 점수를 확인할 수 있습니다.
CodeGraph 결과 확인은 `CODEGRAPH_DEMO.md`, 브라우저 검증은 `BROWSER_DEMO.md`를 따르세요.
