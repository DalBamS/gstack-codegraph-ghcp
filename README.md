# gstack-ghcp

gstack-ghcp는 gstack(GitHub Stack)의 역할 기반 에이전트 운영 방식을 GitHub Copilot 환경에 맞게 옮긴 프로젝트입니다. 브라우저 자동화 하니스는 직접 구현하지 않고, VS Code의 MCP 설정을 통해 Microsoft Playwright MCP를 연결합니다.

이 저장소는 원본 `garrytan/gstack`의 전체 기능을 복제한 프로젝트가 아니라, GitHub Copilot에서 반복 실행하기 좋은 핵심 워크플로우를 추출한 실행형 subset입니다. 원본 gstack의 persistent Chromium daemon, browser CLI, telemetry/update/checkpoint/gbrain 계층은 의도적으로 포함하지 않습니다.

이 저장소는 다음 세 가지를 제공합니다.

- 역할 에이전트: 전략, 설계, 엔지니어링, 릴리스, 문서, QA 역할을 나눈 `.agent.md` 파일
- 공유 스킬: `/office-hours`, `/autoplan`, `/spec`, `/qa`, `/review`, `/investigate`, `/ship`, `/memory` 작업 패턴
- 자동화 스크립트: Git worktree 병렬 작업, 제품 프레이밍, 자동 계획, QA 점수 계산

## 설치 방법

### 1. 저장소 준비

```bash
git clone <repository-url>
cd gstack-ghcp
```

필요한 도구:

- Git
- GitHub CLI (`gh`)
- Node.js와 `npx` (Playwright MCP 실행용)
- Bash 실행 환경 (Windows에서는 Git Bash 또는 WSL 권장)

### 2. GitHub CLI 로그인

`/spec`와 `/ship` 스킬은 GitHub 이슈와 PR 작업에 `gh` CLI를 사용합니다.

```bash
gh auth login
gh auth status
```

명령을 실행하기 전에는 스킬이 실행할 `gh` 명령을 먼저 보여주고 사용자 확인을 받는 흐름을 따릅니다.

### 3. Playwright MCP 설정

브라우저 검증은 `.vscode/mcp.json`에 등록된 Playwright MCP 서버를 사용합니다.

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

중요: 최상위 키는 반드시 `servers`입니다. `mcpServers`를 사용하면 이 프로젝트의 지침과 맞지 않습니다.

### 4. CodeGraph MCP 설정

구조적 코드 탐색은 `.vscode/mcp.json`에 등록된 CodeGraph MCP 서버를 사용합니다. CodeGraph CLI는 전역으로 설치한 뒤 프로젝트 루트에서 `codegraph init -i`로 인덱스를 만듭니다.

```json
{
	"servers": {
		"playwright": {
			"command": "npx",
			"args": ["@playwright/mcp@latest"]
		},
		"codegraph": { "command": "codegraph", "args": ["serve", "--mcp"] }
	}
}
```

기존 `playwright` 항목은 그대로 두고 `codegraph` 항목만 추가합니다. 인덱스 디렉터리 `.codegraph/`는 로컬 산출물이므로 커밋하지 않습니다.

> WSL 사용 시 주의: 프로젝트를 `/mnt` 아래가 아닌 WSL 로컬 디스크에 두세요. `/mnt`는 WAL 미지원으로 읽기가 쓰기에 블록될 수 있습니다.


## 역할 에이전트

역할 에이전트는 `.github/agents/`에 있습니다.

| 에이전트 | 파일 | 역할 |
| --- | --- | --- |
| CEO Agent | `.github/agents/ceo.agent.md` | 전략 수립, 기능 우선순위, 마일스톤 관리 |
| Designer Agent | `.github/agents/designer.agent.md` | UI/UX 설계, 컴포넌트 구조화, API 스펙 정의 |
| Eng Manager Agent | `.github/agents/eng-manager.agent.md` | 코드 품질 관리, PR 리뷰, 성능 최적화 |
| Release Manager Agent | `.github/agents/release-manager.agent.md` | 배포 파이프라인, 버전 관리, 변경로그 관리 |
| Doc Engineer Agent | `.github/agents/doc-engineer.agent.md` | 문서 작성, 예제 코드, API 문서화 |
| QA Agent | `.github/agents/qa.agent.md` | 테스트 계획, 버그 감지, 0-100 품질 점수 계산 |

각 에이전트 파일은 `---` frontmatter 안에 `name`과 `description`을 포함합니다.

## 공유 스킬

스킬은 `.github/skills/<skill-name>/SKILL.md` 구조를 사용합니다. `name` frontmatter에는 `myorg/` 같은 네임스페이스 접두사를 붙이지 않습니다.

| 스킬 | 파일 | 사용 목적 |
| --- | --- | --- |
| `/office-hours` | `.github/skills/office-hours/SKILL.md` | 모호한 제품 아이디어를 문제, 사용자, 좁은 wedge로 재정의 |
| `/autoplan` | `.github/skills/autoplan/SKILL.md` | Think → Plan → Build → Review → Test → Ship → Reflect 실행 계획 생성 |
| `/spec` | `.github/skills/spec/SKILL.md` | 모호한 요청을 5단계로 사양화하고 GitHub 이슈 생성 |
| `/ship` | `.github/skills/ship/SKILL.md` | 머지 전 체크리스트, PR 머지, 연결 이슈 종료 |
| `/qa` | `.github/skills/qa/SKILL.md` | 테스트 계획, Playwright MCP 브라우저 검증, QA 점수 계산 |
| `/review` | `.github/skills/review/SKILL.md` | diff 기반 위험 패턴, 테스트 공백, 출시 전 리뷰 |
| `/investigate` | `.github/skills/investigate/SKILL.md` | 재현, 최소화, 가설, 계측, 회귀 검증 중심 원인 조사 |
| `/codegraph` | `.github/skills/codegraph/SKILL.md` | CodeGraph MCP로 심볼·호출관계·영향범위를 grep 전에 직접 탐색 |
| `/memory` | `.github/skills/memory/SKILL.md` | 결정, 패턴, 남은 작업을 `.github/memory/`에 저장하고 다음 세션에서 불러오기 |

## 스크립트 사용법

스크립트는 `scripts/`에 있으며 모두 실행 권한이 설정되어 있습니다.

### QA 점수 계산

```bash
./scripts/qa-score.sh .
./scripts/qa-score.sh src/auth
```

출력은 PLAN.md와 같은 0-100 스케일을 사용하며, target을 `docs`, `code`, `hybrid` profile로 구분합니다. 문서형 repo는 소스 파일이 없다는 이유로 code 점수를 받지 않고 문서 구조, 예제, 링크, 최신성, workflow coverage로 평가합니다.

- 90-100: 우수, 출시 가능
- 80-89: 양호, 경고 조건 있음
- 70-79: 미흡, 출시 전 개선 필수
- 60-69: 부족, 리뷰 필요
- 0-59: 불충분, 재작업

테스트, 린트, 빌드 도구가 아직 없어도 스크립트는 실패하지 않고 profile에 맞는 가능한 신호로 점수와 개선 항목을 출력합니다.

### QA 워크플로우 리포트

```bash
./scripts/qa-workflow.sh .
./scripts/qa-workflow.sh . --report /tmp/gstack-ghcp-qa.md
./scripts/qa-workflow.sh https://example.com
```

코드 경로를 입력하면 `qa-score.sh` 결과를 테스트 계획과 출시 판단으로 묶어 출력합니다. URL을 입력하면 Playwright MCP로 실행해야 할 브라우저 검증 계획을 출력합니다.

### Office Hours 프레이밍

```bash
./scripts/office-hours-workflow.sh --idea "daily briefing app"
./scripts/office-hours-workflow.sh --idea "email login" --audience "first-time users" --mode reduction
```

이 명령은 구현 전에 사용자 고통, 첫 사용자군, 10-star 결과, 제외 범위, 성공 신호를 확인하는 질문과 downstream 명령을 출력합니다. 파일, 브랜치, GitHub issue, 브라우저 세션은 만들지 않습니다.

### Autoplan sprint chain

```bash
./scripts/autoplan-workflow.sh --idea "email login" --target .
./scripts/autoplan-workflow.sh --idea "dashboard performance" --target src/dashboard --mode thorough
```

이 명령은 Think → Plan → Build → Review → Test → Ship → Reflect 순서의 실행 계획, CEO/Design/Engineering/DevEx 관점의 review gate, QA profile gate, risk register, 최소 완료 기준을 출력합니다. 실제 worktree 생성이나 GitHub mutation은 실행하지 않습니다.

### Spec 품질 게이트

```bash
./scripts/spec-workflow.sh --title "Email login" --body docs/auth-spec.md --label feature
```

이 명령은 GitHub 이슈를 만들기 전에 사양 문서의 필수 섹션, 민감 정보 패턴, 중복 이슈 검색 명령, `gh issue create` 미리보기를 확인합니다. 실제 이슈 생성은 사용자 승인 후 preview된 명령으로 실행합니다.

### Ship dry-run

```bash
./scripts/ship-workflow.sh --pr 123 --issue 42
./scripts/ship-workflow.sh --pr 123 --issue 42 --run-checks
```

이 명령은 PR 상태와 체크 확인 명령, 안전 게이트, `gh pr merge`, `gh issue close` preview를 출력합니다. 실제 merge와 issue close는 사용자 승인 후에만 실행합니다.

### Review workflow

```bash
./scripts/review-workflow.sh --base origin/main --target HEAD
./scripts/review-workflow.sh --base HEAD --target HEAD --report /tmp/gstack-review.md
./scripts/review-workflow.sh --base origin/main --target HEAD --pr 123 --issue 42
```

이 명령은 diff 파일 목록, PR/issue metadata preview, whitespace check, secret/shell/SQL/browser 위험 패턴, 테스트 공백을 확인합니다. 위험 패턴은 자동 수정하지 않고 리뷰 단서로 출력합니다. `--run-gh`를 붙인 경우에만 `gh pr view`와 `gh issue view` 읽기 전용 조회를 실행합니다.

### Investigate workflow

```bash
./scripts/investigate-workflow.sh --symptom "validate-ghcp fails" --target .
./scripts/investigate-workflow.sh --symptom "login returns 500" --target src/auth --command "npm test -- auth"
```

이 명령은 증상을 재현, 최소화, 가설, 계측, 수정, 회귀 검증 단계로 정리합니다. 재현 명령은 기본 preview이며 사용자 승인 후 `--run-command`로만 실행합니다.

### Memory dry-run

```bash
./scripts/memory-workflow.sh save --type pattern --title "gh approval" --note "Show gh mutation commands before running."
./scripts/memory-workflow.sh search --query "Playwright"
./scripts/memory-workflow.sh prune --type backlog
```

저장은 기본적으로 preview만 출력합니다. 실제 `.github/memory/` 파일을 수정하려면 사용자 승인 후 `--apply`를 붙입니다. 기본 seed 파일은 `patterns.md`, `decisions.md`, `backlog.md`입니다.

### Copilot 변환본 구조 검증

```bash
./scripts/validate-ghcp.sh
```

이 명령은 agents/skills frontmatter, Playwright MCP 설정, script 실행 권한, `worktrees/` ignore 규칙을 확인합니다. 성공하면 `CHECK OK`를 출력합니다.

### 단일 worktree 만들기

```bash
./scripts/setup-worktree.sh feature-auth
```

결과:

- `worktrees/feature-auth/` 폴더 생성
- `feature-auth` 브랜치 생성
- 새 worktree에서 해당 브랜치 체크아웃

### 여러 worktree 만들기

```bash
./scripts/parallel-work.sh feature-auth feature-payments feature-docs
```

각 기능을 독립적인 `worktrees/` 하위 폴더에서 병렬로 작업할 수 있습니다.

### worktree 병합하기

```bash
./scripts/merge-worktree.sh feature-auth
```

기본 대상 브랜치는 `main`입니다. 다른 브랜치로 병합하려면 다음처럼 실행합니다.

```bash
BASE_BRANCH=develop ./scripts/merge-worktree.sh feature-auth
```

`worktrees/` 폴더는 로컬 작업 공간이므로 `.gitignore`에 등록되어 커밋되지 않습니다.

## 초급자용 빠른 시작

1. 저장소를 열고 `docs/PLAN.md`를 먼저 읽습니다.
2. 새 기능 아이디어가 있으면 `/office-hours`로 문제를 재정의하고 `/autoplan`으로 sprint chain을 만듭니다.
3. 범위가 좁아지면 CEO Agent 또는 Designer Agent 흐름으로 `/spec`을 사용해 사양을 만듭니다.
4. 병렬 작업이 필요하면 `./scripts/setup-worktree.sh feature-name`으로 독립 작업 폴더를 만듭니다.
5. 구현이 끝나면 `/review`와 `/qa` 또는 `./scripts/qa-score.sh <path>`로 품질 점수를 확인합니다.
6. 브라우저 검증이 필요한 기능은 Playwright MCP를 사용합니다.
7. 출시 준비가 되면 `/ship`으로 머지 전 체크리스트와 연결 이슈 종료 흐름을 확인합니다.
8. 반복되는 결정, 패턴, 남은 작업은 `/memory`로 `.github/memory/`에 저장합니다.

## 프로젝트 구조

```text
.github/
├── agents/                 # 6개 역할 에이전트
├── skills/                 # office-hours, autoplan, spec, qa, review, investigate, codegraph, ship, memory 스킬
└── copilot-instructions.md # Copilot 프로젝트 지침
.vscode/
└── mcp.json                # Playwright + CodeGraph MCP 설정 (.gitignore 예외로 추적)
docs/
└── PLAN.md                 # 구현 계획
.gitattributes              # 셸 스크립트 LF 줄바꿈 고정
scripts/
├── setup-worktree.sh       # 단일 Git worktree 생성
├── parallel-work.sh        # 여러 Git worktree 생성
├── merge-worktree.sh       # worktree 브랜치 병합 및 정리
├── office-hours-workflow.sh # 제품 프레이밍 리포트 생성
├── autoplan-workflow.sh    # sprint chain dry-run 생성
├── memory-workflow.sh      # memory 저장/검색/prune dry-run
├── qa-score.sh             # 0-100 QA 점수 계산
├── qa-workflow.sh          # QA 점수와 출시 판단 리포트 생성
├── review-workflow.sh      # diff 기반 리뷰 리포트 생성
├── investigate-workflow.sh # 원인 조사 리포트 생성
├── ship-workflow.sh        # PR merge/issue close 안전 dry-run
├── spec-workflow.sh        # 사양 품질 게이트와 이슈 생성 dry-run
└── validate-ghcp.sh        # Copilot 변환본 구조 검증
```

## 운영 원칙

- 브라우저 작업은 Playwright MCP로 처리하고 별도 브라우저 하니스를 구현하지 않습니다.
- 원본 gstack의 browser daemon, `$B` CLI, `/browse`, `/scrape`, `/skillify`는 재구현하지 않습니다.
- URL smoke test는 Playwright MCP로 title, visible state, accessibility snapshot, screenshot 필요 여부를 확인합니다.
- GitHub 작업은 `gh` CLI를 사용하되 실행 전 사용자 확인을 받습니다.
- 스킬은 반드시 폴더+`SKILL.md` 구조로 유지합니다.
- 에이전트와 스킬 frontmatter는 간단하고 명확하게 유지합니다.
- 자동화 스크립트는 순수 Git과 셸 스크립트만 사용합니다.
- 셸 스크립트는 `.gitattributes`로 LF 줄바꿈을 고정해 Windows 체크아웃에서도 CI/로컬 실행이 동일합니다.
- `.vscode/`는 무시하되 `.vscode/mcp.json`만 예외로 추적해 Playwright MCP 설정을 함께 배포합니다.

## CI 검증

GitHub Actions는 `.github/workflows/validate.yml`에서 다음 smoke test를 실행합니다.

- `./scripts/validate-ghcp.sh`
- `./scripts/qa-score.sh .`
- `./scripts/qa-workflow.sh .`
- `./scripts/office-hours-workflow.sh` smoke
- `./scripts/autoplan-workflow.sh` smoke
- `./scripts/spec-workflow.sh` dry-run
- `./scripts/review-workflow.sh` smoke
- `./scripts/investigate-workflow.sh` smoke
- `./scripts/ship-workflow.sh` dry-run
- `./scripts/memory-workflow.sh` dry-run