---
name: ship
description: 기능 완성 후 머지 및 연결된 GitHub 이슈 자동 종료
---

# /ship 스킬: 안전한 출시 dry-run

**목적:** 완성된 기능(코드 + 테스트)의 PR 상태를 확인하고, 안전한 merge/issue close 명령을 사용자 승인 전 dry-run으로 제시

---

## 🎯 입력과 출력

**입력:** 
- PR 번호 또는 브랜치명
- 연결된 GitHub 이슈 (예: Closes #42)

**출력:**
1. PR 상태와 체크 확인 명령
2. 안전 게이트 결과
3. merge 명령 미리보기
4. 연결 이슈 close 명령 미리보기
5. 사용자 승인 후 실행 결과

---

## 🔄 출시 프로세스

### 1단계: 머지 전 체크리스트
- [ ] PR이 main/develop 브랜치를 대상으로 함
- [ ] 모든 CI 체크 통과 (테스트, 린트, 타입)
- [ ] 최소 1명 리뷰 승인
- [ ] 이슈가 연결됨 (예: `Closes #42`)

### 2단계: dry-run 생성
- **도구**: `scripts/ship-workflow.sh`
- **내용**: PR 조회, 체크 조회, merge/close 명령 preview

### 3단계: 사용자 승인
- merge와 issue close는 사용자가 명시적으로 승인한 뒤에만 실행합니다.
- CI 실패, draft PR, review 미승인 상태면 merge하지 않습니다.

### 4단계: 연결 이슈 종료
- **도구**: `gh issue close`
- **대상**: PR에서 자동 감지한 연결 이슈
- **상태**: Closed (완료)

### 5단계: 릴리스 노트 생성 (선택)
- **도구**: `gh release create` 또는 GitHub Releases
- **내용**: 머지된 PR 요약

---

## 실행 계약

### 사전 점검

PR 번호와 연결 이슈를 확인합니다. 연결 이슈가 없으면 경고하고, 자동 close 명령은 만들지 않습니다.

```bash
./scripts/ship-workflow.sh --pr <PR_NUMBER> --issue <ISSUE_NUMBER>
```

읽기 전용 GitHub 조회까지 실행하려면 사용자의 확인을 받은 뒤 다음처럼 실행합니다.

```bash
./scripts/ship-workflow.sh --pr <PR_NUMBER> --issue <ISSUE_NUMBER> --run-checks
```

### 안전 게이트

- PR state가 OPEN이어야 합니다.
- Draft PR은 merge하지 않습니다.
- Required checks가 통과해야 합니다.
- 리뷰가 필요한 repo에서는 review decision이 APPROVED여야 합니다.
- 연결 이슈가 없으면 issue close를 실행하지 않습니다.
- `--admin`, `--auto` 같은 보호 우회 플래그는 사용하지 않습니다.

### 실제 실행

`ship-workflow.sh`는 다음 명령을 preview만 합니다. 사용자가 승인한 뒤에만 실행합니다.

```bash
gh pr merge <PR_NUMBER> --merge --delete-branch
gh issue close <ISSUE_NUMBER> --comment "Closed by PR #<PR_NUMBER>"
```

---

## 📋 실행 명령어

### 머지 + 이슈 종료

사용자 확인 후 실행할 명령어:

```bash
# Step 1: PR 정보 확인 (자동으로 실행)
gh pr view <PR_NUMBER> --json title,state,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup,body

# Step 2: PR 체크 확인
gh pr checks <PR_NUMBER>

# Step 3: dry-run 생성
./scripts/ship-workflow.sh --pr <PR_NUMBER> --issue <ISSUE_NUMBER>

# Step 4: 머지 실행 (사용자 확인 필수)
gh pr merge <PR_NUMBER> \
  --merge \
  --delete-branch

# Step 5: 연결 이슈 종료 (사용자 확인 필수)
# 이슈 번호는 PR body에서 자동 추출 (예: "Closes #42")
gh issue close <ISSUE_NUMBER> \
  --comment "Closed by PR #<PR_NUMBER>"
```

### 대화형 예시

```bash
# PR #123을 머지하려고 할 때
/ship #123

# 스킬 동작:
# 1. PR #123 정보 조회
# 2. 연결 이슈 감지 (예: Closes #42)
# 3. 사용자에게 표시:
#    - PR 제목, 설명, 리뷰 상태
#    - 연결 이슈: #42
#    - 실행할 명령어 미리 보기
# 4. 사용자 승인 후:
#    - PR 머지 실행
#    - 이슈 #42 자동 종료
#    - 완료 메시지
```

---

## 🛠️ 스킬 동작 흐름

```
사용자: /ship #123
  ↓
[1] PR #123 정보 조회
  - 제목, 설명, 상태
  - 연결 이슈 파싱 ("Closes #42")
  ↓
[2] 사전 체크
  - 모든 CI 통과? ✓
  - 리뷰 승인? ✓
  - 이슈 연결? ✓ (Closes #42)
  ↓
[3] 머지 명령 미리 보기
  ./scripts/ship-workflow.sh --pr 123 --issue 42
  gh pr merge 123 --merge --delete-branch
  ↓
[4] 사용자 승인 ("Yes" 또는 "Go")
  ↓
[5] 머지 실행
  ↓
[6] 이슈 종료 명령 미리 보기
  gh issue close 42 --comment "Closed by PR #123"
  ↓
[7] 사용자 승인
  ↓
[8] 이슈 종료 실행
  ↓
✅ 완료: PR 머지됨, 이슈 #42 종료됨
```

---

## ⚙️ 기술 설정

### 사전 요구사항
- `gh` CLI 설치됨 (`brew install gh` 또는 `choco install gh`)
- GitHub 리포지토리에 권한 있음 (`gh auth login`)
- PR이 develop/main 대상

### 지원하는 머지 전략
- **--merge**: 일반 머지 커밋 (기본)
- **--squash**: 스쿼시 머지 (선택)
- **--rebase**: 리베이스 머지 (선택)

### 환경 변수
```bash
# GitHub 토큰 (자동으로 gh CLI가 관리)
GH_TOKEN=ghp_xxxx

# 리포지토리 (자동으로 감지)
GITHUB_REPOSITORY=owner/repo
```

---

## 📌 중요 원칙

✅ **gh CLI 명령은 항상 사용자 확인 후 실행**  
✅ **머지 전에 모든 CI 체크 통과 확인**  
✅ **연결 이슈가 없으면 경고**  
✅ **머지 후 자동으로 브랜치 삭제**  
✅ **이슈 종료 시 완료 댓글 추가**  
✅ **--admin, --auto 같은 보호 우회 플래그 금지**

---

## 🚨 에러 처리

| 상황 | 동작 |
|------|------|
| CI 실패 | 머지 중단, 실패 이유 표시 |
| 이슈 연결 없음 | 경고하지만 머지는 진행 |
| 이미 머지됨 | "PR이 이미 머지됨" 메시지 |
| gh CLI 미설치 | "gh CLI 설치 필요" 안내 |

---

**스킬 이름**: ship  
**버전**: 1.0  
**마지막 업데이트**: 2026-06-19
