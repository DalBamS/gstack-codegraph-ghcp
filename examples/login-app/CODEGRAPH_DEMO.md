# CodeGraph 데모 단계

이 샘플(`auth.js`, `service.js`)로 CodeGraph MCP 결과를 직접 확인하는 절차입니다. CLI 출력은 `/codegraph` 스킬이 호출하는 MCP tool과 동일합니다.

## 1. 설치 + 인덱싱

```bash
npm i -g @colbymchenry/codegraph
cd examples/login-app
codegraph init           # 심볼·관계가 인덱싱됨 (실제 수치는 실행 시 확인, .codegraph/, 커밋 안 함)
```

## 2. 조회 (codegraph_* tool과 동일 출력)

```bash
codegraph status              # 인덱스 통계 + 최신 여부
codegraph explore "login"     # 심볼/텍스트 검색
codegraph callers login       # 누가 login을 호출하나
codegraph callees authenticate # authenticate가 부르는 것
codegraph impact login        # login 변경 영향 범위
codegraph explore "login flow" # 진입점 탐색 + 소스 일괄
```

## 3. 예상 출력 형태 (CodeGraph 버전에 따라 수치·서식이 달라질 수 있음)

아래는 예상 형태이며 실제 실행 결과로 확인하세요.

```text
$ codegraph callers login
Callers of "login" (2):
  file      auth.test.js   auth.test.js:1
  function  authenticate   service.js:7

$ codegraph callees authenticate
Callees of "authenticate" (2):
  function  rateLimit  service.js:3
  function  login      auth.js:10

$ codegraph impact login
Impact of changing "login" — 3 affected symbols:
  auth.js       function login:10
  auth.test.js  file auth.test.js:1
  service.js    function authenticate:7
```

호출 그래프: `auth.test.js` + `service.js/authenticate` → `auth.js/login`, `authenticate` → `rateLimit`. grep 없이 영향 범위가 바로 보입니다.
