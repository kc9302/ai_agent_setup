# ai_agent_setup

> 어떤 환경, 어떤 AI 코딩 도구에서도 **똑같은 스킬·도구 세팅**을 한 줄로.

AI 코딩 도구(Claude Code, Codex, Cursor, Gemini CLI, OpenCode …)에 설치할
**Agent Skills** 와 **오픈소스 도구** 를 매니페스트로 관리하는 저장소입니다.
새 머신이나 새 컨테이너에서 이 저장소를 가리키기만 하면 전부 자동으로 설치됩니다.

## 빠른 시작

```bash
# 1) 클론해서 실행
git clone --depth 1 https://github.com/kc9302/ai_agent_setup.git ~/.ai_agent_setup
bash ~/.ai_agent_setup/bootstrap.sh

# 2) 또는 클론 없이 한 줄
curl -fsSL https://raw.githubusercontent.com/kc9302/ai_agent_setup/main/bootstrap.sh | bash
```

AI 에이전트에게 맡기려면 이렇게만 말하면 됩니다:

> `https://github.com/kc9302/ai_agent_setup` 보고 내 환경 세팅해줘

에이전트는 `AGENTS.md` 를 읽고 `bootstrap.sh` 를 실행합니다.

### 이 저장소가 직접 정의한 스킬 (`skills/`)

아래 스킬은 다른 저장소가 아니라 **이 저장소의 `skills/` 폴더**에 있습니다. `bootstrap.sh` 가 자동으로 설치하지만, 아래 매니페스트 표만 보고 손으로 설치하면 **빠집니다.**

| 스킬 | 하는 일 |
|---|---|
| `ai-setup-sync` | 이 저장소로 스킬·도구를 동기화하는 절차 |
| `web-design-guidelines` | Web Interface Guidelines 로 UI 리뷰 (규칙을 고정 사본으로 포함) |
| `stakeholder-rehearsal` | 이해관계자 반응을 라운드별로 시뮬레이션해 시나리오 리포트를 쓴다 |
| `persona-sim-review` | 가상 인물 여러 명에게 출시·공개 가능 여부를 평가받는다 |

`bash` 를 쓸 수 없을 때(예: Windows PowerShell)는 스킬 하나씩 이렇게 설치합니다. 설치 후에는 **Claude Code 를 새 세션으로 다시 열어야** 보입니다.

```bash
npx skills add kc9302/ai_agent_setup --list                      # 이 저장소가 제공하는 스킬 이름 확인
npx skills add kc9302/ai_agent_setup --skill persona-sim-review -g -y
npx skills ls -g                                                  # 설치된 스킬 확인
```

요구사항: `git`, Node.js 18+ (`npx`). 선택: `jq` (discover 용), `GITHUB_TOKEN` (API rate limit 완화).

## 옵션

```bash
bash bootstrap.sh --project                 # 전역(~) 대신 현재 프로젝트에만 스킬 설치
bash bootstrap.sh --agent claude-code       # 특정 에이전트만 (반복 가능). 기본은 자동 감지
bash bootstrap.sh --tag core                # 태그가 core 인 항목만
bash bootstrap.sh --skills-only             # 스킬만 / --tools-only 도구만
bash bootstrap.sh --dry-run                 # 실행할 명령만 출력
AI_SETUP_AGENTS=claude-code,codex bash bootstrap.sh   # 환경변수로 에이전트 지정
```

## 무엇이 설치되나

### 스킬 (`manifest/skills.list`)

| 저장소 | 설치 스킬 | 태그 | 설명 |
|---|---|---|---|
| [anthropics/skills](https://github.com/anthropics/skills) | docx, pdf, pptx, xlsx, doc-coauthoring, mcp-builder, frontend-design, theme-factory, canvas-design, web-artifacts-builder, skill-creator, webapp-testing | official, docs, design | Anthropic 공식: 문서 생성·공동 작성, MCP 제작, 디자인, 테스트 |
| [obra/superpowers](https://github.com/obra/superpowers) | 전체 | methodology | TDD·브레인스토밍·계획 등 개발 방법론 프레임워크 |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | 전체 | methodology | 프로덕션급 엔지니어링 스킬 (spec-driven, debugging, review …) |
| [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | 전체 | behavior | LLM 코딩 함정을 피하는 행동 규칙 |
| [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | 전체 | methodology | 최소주의 코딩 강제 (YAGNI, stdlib 우선). review/audit 포함 |
| [tt-a1i/archify](https://github.com/tt-a1i/archify) | 전체 | diagram | 설명·코드 → 인터랙티브 아키텍처 다이어그램(HTML) |
| [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | 전체 (7) | design | UI/UX 디자인 DB, design-system, ui-styling, banner-design, slides(HTML 발표) |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | react-best-practices, web-design-guidelines, composition-patterns, writing-guidelines | frontend | React·웹 디자인·작문 가이드라인 |
| [blader/humanizer](https://github.com/blader/humanizer) | 전체 | writing | AI 말투 26개 패턴 제거 (영어) |
| [mattpocock/skills](https://github.com/mattpocock/skills) | grill-me, handoff, to-spec, writing-for-agents | methodology | 설계 검증·세션 인수인계·스펙 작성 (겹치지 않는 4개만) |
| [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design) | 전체 | diagram | 편집 디자인 다이어그램 42종 |
| [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | design-taste-frontend | design | 반(反) AI 슬롭 프론트엔드 |
| [huggingface/skills](https://github.com/huggingface/skills) | hf-cli, llm-trainer, datasets, papers, gradio, trackio, local-models, community-evals, spaces | ml | Hugging Face 공식 ML 스킬 |

현재 별 수 보기: `bash scripts/stars.sh` · 각 스킬 상세 설명: [`CATALOG.md`](CATALOG.md)

### 도구 (`manifest/tools.list`)

| 도구 | 설치 | 설명 |
|---|---|---|
| [skills](https://github.com/vercel-labs/skills) | `npm i -g skills` | Agent Skills 설치 CLI ([skills.sh](https://skills.sh)). bootstrap 이 사용 |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | `npm i -g agent-browser` | AI 에이전트용 브라우저 자동화 CLI (Rust) |
| [uv](https://github.com/astral-sh/uv) | `curl … astral.sh/uv/install.sh \| sh` | Python 패키지/도구 관리자. LEANN 의 전제 조건 |
| [LEANN](https://github.com/StarTrail-org/LEANN) | `uv tool install leann-core --with leann` | 저장공간 97% 절감 로컬 벡터 DB. 코드·문서 시맨틱 검색/RAG |
| leann-mcp | `claude mcp add … leann_mcp` | LEANN 을 Claude Code MCP 서버로 등록 (claude CLI 없으면 건너뜀) |
| [markitdown](https://github.com/microsoft/markitdown) | `uv tool install 'markitdown[all]'` | PDF/Word/PPT/Excel → Markdown 변환 CLI |
| [graphify](https://github.com/Graphify-Labs/graphify) | `uv tool install graphifyy` | 코드·문서 → 지식 그래프, `/graphify` 스킬 |
| [llmfit](https://github.com/AlexsJones/llmfit) | `uv tool install llmfit` | 내 하드웨어에 맞는 로컬 LLM 추천 |
| [kordoc](https://github.com/chrisryugj/kordoc) | `npm i -g kordoc` | HWP/HWPX/PDF/Office → Markdown |
| [officecli](https://github.com/iOfficeAI/OfficeCLI) | `npm i -g @officecli/officecli` | Word/Excel/PPT 읽기·편집 CLI |
| [hyperresearch](https://github.com/jordan-gibbs/hyperresearch) | `uv tool install hyperresearch` + `hyperresearch install --global` | 딥 리서치 에이전트 (인용 검증, 지식 볼트). API 키는 선택 |
| [context7-mcp](https://github.com/upstash/context7) | `claude mcp add … @upstash/context7-mcp` | 라이브러리 최신 공식 문서 MCP |
| [playwright-mcp](https://github.com/microsoft/playwright-mcp) | `claude mcp add … @playwright/mcp` | 브라우저 조작 MCP |

각 항목이 **무엇이고 왜 넣었는지**, 설치 후 사용법은 [`CATALOG.md`](CATALOG.md) 에 정리되어 있습니다.

## 새 스킬 추가하기

```bash
bash scripts/discover.sh            # 별 많은 스킬 저장소 탐색 (매니페스트에 없는 것만)
bash scripts/discover.sh archify    # 키워드로 검색
```

마음에 드는 저장소를 `manifest/skills.list` 에 한 줄 추가합니다:

```
owner/repo | * | tags | 한 줄 설명
owner/repo | skill-a,skill-b | tags | 일부 스킬만 설치할 때
```

스킬 이름은 폴더 이름이 아니라 `SKILL.md` 의 `name:` 값입니다(틀리면 CLI 가 오류 없이 건너뜁니다).
그리고 **소스를 커밋에 고정**합니다. 그래야 클론한 시점과 상관없이 모든 환경에 같은 내용이 설치됩니다:

```bash
bash scripts/pin.sh --fill    # owner/repo → owner/repo#<커밋> 으로 고정
bash scripts/validate.sh      # 형식 검사 (고정 안 된 소스는 오류)
bash bootstrap.sh --dry-run   # 실행될 명령 확인
bash bootstrap.sh             # 실제 설치 + 설치 후 검증
git commit -am "add owner/repo: 이유"
```

`bootstrap.sh` 는 설치가 끝나면 정의한 스킬이 **실제로 전부 설치됐는지** 스스로 확인하고, 빠진 것이 있으면 실패로 보고합니다.
설치 없이 다시 확인하려면 `bash scripts/verify.sh` 입니다. 스킬을 올릴 때는 `bash scripts/pin.sh` 로 비교하고 변경 내용을 읽은 뒤 `--update owner/repo` 합니다.

추가한 항목은 `CATALOG.md` 에도 "무엇 / 왜 / 사용 예" 를 한 절 적어 둡니다.

오픈소스 도구는 `manifest/tools.list` 에 `name | check | install | tags | 설명` 으로 추가합니다.
`check` 가 종료코드 0 을 반환하면 이미 설치된 것으로 보고 건너뜁니다.
`install` 이 종료코드 **75** 로 끝나면 "선행 조건 미충족으로 건너뜀"으로 보고하며 실패로 세지 않습니다(예: Node 버전이 낮은 환경의 `paperclipai`).

## 스크립트

| 스크립트 | 역할 |
|---|---|
| `bootstrap.sh` | 매니페스트대로 전부 설치 |
| `scripts/status.sh` | 설치 상태 확인 |
| `scripts/verify.sh` | 정의한 스킬이 이 환경에 전부 설치됐는지 확인 (설치 안 함) |
| `scripts/pin.sh` | 스킬 소스를 커밋에 고정(`--fill`)·갱신(`--update`) |
| `scripts/stars.sh` | 등록된 저장소 별 수 실시간 조회 |
| `scripts/discover.sh` | 새 후보 탐색 (GitHub 토픽 `agent-skills`, `claude-skills`, `skill-md`, `agentic-skills`) |
| `scripts/validate.sh` | 매니페스트·스크립트 검사 (CI 에서도 실행) |

## 이 저장소 자체를 스킬로 설치

```bash
npx skills add kc9302/ai_agent_setup -g
```

`ai-setup-sync` 스킬이 설치되어, 이후 어떤 에이전트에게든 "내 세팅 동기화해줘" 라고만 하면 됩니다.

## 설계 원칙

- **매니페스트가 유일한 진실.** 머신에 손으로 깔지 말고 매니페스트를 고쳐 커밋한다.
- **별 수는 기록하지 않는다.** 금방 낡기 때문에 `stars.sh` 로 실시간 조회한다.
- **의존성 최소.** bash + git + node 만 있으면 동작한다. jq/yq 불필요 (discover 만 jq 사용).
- **부분 실패 허용.** 하나가 실패해도 나머지는 계속 설치하고, 마지막에 실패 목록을 보여준다.
