---
name: autoplan
description: "Use when: turning an approved idea or spec into a build plan, sprint chain, worktree plan, review gate, QA gate, and ship checklist."
---

# /autoplan 스킬: 실행 가능한 sprint chain 생성

**목적:** gstack의 Think → Plan → Build → Review → Test → Ship → Reflect 흐름을 GitHub Copilot 환경에서 실행 가능한 dry-run 계획으로 만듭니다.

---

## 입력과 출력

**입력:**
- 정리된 기능 아이디어 또는 spec 요약
- target path
- 선택 입력: quick, standard, thorough mode

**출력:**
- repo signal 요약
- sprint chain
- 실행할 스크립트 순서
- risk register
- 완료 기준

---

## 실행 계약

### 1단계: 계획 생성

```bash
./scripts/autoplan-workflow.sh --idea "[아이디어]" --target .
```

특정 모듈이 있으면 target을 좁힙니다.

```bash
./scripts/autoplan-workflow.sh \
  --idea "[아이디어]" \
  --target src/auth \
  --mode thorough
```

### 2단계: plan gate 확인

autoplan 결과는 최소 다음 gate를 포함해야 합니다.

- `/office-hours` 또는 동등한 프레이밍 확인
- `/spec` 품질 게이트
- focused worktree 또는 branch 계획
- `/review` diff gate
- `/qa` 또는 Playwright MCP browser gate
- `/ship` dry-run
- `/memory` follow-up

### 3단계: 구현 전 사용자 승인

계획은 실행 명령을 preview하지만, branch 생성, GitHub issue 생성, PR merge, issue close는 사용자 승인 전 실행하지 않습니다.

---

## 중요 원칙

- plan은 implementation backlog가 아니라 검증 가능한 vertical slice여야 합니다.
- 각 단계는 다음 단계의 입력을 남깁니다.
- 테스트 또는 QA가 빠진 plan은 ship-ready가 아닙니다.
- UI/browser 작업은 Playwright MCP로 검증합니다.

---

**스킬 이름**: autoplan
**버전**: 1.0
**마지막 업데이트**: 2026-06-19
