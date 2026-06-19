---
name: spec
description: 모호한 요청을 5단계로 사양 문서로 변환하고 GitHub 이슈 생성
---

# /spec 스킬: 실행형 요구사항 사양화

**목적:** 자유 형식의 기능 요청을 구체적인 사양 문서(PRD)로 변환하고, 품질 게이트를 통과한 뒤 사용자 승인 하에 GitHub 이슈로 등록

---

## 🎯 입력과 출력

**입력:** 기능 아이디어 (모호할 수 있음)
```
"사용자 인증 기능 추가"
"대시보드 성능 개선"
"모바일 지원"
```

**출력:**
1. 사양 문서 (마크다운)
2. 사양 품질 게이트 결과
3. 중복 이슈 검색 명령 미리보기
4. GitHub 이슈 생성 명령 미리보기
5. 사용자 승인 후 GitHub 이슈

---

## 🔄 5단계 사양화 프로세스

### 1단계: 요청 명확화
- **목표**: 무엇을 구현할 것인가?
- **질문**: 
  - 이 기능의 비즈니스 목표는?
  - 해결하려는 문제는?
  - 성공 기준은?

### 2단계: 사용자 관점 정의
- **목표**: 누가 어떻게 사용할 것인가?
- **출력**: 사용자 스토리 3-5개
  ```
  As a [역할], I want [기능], so that [이점]
  ```

### 3단계: 기술 요구사항 도출
- **목표**: 어떻게 구현할 것인가?
- **포함**: 
  - API 엔드포인트 목록
  - 데이터 구조
  - 외부 의존성
  - 성능 기준

### 4단계: 인수 기준 작성
- **목표**: 언제 완료인가?
- **형식**: 
  ```
  Given [상황], When [동작], Then [결과]
  ```

### 5단계: 이슈 생성 및 승인
- **목표**: GitHub에 등록하고 팀 리뷰
- **도구**: `scripts/spec-workflow.sh`, `gh issue create`
- **내용**: 위의 1-4단계 결과를 마크다운 이슈로 변환하고 품질 게이트를 통과한 뒤 생성

---

## 실행 계약

### 0단계: 사전 점검

- repo 루트에서 실행합니다.
- `./scripts/validate-ghcp.sh`가 있으면 먼저 실행해 Copilot 변환본 구조를 확인합니다.
- GitHub 이슈 생성이 필요한 경우 `gh auth status`로 인증 상태를 확인합니다.
- 사용자 승인 전에는 `gh issue create`를 실행하지 않습니다.

### 1단계: 사양 초안 작성

사용자 요청이 모호하면 필요한 최소 질문을 합니다. 질문은 기능 목표, 사용자, 범위, 성공 기준을 확정하는 데 집중합니다.

### 2단계: 품질 게이트 실행

사양 문서를 파일로 만든 뒤 다음 명령을 실행합니다.

```bash
./scripts/spec-workflow.sh \
  --title "[기능명]" \
  --body docs/<spec-file>.md \
  --label feature
```

`spec-workflow.sh`는 다음을 확인합니다.

- Why 또는 Summary
- Scope
- User Stories
- Technical Requirements
- Acceptance Criteria
- secret/token/password/API key 패턴

### 3단계: 중복 이슈 검색

`spec-workflow.sh`가 다음 검색 명령을 미리 보여줍니다.

```bash
gh issue list --search "[기능명] in:title,body" --state open
```

사용자가 원하면 `--run-search`로 읽기 전용 검색을 실행할 수 있습니다.

### 4단계: 이슈 생성 승인

품질 게이트가 `CHECK OK`를 출력한 뒤에만 다음 명령을 사용자에게 보여줍니다.

```bash
gh issue create \
  --title "[기능명]" \
  --body-file docs/<spec-file>.md \
  --label feature
```

사용자가 명시적으로 승인하기 전에는 실행하지 않습니다.

---

## 📋 출력 템플릿

생성되는 GitHub 이슈 내용:

```markdown
# [기능명]

## 📝 요약
[기능이 해결하는 문제와 비즈니스 가치]

## 🎯 범위
- 포함: [이번 이슈에서 할 일]
- 제외: [이번 이슈에서 하지 않을 일]

## 👥 사용자 스토리
- As a [역할], I want...
- As a [역할], I want...

## 🛠️ 기술 요구사항
- API 엔드포인트: [목록]
- 데이터 구조: [요약]
- 외부 의존성: [목록]

## ✅ 인수 기준
- [ ] Given... When... Then...
- [ ] Given... When... Then...

## 📅 예상 규모
- 추정 시간: [X일]
- 우선순위: [High/Medium/Low]
```

---

## 🚀 사용 예시

### 사용자 요청:
```
/spec "사용자가 이메일로 로그인할 수 있어야 함"
```

### 스킬 동작:
1. Designer 또는 CEO가 질문 → 명확화
2. 사양 문서 작성
3. 품질 게이트 실행:
   ```bash
   ./scripts/spec-workflow.sh \
     --title "[기능명]" \
     --body docs/spec-content.md \
     --label feature
   ```
4. 중복 검색과 이슈 생성 명령을 사용자에게 보여줌:
   ```bash
   gh issue list --search "[기능명] in:title,body" --state open

   gh issue create \
     --title "[기능명]" \
     --body-file docs/spec-content.md \
     --label feature
   ```
5. 사용자 승인 후 실행
6. GitHub 이슈 생성 (예: #42)

---

## ⚙️ 기술 설정

### 사전 요구사항
- `gh` CLI 설치됨
- GitHub 리포지토리 접근 권한
- `.github/copilot-instructions.md`에 프로젝트명 정의

### 실행 환경
```bash
# 사양 품질 게이트
./scripts/spec-workflow.sh --title "..." --body docs/spec.md --label feature

# 이슈 생성 명령 (사용자 확인 필수)
gh issue create --title "..." --body-file docs/spec.md --label feature
```

---

## 📌 중요 원칙

✅ **5단계를 모두 완료해야 이슈 생성**
✅ **spec-workflow.sh 품질 게이트가 CHECK OK여야 이슈 생성**
✅ **중복 이슈 검색 명령을 먼저 보여줌**
✅ **gh CLI 명령은 사용자 승인 후 실행**
✅ **secret/token/password/API key는 이슈 본문에 포함하지 않음**
✅ **불명확한 부분은 재질문 (반복)**
✅ **출력 이슈는 디자이너가 검토 후 승인**

---

**스킬 이름**: spec  
**버전**: 1.0  
**마지막 업데이트**: 2026-06-19
