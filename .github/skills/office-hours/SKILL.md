---
name: office-hours
description: "Use when: a feature idea is vague, product direction needs pushback, or the user asks what to build first; runs problem-framing office-hours dry-run."
---

# /office-hours 스킬: 문제 재정의와 좁은 시작점 찾기

**목적:** 구현 전에 사용자의 요청을 더 날카로운 문제 정의, 작은 wedge, 검증 가능한 성공 신호로 바꿉니다.

---

## 입력과 출력

**입력:** 기능 아이디어, 대상 사용자, 현재 pain point

**출력:**
- 여섯 가지 forcing question
- 전제 검토
- 좁은 wedge 후보
- `/autoplan`과 `/spec`으로 넘길 handoff

---

## 실행 계약

### 1단계: 문제를 기능명에서 분리

사용자가 말한 기능명을 그대로 구현 대상으로 확정하지 않습니다. 먼저 실제 pain, 사용자, 기존 workaround, 성공 신호를 확인합니다.

```bash
./scripts/office-hours-workflow.sh --idea "<idea>" --audience "<audience>"
```

### 2단계: 여섯 질문으로 압축

스킬은 다음을 확인합니다.

- 지금 해결해야 하는 구체적 사례
- 가장 아픈 사용자
- 첫 버전의 즉시 유용성
- solution guess와 observed problem의 차이
- 첫 wedge에서 제외할 범위
- 계속/중단/전환을 결정할 신호

### 3단계: 좁은 wedge 선택

선택한 wedge는 `/autoplan`으로 넘깁니다.

```bash
./scripts/autoplan-workflow.sh --idea "<refined problem>" --target .
```

---

## 중요 원칙

- 기능을 바로 만들기 전에 문제를 먼저 재정의합니다.
- 큰 비전을 부정하지 않고, 첫 release에서 배울 수 있는 최소 단위를 고릅니다.
- GitHub issue 생성은 `/spec` 품질 게이트 뒤로 미룹니다.
- 브라우저 검증이 필요해도 Playwright MCP만 사용합니다.

---

**스킬 이름**: office-hours
**버전**: 1.0
**마지막 업데이트**: 2026-06-19
