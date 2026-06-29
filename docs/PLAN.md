# gstack-ghcp 구현 계획

> GitHub Copilot용 브라우저 하니스 제외 변환본
> 
> 이 문서는 초급 개발자를 위해 작은 단계로 쪼갠 구현 로드맵입니다.

---

## 📋 목표

gstack(GitHub Stack)의 역할 기반 에이전트 시스템을 GitHub Copilot 환경에 최적화하여, 대규모 팀 협업 자동화를 지원하는 AI 네트워크를 구축합니다.

**세 개의 핵심 레이어:**
1. **역할 에이전트** (`.github/agents/`) - CEO, Designer, Eng Manager, Release Manager, Doc Engineer, QA
2. **공유 스킬** (`.github/skills/`) - /office-hours, /autoplan, /spec, /qa, /review, /investigate, /ship, /memory
3. **자동화 스크립트** (`scripts/`) - Git 워크트리 병렬화, dry-run 워크플로우, QA 스코어링, 구조 검증

### 현재 상태

이 문서는 초기 구현 계획이 아니라 **완료된 Copilot 변환본의 유지보수/강화 계획**입니다.

- 역할 에이전트, 공유 스킬, Playwright MCP 설정, 자동화 스크립트, CI smoke validation은 기본 구현 완료 상태입니다.
- 현재 보강 중인 영역은 plan review 깊이, 문서형/코드형 QA 점수 분리, `.github/memory/` seed 구조, 문서 최신성 유지입니다.
- 원본 gstack의 browser daemon, browser CLI, telemetry/update/checkpoint/gbrain 계층은 범위 밖입니다.

---

## 🎯 레이어 1: 역할 에이전트 (`.github/agents/`)

### 개념 설명
**역할 에이전트**란?
- 특정 직무(CEO, 설계자, 엔지니어 매니저 등)를 시뮬레이션하는 전문화된 AI 에이전트
- 각 에이전트는 `.agent.md` 파일로 정의되고, 특정 작업 스타일과 도구에 접근 권한을 가짐
- GitHub Copilot에서 호출 가능: `/spec`, `/ship`, `/qa`, `/memory` 같은 스킬 사용

### 구현 구조

```
.github/agents/
├── ceo.agent.md              # 전략·방향성 결정
├── designer.agent.md         # UI/UX·아키텍처 설계
├── eng-manager.agent.md      # 코드 품질·PR 리뷰
├── release-manager.agent.md  # 배포·버전·변경 로그
├── doc-engineer.agent.md     # 문서화·예제·튜토리얼
└── qa.agent.md               # 테스트·버그 리포팅·성능
```

### 각 에이전트 역할 정의

| 에이전트 | 주요 책임 | 도구 접근 | 주요 작업 방식 |
|---------|---------|---------|----------|
| **CEO** | 전체 전략, 기능 우선순위, 마일스톤 | 프로젝트 관리, 이슈 트리징 | 자연어로 전략 수립, 마일스톤 결정 |
| **Designer** | UI/UX 설계, 컴포넌트 구조, API 설계 | 프로토타입, 다이어그램, 설계 문서 | `/spec` 스킬로 사양 작성, 설계 검토 |
| **Eng Manager** | 코드 품질, PR 리뷰, 성능 최적화 | 코드 검토, 리팩토링, 테스트 | `/ship` 스킬로 출시 준비 검증, 코드 리뷰 |
| **Release Manager** | 배포 파이프라인, 버전 관리, 체인지로그 | Git 태깅, 릴리스 스크립트 | 자연어로 배포 계획, 버전 결정 |
| **Doc Engineer** | 문서 작성, 예제 코드, 튜토리얼 | 문서 구조화, 콘텐츠 생성 | 자연어로 문서 구조 설계, 콘텐츠 작성 |
| **QA** | 테스트 계획, 버그 감지, 품질 점수 계산 (0-100) | 테스트 작성, 버그 보고, 성능 측정 | `/qa` 스킬로 테스트 계획 수립, `/memory` 스킬로 학습 저장 |

### 구현 단계

#### **단계 1: CEO 에이전트 프레임 작성** (검토 대상)
- 파일: `.github/agents/ceo.agent.md`
- 내용:
  - 이 에이전트가 할 일 (WHAT)
  - 작업 방식 (HOW) - 전략적·장기적 사고
  - 도구 접근 (WHICH TOOLS) - 프로젝트 이슈만
  - 예제 워크플로우

**체크포인트:** CEO 에이전트가 기능 제안을 받고 마일스톤을 제시하는 방식이 명확한가?

---

#### **단계 2: Designer 에이전트 작성** (검토 대상)
- 파일: `.github/agents/designer.agent.md`
- 내용:
  - 설계 문제 해결 능력
  - API·컴포넌트 구조화
  - 다른 에이전트와의 협력 지점 (CEO의 요청 → 설계)

**체크포인트:** Designer가 CEO의 결정을 받아 구체적인 설계안을 제시하는 워크플로우가 있는가?

---

#### **단계 3: Eng Manager 에이전트 작성** (검토 대상)
- 파일: `.github/agents/eng-manager.agent.md`
- 내용:
  - 코드 리뷰 기준
  - 성능 최적화 포인트
  - Designer의 설계를 실제 코드로 구현 검증

**체크포인트:** PR 리뷰 시 설계와 구현이 일치하는지 확인하는 프로세스가 있는가?

---

#### **단계 4: Release Manager 에이전트 작성** (검토 대상)
- 파일: `.github/agents/release-manager.agent.md`
- 내용:
  - 버전 관리 규칙 (semver)
  - 릴리스 체크리스트
  - 자동 변경 로그 생성

**체크포인트:** 배포 프로세스가 명확하고 자동화 가능한가?

---

#### **단계 5: Doc Engineer 에이전트 작성** (검토 대상)
- 파일: `.github/agents/doc-engineer.agent.md`
- 내용:
  - 문서 구조 표준
  - 예제 코드 작성 규칙
  - API 문서 생성 기준

**체크포인트:** 새로운 기능이 추가될 때 문서도 함께 생성되는 프로세스가 있는가?

---

#### **단계 6: QA 에이전트 작성** (검토 대상)
- 파일: `.github/agents/qa.agent.md`
- 내용:
  - 테스트 계획 수립 방식
  - QA 스코어링 메트릭 정의
  - 버그 보고 템플릿

**체크포인트:** QA가 독립적으로 품질을 평가하고 개선 권고를 할 수 있는가?

---

## 🎓 레이어 2: 공유 스킬 (`.github/skills/`)

### 개념 설명
**스킬**이란?
- 여러 에이전트가 공통으로 사용하는 **재사용 가능한 작업 패턴**
- 각 스킬은 폴더 + SKILL.md 파일로 정의되고, 특정 문제 해결 방식을 인코딩
- 예: `/spec` 스킬 = 사양 문서 작성 워크플로우

### 구현 구조

```
.github/skills/
├── office-hours/
│   └── SKILL.md         # 제품 프레이밍과 좁은 wedge 선택
├── autoplan/
│   └── SKILL.md         # 실행 가능한 sprint chain과 review/QA gate
├── spec/
│   └── SKILL.md         # 사양 문서 작성 워크플로우
├── ship/
│   └── SKILL.md         # 기능 출시 체크리스트
├── qa/
│   └── SKILL.md         # QA 계획 및 테스트 자동화 (Playwright MCP 포함)
├── review/
│   └── SKILL.md         # diff 기반 위험/테스트 공백 리뷰
├── investigate/
│   └── SKILL.md         # 재현→최소화→가설→검증 조사
└── memory/
    └── SKILL.md         # 에이전트 메모리 관리 (학습 내용 저장)
```

### 각 스킬 정의

| 스킬 | 목적 | 입력 | 출력 | 사용자 |
|-----|------|------|------|--------|
| **/office-hours** | 모호한 아이디어를 좁은 문제로 정리 | 아이디어 | 문제 프레이밍 + 성공 신호 | CEO, Designer |
| **/autoplan** | 실행 가능한 sprint chain 생성 | 승인된 아이디어/사양 | gate 기반 실행 계획 | 모든 에이전트 |
| **/spec** | 기능을 사양 문서로 변환 | 기능 아이디어 | PRD + API 설계 | Designer, CEO |
| **/ship** | 기능을 출시 가능하게 | 완성된 코드 | 체크리스트 + 릴리스 노트 | Eng Manager, Release Manager |
| **/qa** | 품질 보증 계획 수립 | 사양 문서 | 테스트 계획 + 성능 기준 | QA, Designer |
| **/review** | diff 기반 위험 검토 | 변경 diff | 위험/테스트 공백 리포트 | Eng Manager |
| **/investigate** | 원인 조사 | 증상/재현 명령 | 가설 + 검증 계획 | Eng Manager, QA |
| **/memory** | 에이전트 학습 저장 | 작업 결과·교훈 | 조직 지식베이스 업데이트 | 모든 에이전트 |

### 구현 단계

#### **단계 1: /spec 스킬 작성** (검토 대상)
- 파일: `.github/skills/spec/SKILL.md`
- 내용:
  - 입력: 기능 설명 (자유 형식)
  - 프로세스: 질문 → 명확화 → 사양 작성
  - 출력: PRD 템플릿 + API 설계
- 예시: CEO가 "/spec 사용자 인증 기능" → Designer가 자세한 사양 작성

**체크포인트:** /spec 스킬을 사용하면 모호한 요구사항이 구체적인 설계로 변환되는가?

---

#### **단계 2: /ship 스킬 작성** (검토 대상)
- 파일: `.github/skills/ship/SKILL.md`
- 내용:
  - 입력: 완성된 기능 (코드 + 테스트)
  - 체크리스트: 코드 검토, 문서, 테스트 커버리지
  - 출력: 릴리스 준비 보고서
- 예시: Eng Manager가 "/ship" → 출시 준비도 자동 평가

**체크포인트:** /ship을 실행하면 모든 출시 조건이 충족되는가?

---

#### **단계 3: /qa 스킬 작성** (검토 대상)
- 파일: `.github/skills/qa/SKILL.md`
- 내용:
  - 입력: 사양 문서
  - 프로세스: 테스트 케이스 생성 → 성능 기준 설정 → 자동화 테스트 작성
  - 브라우저 검증: Playwright MCP (`@playwright/mcp`)를 통해 UI 테스트 자동 실행
  - 출력: 테스트 계획 + QA 스코어링 기준 (0-100)
- 예시: QA가 "/qa" → 자동으로 테스트 계획 수립 + 브라우저 테스트 케이스 생성

**체크포인트:** /qa를 사용하면 품질 기준이 데이터 기반으로 설정되는가?

---

#### **단계 4: /memory 스킬 작성** (검토 대상)
- 파일: `.github/skills/memory/SKILL.md`
- 내용:
  - 입력: 작업 결과·교훈·패턴
  - 저장소: `.github/memory/` 폴더 (마크다운)
  - 출력: 조직 지식베이스 업데이트
- 예시: 어떤 문제 해결법 → 나중에 비슷한 상황에서 재사용

**체크포인트:** 에이전트들이 이전 작업에서 배운 내용을 활용하는가?

---

## 🌐 레이어 2.5: 브라우저 작업 레이어 (선택적)

### 개념 설명
**브라우저 작업**이란?
- E2E 테스트, 스크린샷 캡처, 사용자 상호작용 시뮬레이션 등
- 직접 브라우저 자동화 코드를 작성하지 않음
- **Microsoft Playwright MCP** (`@playwright/mcp`)를 통해 통합

### 구현 구조

```
.vscode/
└── mcp.json                    # MCP 서버 설정 파일
```

### 구성 내용

**파일: `.vscode/mcp.json`**
```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

### 사용 방식

- **QA 에이전트**: `/qa` 스킬 실행 시 Playwright MCP를 통해 자동으로 브라우저 테스트 케이스 생성
- **Designer**: 프로토타입 검증 시 Playwright로 실시간 UI 테스트
- **직접 작성 없음**: 에이전트가 자연어로 "로그인 페이지 테스트하기" → Playwright MCP가 자동 코드 생성 + 실행

### 구현 단계

#### **단계 1: .vscode/mcp.json 작성** (검토 대상)
- 파일: `.vscode/mcp.json`
- 내용: Playwright MCP 서버 연결 설정
- 체크포인트: 에이전트에서 "@playwright/mcp" 명령이 인식되는가?

---

## 🛠️ 레이어 3: 자동화 스크립트 (`scripts/`)

### 개념 설명
**자동화 스크립트**란?
- 개발 워크플로우를 효율화하는 실제 실행 가능한 스크립트
- Git 워크트리를 이용한 병렬 작업 관리
- QA 점수 자동 계산

### 구현 구조

```
scripts/
├── setup-worktree.sh    # Git 워크트리 초기화
├── parallel-work.sh     # 여러 기능을 병렬로 개발
├── office-hours-workflow.sh
├── autoplan-workflow.sh
├── spec-workflow.sh
├── qa-score.sh          # QA 점수 계산 (0-100 스케일, docs/code profile 분리)
├── qa-workflow.sh
├── review-workflow.sh
├── investigate-workflow.sh
├── ship-workflow.sh
├── memory-workflow.sh
├── validate-ghcp.sh
└── merge-worktree.sh    # 워크트리 병합 및 정리

.gitignore (추가)
worktrees/              # 워크트리는 모두 로컬 전용 (커밋 제외)
```

### 각 스크립트 역할

| 스크립트 | 목적 | 사용 시기 | 입력 | 출력 |
|---------|------|---------|------|------|
| **setup-worktree.sh** | 독립적인 작업 브랜치 생성 | 새 기능 시작 시 | 기능명 | `worktrees/feature-name/` (`.gitignore`에 등록) |
| **parallel-work.sh** | 여러 기능을 동시 작업 | 팀 협업 시 | 기능 목록 | 각각의 워크트리 생성 (`.gitignore` 적용) |
| **office-hours-workflow.sh** | 제품 프레이밍 dry-run | 구현 전 | idea/audience | 문제·사용자·성공 신호 |
| **autoplan-workflow.sh** | sprint chain dry-run | 사양 승인 후 | idea/target/mode | review/QA gate 포함 계획 |
| **spec-workflow.sh** | 사양 품질 게이트 | 이슈 생성 전 | title/body/label | 필수 섹션·중복·secret preview |
| **qa-score.sh** | 품질 지표 계산 (0-100 점수) | PR 제출 시 | docs/code 경로 | profile별 점수 + 개선 항목 |
| **qa-workflow.sh** | QA 리포트 생성 | 릴리스 전 | path 또는 URL | 테스트 계획 + 출시 판단 |
| **review-workflow.sh** | diff 기반 위험 검토 | QA 전 | base/target | 위험 패턴 + 테스트 공백 |
| **investigate-workflow.sh** | 원인 조사 dry-run | 버그/실패 시 | symptom/target | 재현·가설·검증 계획 |
| **ship-workflow.sh** | ship preview | 머지 전 | PR/issue | merge/close preview + 안전 게이트 |
| **memory-workflow.sh** | 조직 메모리 preview/apply | 학습 저장 시 | type/title/note | `.github/memory/` 업데이트 preview |
| **validate-ghcp.sh** | 구조 검증 | CI/로컬 smoke | 없음 | Copilot 변환 구조 CHECK OK |
| **merge-worktree.sh** | 완성된 워크트리 메인에 병합 | 기능 완료 시 | 워크트리명 | 정리된 메인 브랜치 |

### 구현 단계

#### **단계 1: setup-worktree.sh 작성** (검토 대상)
- 파일: `scripts/setup-worktree.sh`
- 기능:
  ```bash
  ./scripts/setup-worktree.sh feature-auth
  # 결과: worktrees/feature-auth/ 생성 (독립적인 작업 폴더, .gitignore 적용)
  ```
- 내용:
  - 입력 검증 (기능명 확인)
  - `worktrees/` 디렉토리 생성 (`.gitignore`에 이미 등록됨)
  - Git 워크트리 생성
  - 초기 브랜치 설정
  - 안내 메시지 출력

**체크포인트:** 스크립트 실행 후 완전히 독립적인 작업 폴더가 생성되는가?

---

#### **단계 2: parallel-work.sh 작성** (검토 대상)
- 파일: `scripts/parallel-work.sh`
- 기능:
  ```bash
  ./scripts/parallel-work.sh feature-auth feature-payment feature-logging
  # 결과: 3개의 독립적인 워크트리 동시 생성
  ```
- 내용:
  - 여러 기능명을 입력받기
  - setup-worktree.sh 반복 호출
  - 병렬 작업 상태 대시보드 출력

**체크포인트:** 여러 기능을 동시에 개발할 수 있도록 워크트리가 생성되는가?

---

#### **단계 3: qa-score.sh 작성** (검토 대상)
- 파일: `scripts/qa-score.sh`
- 기능:
  ```bash
  ./scripts/qa-score.sh src/auth/
  # 출력: QA Score: 82/100
  #      - Test Coverage: 85% (25점)
  #      - Lint Issues: 2 (10점 차감)
  #      - Complexity: Normal (20점)
  #      - Type Safety: 90% (20점)
  #      - Documentation: 85% (15점)
  #      - Performance: Good (10점)
  ```
- 내용:
  - target profile 구분: `docs`, `code`, `hybrid`, `unknown`
  - code profile: 테스트 커버리지, 린팅, 복잡도, 타입 안정성, 문서화, 빌드/성능 신호
  - docs profile: 문서 구조, 예제, 링크/참조, 최신성, workflow coverage
  - hybrid profile: code gate를 기본으로 실행하고 문서 최신성도 별도 검토
  - **최종 점수 계산 (0-100 스케일)** ← QA 에이전트, /qa 스킬과 동일한 스케일
  - 개선 권고사항 제시

**체크포인트:** QA 점수가 객관적인 기준으로 계산되고, 개선 항목이 명확한가?

---

#### **단계 4: merge-worktree.sh 작성** (검토 대상)
- 파일: `scripts/merge-worktree.sh`
- 기능:
  ```bash
  ./scripts/merge-worktree.sh worktrees/feature-auth
  # 결과: feature-auth 병합 완료 → 워크트리 정리
  ```
- 내용:
  - 워크트리 상태 확인
  - 메인 브랜치로 병합
  - 충돌 감지 및 안내
  - 워크트리 폴더 정리

**체크포인트:** 완성된 기능이 안전하게 메인에 병합되는가?

---

### QA 점수 스케일 통일

**모든 레이어에서 동일한 0-100 점수 사용:**
- **QA 에이전트**: 품질 점수 기준 정의 (0-100)
- **/qa 스킬**: 테스트 계획 수립 시 점수 기준 제시 (0-100)
- **qa-score.sh 스크립트**: 자동 점수 계산 (0-100)

**점수 해석:**
- 90-100: 우수 (출시 가능)
- 80-89: 양호 (경고 조건 있음, 개선 권고)
- 70-79: 미흡 (출시 전 개선 필수)
- 60-69: 부족 (리뷰 필요)
- 0-59: 불충분 (재작업)

---

## 📅 구현 우선순위 & 현재 로드맵

### Phase 1: 기초 구조
✅ 모든 에이전트 기본 프레임 작성 (6개)
✅ 에이전트 간 협력 규칙 정의

### Phase 2: 스킬 시스템
✅ /office-hours, /autoplan, /spec, /ship, /qa, /review, /investigate 스킬 작성 및 테스트
✅ /memory 시스템 구축

### Phase 3: 자동화 스크립트
✅ 워크트리 관리 스크립트 작성
✅ dry-run workflow 스크립트 작성
✅ docs/code profile 기반 QA 스코어링 로직 작성

### Phase 4: 통합 테스트와 CI
✅ `validate-ghcp.sh` 구조 검증
✅ GitHub Actions smoke validation
✅ shell script syntax validation

### Phase 5: 유지보수 강화
✅ `/autoplan` review/QA gate 세분화
✅ `.github/memory/` seed 파일 추가
🔁 PLAN/README와 실제 구현 상태 동기화 유지
🔁 원본 gstack에서 가져올 수 있는 review depth를 Copilot 환경에 맞게 점진 반영

---

## 💡 각 단계 검토 체크리스트

### 에이전트 검토 시 확인 사항
- [ ] 에이전트의 역할이 명확한가? (1-2문장으로 설명 가능)
- [ ] 도구 접근 범위가 합리적인가? (권한 제한 적절)
- [ ] 다른 에이전트와의 협력 지점이 있는가?
- [ ] 실제 작업 예시가 있는가?

### 스킬 검토 시 확인 사항
- [ ] 입력과 출력이 명확한가?
- [ ] 단계별 프로세스가 자동화 가능한가?
- [ ] 다양한 에이전트가 사용할 수 있는가?
- [ ] 결과가 일관성 있는가?

### 스크립트 검토 시 확인 사항
- [ ] 에러 처리가 있는가?
- [ ] 사용 예시가 명확한가?
- [ ] 실제 실행 가능한가? (테스트됨)
- [ ] 문서가 충분한가?

---

## 🚀 다음 단계

1. **Review depth 강화**: `/autoplan` 결과가 CEO, Design, Engineering, DevEx, QA, Release 관점을 evidence gate로 남기는지 확인
2. **QA profile 검증**: 문서형 repo와 코드형 repo에서 `qa-score.sh` 점수 해석이 서로 분리되는지 확인
3. **Memory 운영 시작**: `.github/memory/patterns.md`, `decisions.md`, `backlog.md` seed 구조를 기준으로 durable memory만 저장
4. **문서 동기화**: workflow나 스킬이 바뀔 때 PLAN/README의 상태와 예시를 함께 갱신

---

## 📚 참고 자료

- [GitHub Copilot 커스텀 에이전트/스킬 문서](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Git 워크트리 가이드](https://git-scm.com/docs/git-worktree)
- [QA 메트릭 정의](https://en.wikipedia.org/wiki/Software_quality)

---

**작성일**: 2026-06-19  
**마지막 업데이트**: 2026-06-29  
**상태**: ✅ 기본 구현 완료, 유지보수 강화 중  
**다음 검토**: review depth, QA profile, memory seed 운영 검증
