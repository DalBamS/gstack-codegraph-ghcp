---
name: investigate
description: "Use when: debugging a bug, broken behavior, failing command, or root cause investigation; runs reproduce-minimize-hypothesize workflow."
---

# /investigate 스킬: 실행형 원인 조사

**목적:** 버그나 실패를 바로 고치지 않고, 재현 → 최소화 → 가설 → 계측 → 수정 → 회귀 검증 순서로 원인을 좁힙니다.

---

## 입력과 출력

**입력:**
- 증상 설명
- 대상 경로
- 선택 입력: 재현 명령

**출력:**
- 조사 리포트
- 현재 git 상태와 최근 커밋
- 증상 키워드 검색 신호
- 가설 목록
- 계측 계획
- 수정 전 회귀 검증 계획

---

## 실행 계약

### 1단계: 재현

증상과 대상 경로를 명시합니다.

```bash
./scripts/investigate-workflow.sh \
  --symptom "qa score dropped" \
  --target .
```

재현 명령이 있으면 먼저 preview만 남깁니다.

```bash
./scripts/investigate-workflow.sh \
  --symptom "login returns 500" \
  --target src/auth \
  --command "npm test -- auth"
```

사용자가 승인한 뒤에만 `--run-command`를 붙여 실행합니다.

### 2단계: 최소화

- 실패 경로, 파일, 입력, 상태를 최소 단위로 줄입니다.
- 큰 검색보다 먼저 한 가지 싼 반증 체크를 수행합니다.

### 3단계: 가설 수립

최소 세 가지를 구분합니다.

- 최근 변경이 원인
- 환경/설정/외부 서비스가 원인
- 관찰 또는 테스트가 불완전함

### 4단계: 계측

가설을 구분하는 가장 작은 로그, assertion, focused test를 추가합니다.

### 5단계: 수정과 회귀 검증

원인이 확인된 뒤에만 수정합니다. 수정 후 관련 경로에 QA를 실행합니다.

```bash
./scripts/qa-workflow.sh <TARGET_PATH>
```

---

## 사용 예시

```text
/investigate "validate-ghcp가 CI에서 실패함"
```

실행:

```bash
./scripts/investigate-workflow.sh \
  --symptom "validate-ghcp fails in CI" \
  --target .github/workflows
```

---

## 중요 원칙

- 원인 없이 수정하지 않습니다.
- 재현 명령은 사용자 승인 없이 실행하지 않습니다.
- 조사 중 만든 임시 로그나 계측은 ship 전에 제거합니다.
- 회귀 테스트 또는 QA 재실행 없이 완료로 판단하지 않습니다.

---

**스킬 이름**: investigate
**버전**: 1.0
**마지막 업데이트**: 2026-06-19