# ai_agent_setup

> **AI 코딩 에이전트용 스킬·도구 설치기.** 스킬을 **커밋에 고정**해 어느 컴퓨터에서든 같은 내용을 설치하고, 설치가 끝나면 **이름으로 실제 설치됐는지 검증**합니다. 포크해서 `manifest/` 에 자기 목록을 넣어 쓸 수 있습니다.

처음에는 만든 사람 한 명이 여러 PC·AI 도구 환경을 똑같이 맞추려고 시작했고, 같은 고민이 있는 사람이 포크해 쓰도록 공개되어 있습니다. 새 머신이나 새 컨테이너에서 이 저장소를 가리키기만 하면 매니페스트대로 설치됩니다.

<!-- BEGIN:generated:summary -->
> **이 저장소가 지금 관리하는 것** (manifest 에서 자동 생성):
> 외부 스킬 소스 **23개**(이름을 지정한 스킬 52개 + 전체를 받는 `*` 소스 10개), 이 저장소가 직접 정의한 로컬 스킬 **5개**, 도구 **21개**.
>
> **`--tag core`(작은 세트)**: 스킬 소스 `anthropics/skills`, `obra/superpowers`, `addyosmani/agent-skills`, `forrestchang/andrej-karpathy-skills`, `DietrichGebert/ponytail`, 도구 `skills-cli`, `uv`. 로컬 스킬은 포함되지 않습니다.
<!-- END:generated:summary -->

### 무엇이 "같게" 설치되고, 무엇은 아닌가

| 대상 | 같음의 의미 |
|---|---|
| 외부 스킬 소스 (`manifest/skills.list`) | **고정됨.** 40자리 커밋으로 받고, 설치 뒤 `SKILL.md` 의 이름으로 실제 설치됐는지 확인합니다 |
| 이 저장소의 로컬 스킬 (`skills/`) | 클론한 체크아웃 그대로입니다(클론 = 고정) |
| 도구 (`manifest/tools.list`) | **버전·커밋·해시로 고정됨(직접 설치하는 패키지까지).** npm·uv 는 `@버전`/`==버전`, git 은 40자리 커밋, 받아서 실행하는 설치 스크립트(uv, orx)는 sha256 을 확인한 뒤 실행합니다. `check` 는 "있다"가 아니라 **그 버전이다**를 확인하므로, 다른 버전이 이미 깔려 있으면 정해진 버전으로 다시 설치합니다(더 새 버전이어도 내려갑니다) |
| 설치기가 쓰는 skills CLI | **고정됨.** `manifest/skills-cli.version` (`npx -y skills@<버전>`) |
| MCP 서버 등록 (leann, context7, playwright) | 등록하는 패키지는 고정(`npx -y 패키지@버전`)이지만, 이미 등록돼 있으면 건너뛰므로 **다른 버전으로 등록된 것은 바꾸지 않습니다**. `claude` CLI 가 있을 때만 등록됩니다 |
| 줄바꿈 | 설치기가 skills CLI 의 git 에 `core.autocrlf=false` 를 강제하고, 이 저장소는 `.gitattributes` 로 체크아웃을 LF 로 고정합니다. Windows 의 Git 기본값(`autocrlf=true`)이면 받은 스킬이 CRLF 가 되어 Linux·맥과 다른 바이트로 설치되고, 스킬에 든 `.sh` 는 bash 에서 깨졌습니다(CI 의 세 OS 비교에서 확인). **이 수정 전에 Windows 에 설치한 스킬은 CRLF 일 수 있으니 설치기를 다시 실행하세요** |
| 고정되지 않는 것 | 고정한 패키지의 **전이 의존성**(그 패키지가 끌어오는 다른 패키지)과, 업스트림이 버전·커밋을 지우는 경우. 후자는 아직 감시하지 않습니다 |

그래서 **같은 버전의 같은 패키지가 깔린다**까지는 말할 수 있지만, 전이 의존성까지 비트 단위로 같다는 뜻은 아닙니다. 버전을 올릴 때는 `manifest/tools.list` 의 설치 명령과 `check` 의 버전을 함께 고치고(`skills CLI` 는 `manifest/skills-cli.version` 도), `bash scripts/validate.sh` 가 버전 없이 넣은 도구와 해시 확인 없이 받아 실행하는 명령을 막아 줍니다. 고정할 수 없는 도구는 `tags` 에 `unpinned` 를, 설명에 `미고정: 사유` 를 적어야 통과합니다.

### 어디서 검증됐나

| 환경 | 상태 |
|---|---|
| Linux 빈 환경 + Claude Code | 검증됨. `bootstrap.sh` 전체, `verify.sh`, 2차 실행(멱등), Node 설치기를 반복해서 확인했습니다 |
| GitHub Actions (ubuntu / macOS / Windows) | 검증됨. 세 OS 에서 Node 설치기 dry-run·로컬 스킬 실제 설치·와일드카드 소스 1개 실제 설치. macOS 러너에서는 `bootstrap.sh` 전체(스킬 + 도구)를 실제로 실행하고 `verify.sh`·2차 실행까지 확인합니다 |
| 소유자의 Windows PC | 소유자 보고: Git Bash `bootstrap.sh` 로 스킬과 도구 21개 중 19개 설치, PowerShell Node 설치기로 스킬 설치 정상. 이후 `graft`·`im-not-ai` 처리와 Node 사전 점검을 바꿨고 **그 뒤의 재실행 기록은 아직 없습니다** |
| 세 OS 의 설치 결과 비교 | CI 가 ubuntu·macOS·Windows 에서 같은 설치기로 스킬 전체를 깔고 설치된 파일을 직접 해시해 비교합니다(`scripts/snapshot.mjs --diff`). 다르면 CI 가 실패합니다. 이 비교가 Windows 의 CRLF 문제를 찾아냈습니다 |
| 실제 맥북 | **미검증.** 맥은 CI 러너에서만 확인했습니다 |
| 실제 WSL | **미검증.** WSL 오설치 감지 로직만 시험했습니다 |
| Codex · Cursor · Gemini CLI · OpenCode | **미검증.** skills CLI 가 에이전트를 자동 감지해 각 폴더에 설치한다고 하지만 이 저장소에서 확인한 적은 없습니다. 검증은 Claude Code 에서만 했습니다 |
| 스킬이 많을 때의 영향 | **미측정.** 컨텍스트 비용, 에이전트가 엉뚱한 스킬을 고르는 정도를 재 본 적이 없습니다 |
| `skill-radar` 의 설치 단계 | **미실행.** 후보 카드를 보여주는 단계까지만 시험했습니다 |

<details>
<summary>English summary</summary>

**ai_agent_setup** installs Agent Skills and CLI tools for AI coding agents from a manifest, and checks afterwards that every skill you defined is really installed.

- Skill sources are pinned to 40-character commits, so every machine gets the same content. After installing, the installer compares the skill *names* against `skills ls` because the skills CLI silently skips names that do not match.
- CLI tools (`manifest/tools.list`) are pinned to exact versions (npm `@x.y.z`, uv `==x.y.z`, git commits, install scripts checked against a sha256). Transitive dependencies are not pinned, and an upstream deleting a pinned version is not monitored yet.
- Cross-platform path: `git clone --depth 1 --branch main https://github.com/kc9302/ai_agent_setup.git`, then `node scripts/install-skills.mjs` (Node.js 22.20+ and git; skills only). `bash bootstrap.sh` installs skills and tools on Linux, macOS, WSL and Git Bash.
- Verified: a clean Linux environment with Claude Code, and GitHub Actions runners (ubuntu, macOS, Windows). Not verified: a real MacBook, real WSL, Codex, Cursor, Gemini CLI, OpenCode.
- Fork it and replace `manifest/skills.list` and `manifest/tools.list` with your own lists. `bash scripts/validate.sh` checks the format.
- The docs are in Korean; `CATALOG.md` explains what each entry is and why it is included.

</details>

## 빠른 시작

### 처음이라면: 작은 세트 + 설치 전 미리보기

전체 설치는 스킬과 도구 21개를 모두 깝니다. 처음 받는 사람은 **스킬만, `core` 태그 소스만** 설치하는 `minimal` 로 시작하세요. 도구·MCP 서버 등록·`curl | sh` 가 없고 관리자 권한이 필요 없습니다. 다만 "작다"는 전체보다 작다는 뜻입니다: `core` 소스 중 와일드카드(`*`) 소스가 커서 **2026-10-07 측정으로 스킬 58개**가 설치됩니다. 더 줄이려면 `manifest/skills.list` 의 `core` 태그를 조정하세요.

```
node scripts/install-skills.mjs --profile minimal --diff    # 설치하지 않고 겹침만 미리 보기 (Windows·맥·Linux 공통)
node scripts/install-skills.mjs --profile minimal           # 설치
# bash 를 쓰는 환경:  bash bootstrap.sh --profile minimal --diff   →   bash bootstrap.sh --profile minimal
```

> **⚠ 같은 이름의 스킬이 이미 있으면 확인도 백업도 없이 덮어씁니다.** (skills CLI 의 동작이며, 직접 만든 스킬도 마찬가지입니다. 빈 환경에서 확인했습니다.) `--diff` 는 설치될 스킬마다 *신규 / 같은 출처 갱신 / 다른 출처·출처 불명(덮어씀)* 으로 나눠 보여줍니다. 아끼는 스킬이 "덮어씀"에 있으면 먼저 폴더를 복사해 두세요. 와일드카드(`*`) 소스는 이름을 알려고 소스를 받아 오므로 몇 초 걸리고 네트워크가 필요합니다. `minimal` 에는 이 저장소의 로컬 스킬(`skills/`)이 포함되지 않습니다. 필요한 것만 `npx skills add kc9302/ai_agent_setup --skill <이름> -g -y` 로 추가하세요.

### 스킬만, 어디서나 (Windows PowerShell · macOS · Linux 공통, 가장 단순)

```
git clone --depth 1 --branch main https://github.com/kc9302/ai_agent_setup.git
cd ai_agent_setup
node scripts/install-skills.mjs
```

Node.js 22.20+ 와 git 만 있으면 됩니다(`skills` CLI 가 요구하는 버전이며, 더 낮으면 `npx` 가 조용히 옛 버전으로 내려가 고정 커밋 설치가 실패합니다). 시작할 때 환경을 점검하고(Node·git 버전, 오래된 클론, WSL 에 잘못 설치되는 경우), 끝나면 정의한 스킬이 이름으로 실제 설치됐는지 확인합니다. 설치 후 **Claude Code 를 새 세션으로 다시 열어야** 스킬이 보입니다. `--dry-run` 으로 실행할 명령만 볼 수 있습니다.
이미 클론한 폴더가 있다면 `git fetch --depth 1 origin main` 과 `git reset --hard FETCH_HEAD` 를 **각각** 실행한 뒤 다시 실행하세요(PowerShell 5.1 은 `&&` 를 지원하지 않습니다).

> **설치 로그에 `✗ … PromptScript: PromptScript does not support global skill installation` 줄이 보여도 정상입니다.** 로컬 스킬 설치 요약에 나오는 skills CLI 의 안내로, 전역 설치를 지원하지 않는 에이전트(PromptScript)를 건너뛴다는 뜻입니다. 다른 에이전트 설치와 이 스크립트의 결과(종료 코드·검증)에는 영향이 없습니다. 진짜 실패는 마지막의 `finished with N failure(s)` 목록(bash)이나 `실패` 요약(Node)에 나옵니다.

### 스킬 + 도구 (Linux · macOS · WSL · Windows Git Bash)

```bash
# 이미 클론돼 있으면 clone 이 실패하므로 최신으로 맞춘다. 오래된 사본으로 설치되는 것을 막는다.
git clone --depth 1 --branch main https://github.com/kc9302/ai_agent_setup.git ~/.ai_agent_setup 2>/dev/null \
  || { git -C ~/.ai_agent_setup fetch --depth 1 origin main && git -C ~/.ai_agent_setup reset --hard FETCH_HEAD; }
bash ~/.ai_agent_setup/bootstrap.sh

# 또는 클론 없이 한 줄
curl -fsSL https://raw.githubusercontent.com/kc9302/ai_agent_setup/main/bootstrap.sh | bash
```

AI 에이전트에게 맡기려면 이렇게만 말하면 됩니다:

> `https://github.com/kc9302/ai_agent_setup` 보고 내 환경 세팅해줘

에이전트는 `AGENTS.md` 를 읽고, Windows·맥이면 위의 Node 설치기를, Linux·WSL 이면 `bootstrap.sh` 를 실행합니다.

### 이 저장소가 직접 정의한 스킬 (`skills/`)

아래 스킬은 다른 저장소가 아니라 **이 저장소의 `skills/` 폴더**에 있습니다. `bootstrap.sh` 가 자동으로 설치하지만, 아래 매니페스트 표만 보고 손으로 설치하면 **빠집니다.**

| 스킬 | 하는 일 |
|---|---|
| `ai-setup-sync` | 이 저장소로 스킬·도구를 동기화하는 절차 |
| `web-design-guidelines` | Web Interface Guidelines 로 UI 리뷰 (규칙을 고정 사본으로 포함) |
| `stakeholder-rehearsal` | 이해관계자 반응을 라운드별로 시뮬레이션해 시나리오 리포트를 쓴다 |
| `skill-radar` | 매일 갱신되는 인기·신규 스킬 후보를 카드로 보여주고, 요청할 때만 설치를 돕는다 |
| `persona-sim-review` | 가상 인물 여러 명에게 출시·공개 가능 여부를 평가받는다 |

**Windows 에서는** 두 가지 중 하나를 쓰세요.
- **Git Bash 에서 `bash bootstrap.sh`**: 스킬과 도구를 한 번에 설치합니다. 소유자의 Windows 실행에서 스킬과 도구 21개 중 19개가 설치된 것이 보고됐습니다(위 "어디서 검증됐나" 참고). 빌드 도구가 없으면 `graft` 는 네이티브 모듈 빌드가 실패해도 명령이 동작하면 경고만 남기고, 심볼릭 링크가 필요한 `im-not-ai` 는 개발자 모드와 `MSYS=winsymlinks:nativestrict` 가 없으면 "건너뜀"으로 표시됩니다.
- **PowerShell 에서 Node 설치기**(아래): 스킬만 설치합니다. PowerShell 에서 `bash` 를 치면 Git Bash 가 아니라 WSL 의 bash 가 실행돼 스킬이 Windows 가 아니라 WSL 안에 설치될 수 있습니다. `bootstrap.sh` 는 이를 감지해(WSL 홈에는 `.claude` 가 없고 Windows 쪽에만 있을 때) 멈추고 안내합니다. WSL 안에 설치하려면 `--wsl`. PowerShell 에서 Git Bash 를 쓰려면 `& "$env:ProgramFiles\Git\bin\bash.exe" bootstrap.sh`.

맥의 기본 bash(3.2)가 걱정될 때도 Node 설치기를 쓸 수 있습니다. Node 설치기는 `bootstrap.sh` 의 스킬 단계와 같은 일을 합니다(매니페스트 스킬 전부 + 위 로컬 스킬 + 설치 후 이름 확인). 도구(`manifest/tools.list`)는 설치하지 않으므로 도구가 필요하면 `bootstrap.sh` 를 쓰세요. 설치 후에는 **Claude Code 를 새 세션으로 다시 열어야** 새 스킬이 보입니다.

```bash
git clone --depth 1 https://github.com/kc9302/ai_agent_setup.git
cd ai_agent_setup
node scripts/install-skills.mjs               # 전부 설치하고 확인 (--dry-run 으로 명령만 보기, --project 로 현재 프로젝트에만)
```

스킬 하나만 필요하면:

```bash
npx skills add kc9302/ai_agent_setup --skill persona-sim-review -g -y
npx skills ls -g                                                  # 설치된 스킬 확인
```

요구사항: `git`, Node.js 22.20+ (`npx`). 선택: `jq` (discover 용), `GITHUB_TOKEN` (API rate limit 완화).

## 옵션

```bash
bash bootstrap.sh --project                 # 전역(~) 대신 현재 프로젝트에만 스킬 설치
bash bootstrap.sh --agent claude-code       # 특정 에이전트만 (반복 가능). 기본은 자동 감지
bash bootstrap.sh --tag core                # 태그가 core 인 항목만
bash bootstrap.sh --profile minimal         # 작은 세트: 스킬만(core), 도구·MCP·curl|sh 없음 (full 이 기본)
bash bootstrap.sh --diff                    # 설치하지 않고, 이미 가진 스킬과 겹치는/덮어쓸 것을 미리 보기 (Node 필요)
bash bootstrap.sh --skills-only             # 스킬만 / --tools-only 도구만
bash bootstrap.sh --dry-run                 # 실행할 명령만 출력
AI_SETUP_AGENTS=claude-code,codex bash bootstrap.sh   # 환경변수로 에이전트 지정
```

## 무엇이 설치되나

### 스킬 (`manifest/skills.list`)

<!-- BEGIN:generated:skills -->
| 저장소 | 설치 스킬 | 태그 | 설명 |
|---|---|---|---|
| [anthropics/skills](https://github.com/anthropics/skills) | docx, pdf, pptx, xlsx, skill-creator, webapp-testing, doc-coauthoring, mcp-builder, frontend-design, theme-factory, canvas-design, web-artifacts-builder | official,docs,design,core | Anthropic 공식 스킬. 문서 생성(docx/pdf/pptx/xlsx)·공동 문서 작성, MCP 서버 제작, 프론트엔드/테마/캔버스 디자인, 웹 아티팩트, 스킬 제작, 웹앱 테스트 |
| [obra/superpowers](https://github.com/obra/superpowers) | 전체 | methodology,core | TDD·브레인스토밍·계획 등 개발 방법론 스킬 프레임워크 |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | 전체 | methodology,core | Addy Osmani 의 프로덕션급 엔지니어링 스킬 모음 (spec-driven, debugging, code-review 등) |
| [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | 전체 | behavior,core | Karpathy 가 지적한 LLM 코딩 함정을 피하도록 하는 행동 규칙 스킬 |
| [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | 전체 | methodology,core | "가장 게으른 동작하는 해법" 강제. stdlib·내장 기능 우선, 과잉 설계 방지. review/audit/debt 스킬 포함 |
| [tt-a1i/archify](https://github.com/tt-a1i/archify) | 전체 | diagram,visual | 설명·코드를 인터랙티브 아키텍처/시퀀스/데이터플로우 다이어그램(HTML)으로 변환 |
| [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | 전체 | design,frontend | UI/UX 디자인 인텔리전스 (ui-ux-pro-max) + design-system, ui-styling, banner-design, slides(HTML 발표자료), brand, design |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | vercel-react-best-practices, vercel-composition-patterns, writing-guidelines | frontend,web | Vercel 의 React/작문 가이드라인 스킬. web-design-guidelines 는 실행마다 원격 규칙을 내려받아 고정되지 않으므로 이 저장소의 skills/web-design-guidelines(고정 사본)로 대체 |
| [blader/humanizer](https://github.com/blader/humanizer) | 전체 | writing | AI 특유의 말투(not X but Y, 강조 마무리, 억지 3단 나열 등 26개 패턴)를 제거해 사람이 쓴 글처럼 고침 (영어) |
| [huggingface/skills](https://github.com/huggingface/skills) | hf-cli, huggingface-llm-trainer, huggingface-datasets, huggingface-papers, huggingface-gradio, huggingface-trackio, huggingface-local-models, huggingface-community-evals, huggingface-spaces | ml | Hugging Face 공식 스킬. Hub CLI, TRL 학습, 데이터셋, 논문, Gradio, 실험 추적, 로컬 모델, 평가, Spaces 배포 |
| [mattpocock/skills](https://github.com/mattpocock/skills) | grill-me, handoff, to-spec, writing-for-agents | methodology,productivity | Matt Pocock 스킬 중 superpowers 와 안 겹치는 것만: 집요한 질문으로 설계 검증(grill-me), 세션 인수인계(handoff), 스펙 작성(to-spec), 에이전트용 문서 작성법(writing-for-agents) |
| [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design) | 전체 | diagram,visual | 편집 디자인 품질의 다이어그램 42종 (HTML/SVG/PNG). draw.io/Mermaid/Excalidraw 가져오기, 브랜드 색상 반영 |
| [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | design-taste-frontend | design,frontend | 뻔한 AI식 UI 를 피하는 프론트엔드 디자인 스킬. 13개 중 기본 1개만 (ui-ux-pro-max 와 겹치지 않게) |
| [trailofbits/skills](https://github.com/trailofbits/skills) | differential-review, sharp-edges, property-based-testing, semgrep-rule-creator | security,review,testing | Trail of Bits 보안 스킬 중 범용 4개: 변경분 보안 리뷰, 위험한 API/설정 탐지, 속성 기반 테스트, Semgrep 룰 작성 (블록체인·퍼징 전용은 제외) |
| [muratcankoylan/Agent-Skills-for-Context-Engineering](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering) | context-fundamentals, context-degradation, context-compression, context-optimization, multi-agent-patterns, memory-systems, tool-design, filesystem-context, evaluation | context,agents,methodology,full-depth | 컨텍스트 엔지니어링 선별 9개: 컨텍스트 윈도우 원리·열화 진단·압축·최적화, 멀티 에이전트 패턴, 메모리, 도구 설계, 파일 기반 컨텍스트, 에이전트 평가 |
| [hamelsmu/evals-skills](https://github.com/hamelsmu/evals-skills) | 전체 | ml,evals | Hamel Husain 의 LLM 평가 스킬 7개: 오류 분석, 합성 데이터, 심판 프롬프트 작성·검증, RAG 평가, 리뷰 UI, 평가 감사 |
| [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) | 전체 | web,quality,frontend | Lighthouse 기반 웹 품질 스킬 6개: 접근성(WCAG 2.2), Core Web Vitals, 성능, SEO, 모범 사례, 통합 품질 감사 |
| [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | security-audit | security,review | Cloudflare 의 코드베이스 보안 감사 스킬: 정찰→공격 유형별 탐색→검증→JSON 보고서(스키마 검증 스크립트 포함). 웹/RPC/클라우드/공급망/AI·LLM 등 영역별 체크리스트 |
| [emilkowalski/skills](https://github.com/emilkowalski/skills) | emil-design-eng, animate, review-animations, break-ui, animation-vocabulary | design,frontend,animation | Emil Kowalski 의 UI 마감·모션 스킬 중 웹용 5개: 디자인 엔지니어링 철학, 애니메이션 설계, 모션 코드 리뷰, 최악 데이터로 UI 깨보기, 모션 용어 사전 (Swift/Expo/모바일 전용은 제외) |
| [Jakeschincariol/arena-skill](https://github.com/Jakeschincariol/arena-skill) | arena | agents,methodology,heavy | 같은 작업을 서브에이전트 N개(기본 100, --quick 16)에게 맡겨 서로 공격·방어시키는 토너먼트로 해법 하나를 남김. 기본 100개는 서브에이전트 595회 호출이라 비용이 크다 — 일상에는 --quick(91회) 권장 |
| [opendataloader-project/opendataloader-pdf](https://github.com/opendataloader-project/opendataloader-pdf) | odl-pdf | pdf,docs | opendataloader-pdf(ODL)로 PDF 를 Markdown/JSON/HTML 로 추출하는 절차: 설치된 --help 를 먼저 읽고, 최소 명령을 만들고, 종료 코드 0 이 곧 성공이 아님을 전제로 추출 결과를 검증한다. 런타임(Java 11+ 와 pip/npm 패키지)은 따로 설치해야 한다 |
| [mikehasa/golive-skill](https://github.com/mikehasa/golive-skill) | golive | deploy,devops | 에이전트가 만든 앱을 사용자 본인의 호스팅·DB·인증·결제·이메일·DNS 계정에서 실서비스로 올리는 절차. 계획을 사람이 승인하기 전에는 계정에 쓰지 않는다 (알파 0.1.0-alpha.8) |
| [QingYunA/answer-me-with-html](https://github.com/QingYunA/answer-me-with-html) | answer-me-with-html | docs,visual | 복잡한 답을 Markdown 초안으로 쓰면 번들 CLI 가 한 페이지 HTML 설명서(템플릿, SVG 자동 배치, 문체 점검)로 만들어 준다. 상시 모드 플러그인은 포함하지 않는다 |
<!-- END:generated:skills -->

현재 별 수 보기: `bash scripts/stars.sh` · 각 스킬 상세 설명: [`CATALOG.md`](CATALOG.md)

### 도구 (`manifest/tools.list`)

<!-- BEGIN:generated:tools -->
| 도구 | 고정 버전 | 태그 | 설명 |
|---|---|---|---|
| `skills-cli` | 1.7.1 | core | Agent Skills 설치 CLI (skills.sh). bootstrap 이 스킬 설치에 사용 |
| `agent-browser` | 0.38.2 | browser | AI 에이전트용 브라우저 자동화 CLI (Vercel Labs) |
| `uv` | 0.12.23 | python,core | 빠른 Python 패키지/도구 관리자 (Astral). 공식 설치 스크립트가 막히면 pip 로 폴백. leann·markitdown 설치에 사용 |
| `leann` | 0.3.8 | rag,search,python | 저장공간 97% 절감 로컬 벡터 DB. 코드/문서/메일을 시맨틱 검색·RAG (StarTrail-org/LEANN) |
| `leann-mcp` | — | rag,search,mcp | LEANN 을 Claude Code MCP 서버(leann-server)로 등록. leann 이 설치된 경우에만 등록. 코드베이스 시맨틱 검색을 에이전트가 직접 사용 |
| `markitdown` | 0.1.8 | docs,python | PDF/Word/PPT/Excel/HTML 등을 Markdown 으로 변환하는 CLI (Microsoft) |
| `context7-mcp` | 4.2.0 | mcp,docs | 라이브러리 최신 공식 문서를 에이전트에 실시간 제공하는 MCP (Upstash Context7) |
| `playwright-mcp` | 0.0.83 | mcp,browser | 에이전트가 실제 브라우저를 조작·검증하는 MCP (Microsoft Playwright) |
| `graphify` | 0.9.79 | code,graph,python | 코드·문서를 질의 가능한 지식 그래프로 변환 (tree-sitter, 벡터 DB 불필요). graphify install 로 /graphify 스킬 등록 (PyPI 패키지명은 graphifyy) |
| `llmfit` | 1.1.16 | ml,local-llm,python | 내 하드웨어(CPU/RAM/GPU)에서 돌아가는 오픈 LLM 을 양자화별로 추천 |
| `kordoc` | 4.19.2 | docs,korean | 한국 문서 HWP·HWPX·PDF·Office·이미지(OCR) 를 Markdown/JSON 으로 변환 |
| `officecli` | 1.0.153 | docs,office | AI 에이전트용 Word/Excel/PowerPoint 읽기·편집·자동화 CLI (내장 렌더링, 수식 계산). 버전을 고정하고 자동 업데이트를 끈다(기본값은 켜짐이라 시간이 지나면 환경마다 버전이 달라진다) |
| `hyperresearch` | 0.12.0 | research,python | Claude Code 를 딥 리서치 에이전트로 전환 (16단계 파이프라인, 인용 검증). --global 로 ~/.claude 에 /hyperresearch 스킬과 에이전트만 설치, 프로젝트는 건드리지 않음 |
| `paperclipai` | 2026.1005.0 | agents,orchestration | AI 에이전트 팀을 조직도·예산·목표로 관리하는 Node 서버+React UI 의 CLI. 설치는 CLI 만 하고, 서버 시작은 직접 `paperclipai onboard` (내장 Postgres 와 설정 파일을 만든다) |
| `graft` | 0.21.1 | agents,context,code-intel | 코드베이스를 그래프로 만들어 에이전트에 연결하는 컨텍스트 레이어 CLI. 설치 때만 텔레메트리를 끈다(DO_NOT_TRACK). 프로젝트 연결은 직접 `graft init` |
| `specify` | 1.1.1 | spec,methodology,python | GitHub 공식 Spec Kit CLI(MIT). 스펙 주도 개발용 프로젝트 골격(.specify/)과 에이전트 슬래시 명령을 만든다. 설치는 CLI 만 하고, 프로젝트 적용은 직접 `specify init <이름> --integration claude` |
| `agent-reach` | 커밋 a19a171 | research,web,python | Twitter/X·Reddit·YouTube·Bilibili·샤오홍슈 등 16개 플랫폼을 읽는 CLI(MIT). 검토한 커밋에 고정해 설치(PyPI 의 agent-reach 는 다른 프로젝트). 스킬과 외부 도구 설치(--system)는 자동 실행하지 않음 |
| `orx` | 0.2.15 | agents,autoresearch | alphaXiv OpenResearch 의 CLI(orx, MIT): 연구 에이전트용 로컬 워크스페이스·실험 트리·원격 연산 실행. v0.2.15 릴리스에 고정해 체크섬 검증 설치(~/.local/bin/orx, 셸 설정 변경 없음). 첫 실행부터 텔레메트리가 기본 켜짐 — 끄려면 `orx telemetry off`. 서버(orx up)와 스킬(orx install-skills)은 자동 실행하지 않음 |
| `pdf-inspector` | 1.25.2 | docs,pdf | Firecrawl 의 PDF 분류·텍스트 추출·Markdown 변환 CLI(Rust 기반, MIT). 텍스트 PDF 를 OCR 없이 로컬에서 빠르게 변환하고 스캔 PDF 는 detect 로 구분한다. markitdown 과 같은 용도의 대안 |
| `im-not-ai` | 커밋 2f3d943 | writing,korean | 한글 AI 글투 제거(번역투·기계적 병렬·관용구 등). 스킬 4개와 서브에이전트를 ~/.claude 에 심볼릭 링크로 연결(검토한 커밋에 고정, 클론은 ~/.local/share/im-not-ai 에 유지해야 함). blader/humanizer 의 한국어 짝 |
| `officecli-skills` | — | docs,office,skills | officecli 에 내장된 스킬 11개(기본 officecli + pptx·word·excel·word-form·morph-ppt·morph-ppt-3d·pitch-deck·academic-paper·data-dashboard·financial-model)를 감지된 에이전트에 설치. 스킬이 바이너리에 내장돼 있어 고정한 officecli 버전과 항상 같다 |
<!-- END:generated:tools -->

각 항목이 **무엇이고 왜 넣었는지**, 설치 후 사용법은 [`CATALOG.md`](CATALOG.md) 에 정리되어 있습니다.

## 제거하기 (되돌리기)

이 저장소는 설치만 하고 제거 스크립트는 두지 않습니다(다른 방법으로 깐 스킬과 섞이기 때문). 직접 지우세요.

- **스킬**: `npx skills ls -g` 로 이름과 출처를 확인한 뒤 `npx skills remove <이름> [<이름> …] -g -y`. 지정한 스킬만 지워지고 나머지는 남습니다. 프로젝트 범위로 깔았다면 `-g` 를 빼고 그 프로젝트에서 실행합니다. ⚠ `--all` 은 이 저장소가 깔지 않은 스킬까지 전부 지우므로 쓰지 마세요.
- **도구**: 깐 방식대로 지웁니다. npm 은 `npm uninstall -g <패키지>`, uv 는 `uv tool uninstall <이름>`, MCP 서버는 `claude mcp remove <이름>`(`leann-server`, `context7`, `playwright`). 도구마다 어떻게 설치되는지는 `manifest/tools.list` 의 설치 열에 있습니다.

## 두 환경이 같은지 확인하기

"같다"는 말만으로 믿지 않도록, 설치된 것을 기록해 두 환경을 비교할 수 있습니다.

```bash
node scripts/snapshot.mjs > mine.json                   # 스킬 + 도구 스냅샷 (bash 가 있으면 도구의 고정 버전 확인까지)
node scripts/snapshot.mjs --skills-only > mine.json     # 스킬만. bash 가 없는 Windows PowerShell 도 됩니다
bash scripts/verify.sh --json > mine.json               # 위와 같은 스냅샷 (bash)
node scripts/snapshot.mjs --diff mine.json other.json   # 두 스냅샷 비교. 다르면 종료 코드 1
```

**"같다"의 정의**: 스킬은 이름·출처·**고정 커밋·폴더 내용 해시**가 모두 같을 때(skills CLI 가 `~/.agents/.skill-lock.json` 에 남기는 값을 씁니다). 이 저장소의 로컬 스킬은 출처 경로가 머신마다 달라 이름만 비교하고, 내용 해시 차이는 참고로만 알립니다(줄바꿈 설정 차이일 수 있음). 도구는 고정한 버전이 설치돼 있을 때(`npm ls -g`, `uv tool list` 기준)이고, 확인하지 않은 쪽(`unchecked`, 예: Windows)은 비교에서 뺍니다. 스냅샷에는 OS·CPU·Node 버전만 들어가고 사용자 이름이나 경로는 들어가지 않습니다.

## 고정한 것이 사라지지 않았는지 확인하기

업스트림이 저장소를 지우거나 커밋을 없애거나 버전을 내리면 고정한 그대로는 설치되지 않습니다. `bash scripts/pin-alive.sh` 가 스킬 커밋과 도구 버전(npm·PyPI), 해시를 확인하는 설치 스크립트의 내용, git 커밋이 **지금도 받아지는지** 확인합니다. `pin-health` workflow 가 주 1회 이를 돌리고, 받을 수 없는 것이 있으면 이슈를 엽니다. "받아진다"는 지금 받을 수 있다는 뜻이지 앞으로도 그렇다는 보증이 아닙니다.

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
bash scripts/gen-docs.sh      # 이 README 의 표·숫자를 manifest 에서 다시 쓴다
bash scripts/validate.sh      # 형식 검사 (고정 안 된 소스는 오류, README 가 manifest 와 다르면 오류)
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
| `scripts/radar.sh` | 인기·신규 후보를 `candidates.json` 으로 만든다. 매일 `radar` workflow 가 돌려 `radar-data` 브랜치에 발행한다. 보여주기만 하고 설치·매니페스트 수정은 하지 않는다 |
| `scripts/snapshot.mjs` | 설치된 스킬·도구의 JSON 스냅샷을 만들고(`--skills-only` 는 스킬만), `--diff a.json b.json` 으로 두 환경을 비교한다. `verify.sh --json` 이 이것을 부른다 |
| `scripts/pin-alive.sh` | 고정한 스킬 커밋·도구 버전·설치 스크립트가 지금도 받아지는지 확인한다. 주 1회 `pin-health` workflow 가 돌린다 |
| `scripts/fetch-verified.sh` | 스크립트를 받아 sha256 이 맞을 때만 실행한다(`tools.list` 가 `curl \| sh` 대신 쓴다) |
| `scripts/gen-docs.sh` | 이 README 의 숫자 요약과 스킬·도구 표를 manifest 에서 다시 쓴다(`--check` 는 최신 여부만 확인). 표를 손으로 고치지 마세요 |
| `scripts/validate.sh` | 매니페스트·스크립트·README 일치 검사 (CI 에서도 실행) |

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
