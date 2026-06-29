---
name: codegraph
description: CodeGraph MCP로 코드베이스 구조를 그래프로 탐색하고 grep/Read보다 먼저 호출하는 구조 질의 워크플로우
---

# /codegraph 스킬: 구조적 코드 탐색

**목적:** 심볼·호출관계·영향범위 같은 구조적 질문을 grep 루프 대신 CodeGraph MCP tool로 직접 답합니다.

---

## 핵심 원칙

- 코드를 찾기 전에 **먼저 CodeGraph tool을 호출**합니다.
- CodeGraph tool 결과는 이미 읽은 소스로 취급하고 grep으로 재검증하지 않습니다.
- `.codegraph/`가 없으면 `codegraph init -i` 실행을 제안합니다.

---

## 우선 호출 tool

| 상황 | 먼저 호출할 tool |
|------|------------------|
| 코드 탐색 시작 (기본) | `codegraph_explore` |
| 심볼/텍스트 검색 | `codegraph_search` |
| 누가 이 함수를 호출하나 | `codegraph_callers` |
| 이 함수가 무엇을 호출하나 | `codegraph_callees` |
| 변경 영향 범위 | `codegraph_impact` |
| 인덱스 신선도 확인 | `codegraph_status` |

---

## 실행 계약

1. `.codegraph/` 인덱스가 없으면 `codegraph init -i`를 먼저 제안합니다.
2. 탐색은 `codegraph_explore`로 시작합니다.
3. 검색·호출관계·영향범위는 위 표의 tool로 답합니다.
4. 결과를 신뢰하고 grep/Read로 중복 검증하지 않습니다.
5. 편집 후에는 `codegraph_status`로 staleness 배너를 확인합니다.

---

## 사용 예시

```text
/codegraph login 함수 영향 범위
```

동작: `codegraph_explore`로 진입 → `codegraph_callers`/`codegraph_impact`로 호출자·영향 확인 → 결과를 소스로 취급.

---

**스킬 이름**: codegraph
**버전**: 1.0
