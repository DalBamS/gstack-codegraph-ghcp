---
name: codegraph
description: CodeGraph MCP로 코드베이스 구조를 그래프로 탐색하고 grep/Read보다 먼저 호출하는 구조 질의 워크플로우
---

# /codegraph 스킬: 구조적 코드 탐색

**목적:** 심볼·호출관계·영향범위 같은 구조적 질문을 grep 루프 대신 CodeGraph MCP tool로 직접 답합니다.

---

## 핵심 원칙

- 구조 질문은 코드를 찾기 전에 **먼저 `codegraph_explore`를 호출**합니다.
- explore 결과(소스+호출경로+영향범위)는 이미 읽은 소스로 취급하고 grep으로 재검증하지 않습니다.
- 인덱스는 저장 시 자동 동기화되며, 수동 확인이 필요하면 CLI `codegraph status`로 확인합니다.
- `.codegraph/`가 없으면 `codegraph init` 실행을 제안합니다.

---

## 우선 호출 tool

### MCP tool (Copilot이 실제 보는 것)

| tool | 한 번의 호출로 답하는 것 |
|------|--------------------------|
| `codegraph_explore` | 탐색·검색·호출자·callee·영향 범위·소스 읽기를 한 번에 |

### CLI 세분 조회 (선택, 터미널에서만)

`codegraph_explore` 결과로 부족할 때만 보조로 사용합니다. 나머지 codegraph_* tool은 MCP 기본 목록에 노출되지 않아 에이전트가 직접 호출할 수 없으므로 CLI 서브커맨드로 씁니다.

- `codegraph callers <symbol>`: 누가 이 함수를 호출하나
- `codegraph callees <symbol>`: 이 함수가 무엇을 호출하나
- `codegraph impact <symbol>`: 변경 영향 범위
- `codegraph node <symbol|file>`: 단일 심볼/파일 상세
- `codegraph status`: 인덱스 통계와 신선도 확인

---

## 실행 계약

1. `.codegraph/` 인덱스가 없으면 `codegraph init`을 먼저 제안합니다.
2. 구조 질문은 `codegraph_explore` 한 번으로 답합니다(소스+호출경로+영향범위 포함).
3. 부족할 때만 위 CLI 세분 조회를 보조로 사용합니다.
4. 결과를 신뢰하고 grep/Read로 중복 검증하지 않습니다.
5. 인덱스는 저장 시 자동 동기화되며, 수동 확인이 필요하면 CLI `codegraph status`를 씁니다.

---

## 사용 예시

```text
/codegraph login 함수 영향 범위
```

동작: `codegraph_explore`로 진입 → 한 번의 호출로 호출자·영향 범위·소스를 받아 그대로 신뢰. 부족하면 CLI `codegraph callers`/`codegraph impact`로 보강.

---

**스킬 이름**: codegraph
**버전**: 1.0
