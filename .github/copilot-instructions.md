# GitHub Copilot Instructions for gstack-ghcp

## 🎯 프로젝트 목적

**gstack-ghcp**는 gstack(GitHub Stack)을 GitHub Copilot 환경에 최적화한 변환본입니다.

### 핵심 특징

- **브라우저 하니스 제외**: gstack의 자체(bespoke) 브라우저 하니스는 재구현하지 않습니다.
- **Playwright MCP 대체**: 브라우저 기능(E2E 테스트, UI 검증, 스크린샷 등)은 **Microsoft Playwright MCP**로 대체하고 통합합니다.
- **역할 기반 에이전트**: CEO, Designer, Eng Manager, Release Manager, Doc Engineer, QA 등 6가지 역할 에이전트가 협력합니다.
- **공유 스킬 시스템**: `/office-hours`, `/autoplan`, `/spec`, `/qa`, `/review`, `/investigate`, `/ship`, `/memory` 8가지 스킬로 반복 가능한 작업 패턴을 정의합니다.
- **자동화 스크립트**: Git 워크트리 병렬화, 제품 프레이밍, 자동 계획, QA 스코어링(0-100), spec/review/investigate/ship/memory dry-run 검증.
- **범위 제한**: 원본 gstack의 persistent Chromium daemon, `$B` CLI, telemetry/update/checkpoint/gbrain 계층은 재구현하지 않습니다.

---

## 📂 폴더 구조

```
.github/
├── agents/                   # 역할 에이전트 정의
│   ├── ceo.agent.md         # 전략·마일스톤 결정
│   ├── designer.agent.md    # UI/UX·아키텍처 설계
│   ├── eng-manager.agent.md # 코드 품질·PR 리뷰
│   ├── release-manager.agent.md  # 배포·버전 관리
│   ├── doc-engineer.agent.md     # 문서 작성·예제
│   └── qa.agent.md          # 테스트·품질 평가 (0-100 점수)
├── skills/                  # 공유 스킬 (에이전트가 공통 사용)
│   ├── office-hours/
│   │   └── SKILL.md         # 제품 프레이밍과 좁은 wedge 선택
│   ├── autoplan/
│   │   └── SKILL.md         # Think→Plan→Build→Review→Test→Ship→Reflect 계획
│   ├── spec/
│   │   └── SKILL.md         # 사양 문서 작성 워크플로우
│   ├── qa/
│   │   └── SKILL.md         # QA 계획 + 테스트 자동화 (Playwright MCP 포함)
│   ├── review/
│   │   └── SKILL.md         # diff 기반 위험/테스트 공백 리뷰
│   ├── investigate/
│   │   └── SKILL.md         # 재현→최소화→가설→계측 원인 조사
│   ├── ship/
│   │   └── SKILL.md         # 기능 출시 체크리스트
│   └── memory/
│       └── SKILL.md         # 에이전트 메모리·학습 저장
├── memory/                  # 조직 지식베이스 (마크다운)
│   ├── patterns.md          # 반복되는 문제 해결 패턴
│   ├── decisions.md         # 아키텍처 결정 기록
│   └── ...
└── copilot-instructions.md  # 이 파일 (GitHub Copilot용 지침)

scripts/                      # 자동화 스크립트
├── setup-worktree.sh        # Git 워크트리 생성
├── parallel-work.sh         # 여러 기능 병렬 개발
├── office-hours-workflow.sh # 제품 프레이밍 리포트
├── autoplan-workflow.sh     # sprint chain dry-run 계획
├── qa-score.sh              # QA 점수 계산 (0-100)
├── qa-workflow.sh           # QA 리포트와 출시 판단
├── spec-workflow.sh         # 사양 품질 게이트와 이슈 생성 dry-run
├── review-workflow.sh       # diff 기반 리뷰 리포트
├── investigate-workflow.sh  # 원인 조사 리포트
├── ship-workflow.sh         # PR merge/issue close dry-run
├── memory-workflow.sh       # memory 저장/검색/prune dry-run
├── validate-ghcp.sh         # Copilot 변환본 구조 검증
└── merge-worktree.sh        # 워크트리 병합 및 정리

.github/workflows/
└── validate.yml             # GitHub Actions smoke validation

.vscode/
└── mcp.json                 # MCP 서버 설정 (Playwright 연결)

docs/
├── PLAN.md                  # 구현 계획 (레이어별 단계)
└── ...

.gitignore
worktrees/                   # 로컬 전용 (커밋 제외)
```

---

## 🔍 코드 구조 탐색 규칙 (CodeGraph MCP)

심볼·호출관계·영향범위 같은 구조적 질문은 grep 반복 루프 대신 CodeGraph MCP tool로 직접 답합니다. 탐색은 `codegraph_explore`로 시작하고 `codegraph_search`, `codegraph_callers`, `codegraph_callees`, `codegraph_impact`, `codegraph_status`를 사용합니다. tool 결과는 이미 읽은 소스로 신뢰하고 grep으로 재검증하지 않으며, 코드 편집 후에는 `codegraph_status`로 staleness 배너를 확인합니다. `.codegraph/`가 없으면 `codegraph init -i`를 제안합니다.

---

## 🌐 브라우저 작업 규칙

### 직접 구현하지 않기

브라우저 자동화(E2E 테스트, UI 검증, 스크린샷, 사용자 상호작용 시뮬레이션 등)는 **직접 코드를 작성하지 않습니다.**

### Playwright MCP 사용

모든 브라우저 작업은 `.vscode/mcp.json`에 등록된 **Playwright MCP**를 통해 처리합니다:

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

### 사용 예시

1. **QA 에이전트**: `/qa` 스킬 실행
   - 입력: 사양 문서
   - Playwright MCP: 자동으로 브라우저 테스트 케이스 생성 + 실행
   - 출력: 테스트 결과 + QA 점수 (0-100)

2. **Designer**: 프로토타입 검증
   - 자연어 요청: "로그인 페이지 검증해줄래?"
   - Playwright MCP: 자동 코드 생성 → UI 테스트 실행
   - 결과: 스크린샷 + 검증 보고

3. **통합 워크플로우**:
   ```
  아이디어 프레이밍 (/office-hours)
  ↓
  sprint chain 생성 (/autoplan)
  ↓
   사양 문서 작성 (Designer, /spec)
   ↓
   코드 구현 (엔지니어)
   ↓
  /review 스킬 실행 (Eng Manager)
  ↓
  버그가 있으면 /investigate 스킬 실행
  ↓
   /qa 스킬 실행 (QA)
   ↓
   Playwright MCP가 자동으로 테스트 케이스 생성 + 실행
   ↓
   QA 점수 (0-100) + 결과 보고
   ```

---

## 👤 개발자 지침 (초급자용)

### 핵심 원칙

**한 번에 한 단계씩, 작게 쪼개서, 매 단계 후 검토하기**

### 작업 방식

1. **계획 읽기**: `docs/PLAN.md`에서 전체 구조 이해
2. **단계 선택**: Phase 1부터 시작 (에이전트 기본 프레임)
3. **작은 파일 작성**: 하나의 `.agent.md` 또는 `SKILL.md` 작성 (200-300줄)
4. **즉시 검토**: 작성 후 멈추고 검토 받기
5. **피드백 반영**: 수정 사항 적용
6. **다음 단계**: 다음 에이전트/스킬로 진행

### 검토 체크리스트

#### 에이전트 검토 시
- [ ] 역할이 명확한가? (1-2문장 설명 가능)
- [ ] 도구 접근 범위가 합리적인가? (권한 제한 적절)
- [ ] 다른 에이전트와의 협력 지점이 있는가?
- [ ] 실제 작업 예시가 있는가?

#### 스킬 검토 시
- [ ] 입력과 출력이 명확한가?
- [ ] 단계별 프로세스가 자동화 가능한가?
- [ ] 다양한 에이전트가 사용할 수 있는가?
- [ ] 결과가 일관성 있는가?

#### 스크립트 검토 시
- [ ] 에러 처리가 있는가?
- [ ] 사용 예시가 명확한가?
- [ ] 실제 실행 가능한가? (테스트됨)
- [ ] 문서가 충분한가?

### 질문 및 문제 해결

작업 중 막히면:
- **"이 부분이 뭐하는 건가요?"** → `docs/PLAN.md`에서 해당 섹션 확인
- **"다음 단계가 뭐예요?"** → 현재 Phase의 마지막 단계 완료 후 다음 Phase로
- **"이렇게 짜도 되나요?"** → 체크리스트로 검증 후 검토 요청

---

## 📅 구현 순서 (Phase별)

### Phase 1: 역할 에이전트 기초 (1-2주)
1. CEO 에이전트 작성 → 검토
2. Designer 에이전트 작성 → 검토
3. Eng Manager 에이전트 작성 → 검토
4. Release Manager 에이전트 작성 → 검토
5. Doc Engineer 에이전트 작성 → 검토
6. QA 에이전트 작성 → 검토

### Phase 2: 스킬 시스템 (2-3주)
1. `/office-hours` 스킬 작성 → 검토
2. `/autoplan` 스킬 작성 → 검토
3. `/spec` 스킬 작성 → 검토
4. `/qa` 스킬 작성 (Playwright MCP 포함) → 검토
5. `/review` 스킬 작성 → 검토
6. `/investigate` 스킬 작성 → 검토
7. `/ship` 스킬 작성 → 검토
8. `/memory` 스킬 작성 → 검토

### Phase 3: Playwright MCP 연결 (1주)
1. `.vscode/mcp.json` 작성 및 테스트 → 검토

### Phase 4: 자동화 스크립트 (1-2주)
1. `setup-worktree.sh` 작성 → 검토
2. `parallel-work.sh` 작성 → 검토
3. `office-hours-workflow.sh` 작성 → 검토
4. `autoplan-workflow.sh` 작성 → 검토
5. `qa-score.sh` 작성 → 검토
6. `qa-workflow.sh` 작성 → 검토
7. `spec-workflow.sh` 작성 → 검토
8. `review-workflow.sh` 작성 → 검토
9. `investigate-workflow.sh` 작성 → 검토
10. `ship-workflow.sh` 작성 → 검토
11. `memory-workflow.sh` 작성 → 검토
12. `validate-ghcp.sh` 작성 → 검토
13. `merge-worktree.sh` 작성 → 검토

### Phase 5: 통합 테스트 (1주)
1. 실제 워크플로우 시뮬레이션
2. 에이전트-스킬-Playwright 통합 검증
3. 문서 정리 및 튜토리얼 작성

---

## 🚀 첫 시작

**다음 단계:**
1. `docs/PLAN.md`를 읽고 전체 구조 이해
2. `.github/agents/ceo.agent.md` 파일 생성 준비
3. 검토 받으며 한 단계씩 진행

**연락 방법:**
- 각 단계 완료 후 검토 요청 (멈춤)
- 막히는 부분이 있으면 질문
- 수정 사항 피드백 받기

---

**작성일**: 2026-06-19  
**상태**: 📋 초급자 친화적 설정 완료  
**다음**: Phase 1 - CEO 에이전트 작성 시작
