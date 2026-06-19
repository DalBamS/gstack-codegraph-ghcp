---
name: review
description: "Use when: reviewing a branch, PR, diff, or work-in-progress changes; runs diff-based risk review and test-gap dry-run."
---

# /review 스킬: 실행형 diff 리뷰

**목적:** base ref와 target ref 사이의 변경을 검토해 위험 패턴, 테스트 공백, 출시 전 확인 항목을 찾습니다.

---

## 입력과 출력

**입력:**
- base ref: 기본 `origin/main`
- target ref: 기본 `HEAD`
- 선택 입력: report path, fail-on-risk 여부

**출력:**
- 변경 파일 목록
- `git diff --check` 결과
- secret, shell, SQL, browser, LLM trust boundary 관련 고위험 패턴 scan
- 테스트 공백 안내
- `/qa` 또는 `qa-workflow.sh`로 이어지는 검증 권고

---

## 실행 계약

### 1단계: 범위 확인

기본 비교는 현재 브랜치와 `origin/main`입니다.

```bash
./scripts/review-workflow.sh --base origin/main --target HEAD
```

CI나 smoke test처럼 변경이 없는 비교에서는 다음처럼 실행합니다.

```bash
./scripts/review-workflow.sh --base HEAD --target HEAD
```

### 2단계: diff 기반 검토

`review-workflow.sh`는 다음을 실행합니다.

- `git diff --name-only`
- `git diff --check`
- diff risk scan
- source 변경 대비 test/spec 변경 여부 확인

### 3단계: 결과 해석

- whitespace check 실패는 수정 전까지 merge하지 않습니다.
- risk scan은 자동 차단이 아니라 사람이 확인할 review finding입니다.
- source 변경에 test/spec 변경이 없으면 명시적 이유를 남기거나 테스트를 추가합니다.

### 4단계: 후속 검증

리뷰에서 문제가 없으면 관련 경로에 QA를 실행합니다.

```bash
./scripts/qa-workflow.sh <TARGET_PATH>
```

---

## 사용 예시

```text
/review 현재 브랜치
```

실행:

```bash
./scripts/review-workflow.sh --base origin/main --target HEAD
```

리포트 파일 생성:

```bash
./scripts/review-workflow.sh --base origin/main --target HEAD --report /tmp/gstack-review.md
```

---

## 중요 원칙

- 리뷰는 버그, 보안 위험, 회귀 가능성, 누락된 테스트를 먼저 다룹니다.
- unrelated refactor는 review finding으로 만들지 않습니다.
- 자동 scan 결과는 사람이 확인할 단서이며, 최종 판단은 diff와 사양을 함께 보고 내립니다.
- 위험한 GitHub mutation은 `/ship`으로 넘깁니다.

---

**스킬 이름**: review
**버전**: 1.0
**마지막 업데이트**: 2026-06-19