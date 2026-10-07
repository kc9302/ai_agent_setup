# ai_agent_setup

> **AI 코딩 에이전트용 스킬·도구 설치기.** 스킬을 **커밋에 고정**해 어느 컴퓨터에서든 같은 내용을 설치하고, 설치가 끝나면 **이름으로 실제 설치됐는지 검증**합니다. 포크해서 `manifest/` 에 자기 목록을 넣어 쓸 수 있습니다.

처음에는 만든 사람 한 명이 여러 PC·AI 도구 환경을 똑같이 맞추려고 시작했고, 같은 고민이 있는 사람이 포크해 쓰도록 공개되어 있습니다. 새 머신이나 새 컨테이너에서 이 저장소를 가리키기만 하면 매니페스트대로 설치됩니다.

<!-- BEGIN:generated:summary -->
> **이 저장소가 지금 관리하는 것** (manifest 에서 자동 생성):
> 외부 스킬 소스 **23개**(스킬을 이름으로 지정한 소스 13개 — 합쳐 스킬 52개 — + 스킬 전체를 받는 `*` 소스 10개), 이 저장소가 직접 정의한 로컬 스킬 **5개**, 도구 **21개**.
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
| 고정되지 않는 것 | 고정한 패키지의 **전이 의존성**(그 패키지가 끌어오는 다른 패키지)과, 업스트림이 버전·커밋을 지우는 경우. 후자는 막을 수 없고, 주 1회 `pin-health` 가 받을 수 있는지만 점검해 이슈로 알립니다(아래 "고정한 것이 사라지지 않았는지 확인하기") |

그래서 **같은 버전의 같은 패키지가 깔린다**까지는 말할 수 있지만, 전이 의존성까지 비트 단위로 같다는 뜻은 아닙니다. 버전을 올릴 때는 `manifest/tools.list` 의 설치 명령과 `check` 의 버전을 함께 고치고(`skills CLI` 는 `manifest/skills-cli.version` 도), `bash scripts/validate.sh` 가 버전 없이 넣은 도구와 해시 확인 없이 받아 실행하는 명령을 막아 줍니다. 고정할 수 없는 도구는 `tags` 에 `unpinned` 를, 설명에 `미고정: 사유` 를 적어야 통과합니다.

### 어디서 검증됐나

| 환경 | 상태 |
|---|---|
| Linux 빈 환경 + Claude Code | 검증됨. `bootstrap.sh` 전체, `verify.sh`, 2차 실행(멱등), Node 설치기를 반복해서 확인했습니다 |
| GitHub Actions (ubuntu / macOS / Windows) | 검증됨. 세 OS 에서 Node 설치기 dry-run·로컬 스킬 실제 설치·와일드카드 소스 1개 실제 설치. macOS 러너에서는 `bootstrap.sh` 전체(스킬 + 도구)를 실제로 실행하고 `verify.sh`·2차 실행까지 확인합니다 |
| 소유자의 Windows PC | 소유자 보고: Git Bash `bootstrap.sh` 로 스킬과 도구 21개 중 19개 설치(실패한 2개는 `graft` 와 `im-not-ai`, 이후 처리를 바꿈), PowerShell Node 설치기로 스킬 설치 정상. 이후 `graft`·`im-not-ai` 처리와 Node 사전 점검을 바꿨고 **그 뒤의 재실행 기록은 아직 없습니다** |
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
- CLI tools (`manifest/tools.list`) are pinned to exact versions (npm `@x.y.z`, uv `==x.y.z`, git commits, install scripts checked against a sha256). Transitive dependencies are not pinned, and an upstream deleting a pinned version or commit cannot be prevented; a weekly `pin-health` workflow only checks that every pin can still be fetched and opens an issue if not.
- Cross-platform path: `git clone --depth 1 --branch main https://github.com/kc9302/ai_agent_setup.git`, then `node scripts/install-skills.mjs` (Node.js 22.20+ and git; skills only). `bash bootstrap.sh` installs skills and tools on Linux, macOS, WSL and Git Bash.
- Verified: a clean Linux environment with Claude Code, and GitHub Actions runners (ubuntu, macOS, Windows). Not verified: a real MacBook, real WSL, Codex, Cursor, Gemini CLI, OpenCode.
- Fork it and replace `manifest/skills.list` and `manifest/tools.list` with your own lists. `bash scripts/validate.sh` checks the format.
- The docs are in Korean; `CATALOG.md` explains what each entry is and why it is included.

</details>

## 빠른 시작

### 처음이라면: 작은 세트 + 설치 전 미리보기

전체 설치는 스킬과 도구 21개를 모두 깝니다. 처음 받는 사람은 **스킬만, `core` 태그 소스만** 설치하는 `minimal` 로 시작하세요. 도구·MCP 서버 등록·`curl | sh` 가 없고 관리자 권한이 필요 없습니다. 다만 "작다"는 전체보다 작다는 뜻입니다: `core` 소스 중 와일드카드(`*`) 소스가 커서 **2026-10-07 측정으로 스킬 58개**가 설치됩니다. 더 줄이려면 `manifest/skills.list` 의 `core` 태그를 조정하세요.

```
git clone --depth 1 --branch main https://github.com/kc9302/ai_agent_setup.git
cd ai_agent_setup
node scripts/install-skills.mjs --profile minimal --diff    # 설치하지 않고 겹침만 미리 보기 (Windows·맥·Linux 공통)
node scripts/install-skills.mjs --profile minimal           # 설치
# 이미 쓰는 스킬이 있다면:  node scripts/install-skills.mjs --profile minimal --backup
# bash 를 쓰는 환경:  bash bootstrap.sh --profile minimal --diff   →   bash bootstrap.sh --profile minimal [--backup]
```

용어: **`core`** 는 매니페스트의 태그(작은 세트의 기준)이고, **`--profile minimal`** 은 "`core` 소스의 스킬만, 도구·MCP·로컬 스킬 없이" 설치하는 프로필입니다. `--tag core` 는 `core` 항목을 **도구까지 포함해** 설치하므로 `minimal` 과 다릅니다.

> **⚠ 같은 이름의 스킬이 이미 있으면 확인도 백업도 없이 덮어씁니다.** (skills CLI 의 동작이며, 직접 만든 스킬도 마찬가지입니다. 빈 환경에서 확인했습니다.) `--diff` 는 설치될 스킬마다 *신규 / 같은 출처 갱신 / 다른 출처·출처 불명(덮어씀)* 으로 나눠 보여줍니다. 아끼는 스킬이 "덮어씀"에 있으면 **`--backup` 을 붙여 설치하세요**: 설치 전에 덮어써질 기존 폴더(다른 출처·출처 불명)를 `~/.agents/skills-backup/<시각>/` 에 복사해 두고, 복사에 실패하면 설치하지 않습니다(같은 출처의 갱신과 내용이 같은 로컬 스킬은 복사하지 않습니다). 복사만 하려면 `--backup-only`. 와일드카드(`*`) 소스는 이름을 알려고 소스를 받아 오므로 몇 초 걸리고 네트워크가 필요합니다. `minimal` 에는 이 저장소의 로컬 스킬(`skills/`)이 포함되지 않습니다. 필요한 것만 `npx skills add kc9302/ai_agent_setup --skill <이름> -g -y` 로 추가하세요.

### 스킬만 전부, 어디서나 (Windows PowerShell · macOS · Linux 공통, 가장 단순)

위의 클론 폴더에서(`minimal` 이 아니라 **스킬 전부**를 받습니다):

```
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

# 클론 없이 한 줄: 편하지만 "그 순간의 main" 스크립트를 바로 실행하므로, 이 저장소가 내세우는 고정·검토와는 맞지 않습니다.
# 위의 클론 후 실행을 권장하고, 이 한 줄은 일회용 컨테이너처럼 어차피 믿고 쓰는 환경에서만 쓰세요.
curl -fsSL https://raw.githubusercontent.com/kc9302/ai_agent_setup/main/bootstrap.sh | bash
```

AI 에이전트에게 맡기려면 이렇게만 말하면 됩니다:

> `https://github.com/kc9302/ai_agent_setup` 보고 내 환경 세팅해줘

에이전트는 `AGENTS.md` 를 읽고, Windows·맥이면 위의 Node 설치기를, Linux·WSL 이면 `bootstrap.sh` 를 실행합니다.

### 이 저장소가 직접 정의한 스킬 (`skills/`)

아래 스킬은 다른 저장소가 아니라 **이 저장소의 `skills/` 폴더**에 있습니다. `bootstrap.sh` 가 자동으로 설치하지만, CATALOG 의 매니페스트 표만 보고 손으로 설치하면 **빠집니다.**

| 스킬 | 하는 일 |
|---|---|
| `ai-setup-sync` | 이 저장소로 스킬·도구를 동기화하는 절차 |
| `web-design-guidelines` | Web Interface Guidelines 로 UI 리뷰 (규칙을 고정 사본으로 포함) |
| `stakeholder-rehearsal` | 이해관계자 반응을 라운드별로 시뮬레이션해 시나리오 리포트를 쓴다 |
| `skill-radar` | 매일 갱신되는 인기·신규 스킬 후보를 카드로 보여주고, 요청할 때만 설치를 돕는다 |
| `persona-sim-review` | 가상 인물 여러 명에게 출시·공개 가능 여부를 평가받는다 |

**이미 Windows 에 설치해 두었다면:** 줄바꿈 수정(`core.autocrlf=false` 강제) 전에 받은 스킬은 CRLF 일 수 있습니다. 클론을 최신으로 맞추고 설치기를 다시 실행하면 같은 이름이 LF 로 덮어써집니다. 확인은 `node scripts/snapshot.mjs --skills-only` 의 `content_lf` 와 `content` 가 같은지로 합니다.

**Windows 에서는** 두 가지 중 하나를 쓰세요.
- **Git Bash 에서 `bash bootstrap.sh`**: 스킬과 도구를 한 번에 설치합니다. 소유자의 Windows 실행에서 스킬과 도구 21개 중 19개(실패 2개는 `graft`·`im-not-ai`)가 설치된 것이 보고됐습니다(위 "어디서 검증됐나" 참고). 빌드 도구가 없으면 `graft` 는 네이티브 모듈 빌드가 실패해도 명령이 동작하면 경고만 남기고, 심볼릭 링크가 필요한 `im-not-ai` 는 개발자 모드와 `MSYS=winsymlinks:nativestrict` 가 없으면 "건너뜀"으로 표시됩니다.
- **PowerShell 에서 Node 설치기**(아래): 스킬만 설치합니다. PowerShell 에서 `bash` 를 치면 Git Bash 가 아니라 WSL 의 bash 가 실행돼 스킬이 Windows 가 아니라 WSL 안에 설치될 수 있습니다. `bootstrap.sh` 는 이를 감지해(WSL 홈에는 `.claude` 가 없고 Windows 쪽에만 있을 때) 멈추고 안내합니다. WSL 안에 설치하려면 `--wsl`. PowerShell 에서 Git Bash 를 쓰려면 `& "$env:ProgramFiles\Git\bin\bash.exe" bootstrap.sh`.

맥의 기본 bash(3.2)가 걱정될 때도 Node 설치기를 쓸 수 있습니다. Node 설치기는 `bootstrap.sh` 의 스킬 단계와 같은 일을 합니다(매니페스트 스킬 전부 + 위 로컬 스킬 + 설치 후 이름 확인). 도구(`manifest/tools.list`)는 설치하지 않으므로 도구가 필요하면 `bootstrap.sh` 를 쓰세요. 설치 후에는 **Claude Code 를 새 세션으로 다시 열어야** 새 스킬이 보입니다.

Node 설치기의 옵션은 `--dry-run`(명령만 보기), `--project`(현재 프로젝트에만), `--profile minimal`, `--diff` 입니다.

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
bash bootstrap.sh --backup                  # 설치 전에, 덮어써질 기존 스킬을 ~/.agents/skills-backup/<시각>/ 에 복사 (Node 필요)
bash bootstrap.sh --skills-only             # 스킬만 / --tools-only 도구만
bash bootstrap.sh --dry-run                 # 실행할 명령만 출력
AI_SETUP_AGENTS=claude-code,codex bash bootstrap.sh   # 환경변수로 에이전트 지정
```

## 무엇이 설치되나

외부 스킬 소스 표와 도구 표(고정 버전 포함)는 [`CATALOG.md` 의 "한눈에 보기"](CATALOG.md#한눈에-보기-manifest-에서-자동-생성) 에 있고, 각 항목이 **무엇이고 왜 넣었는지**, 설치 후 사용법도 같은 파일에 있습니다. 원본은 `manifest/skills.list`, `manifest/tools.list` 입니다. 위 "이 저장소가 직접 정의한 스킬" 표의 5개는 이 저장소의 `skills/` 에서 설치됩니다.

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
node scripts/snapshot.mjs --check mine.json               # 스냅샷을 manifest 와 대조: 빠진 스킬·다른 커밋이 있으면 종료 코드 1 (--profile minimal 도 됨)
```

**"같다"의 정의**: 스킬은 이름·출처·**고정 커밋·폴더 내용 해시**가 모두 같을 때(skills CLI 가 `~/.agents/.skill-lock.json` 에 남기는 값을 씁니다). 이 저장소의 로컬 스킬은 출처 경로가 머신마다 달라 출처는 보지 않습니다. 두 스냅샷이 **같은 저장소 커밋**에서 설치됐으면 내용도 같아야 하고(다르면 실패), 저장소 커밋이 다르거나 모르면 내용 차이는 참고로만 알립니다. 스냅샷이 비어 있으면 둘 다 비어 있어도 "같다"로 치지 않습니다. 비교 대신 `--check` 는 스냅샷 하나를 manifest 와 직접 대조해, 둘 다 똑같이 빠뜨린 스킬도 잡습니다. 도구는 고정한 버전이 설치돼 있을 때(`npm ls -g`, `uv tool list` 기준)이고, 확인하지 않은 쪽(`unchecked`, 예: Windows)은 비교에서 뺍니다. 스냅샷에는 OS·CPU·Node 버전만 들어가고 사용자 이름이나 경로는 들어가지 않습니다.

## 고정한 것이 사라지지 않았는지 확인하기

업스트림이 저장소를 지우거나 커밋을 없애거나 버전을 내리면 고정한 그대로는 설치되지 않습니다. `bash scripts/pin-alive.sh` 가 스킬 커밋과 도구 버전(npm·PyPI), 해시를 확인하는 설치 스크립트의 내용, git 커밋이 **지금도 받아지는지** 확인합니다. `pin-health` workflow 가 주 1회 이를 돌리고, 받을 수 없는 것이 있으면 이슈를 엽니다. "받아진다"는 지금 받을 수 있다는 뜻이지 앞으로도 그렇다는 보증이 아닙니다.

## 새 스킬·도구 추가하기, 스크립트 목록

후보 찾기(`scripts/discover.sh`) → `manifest/skills.list` 한 줄 → 커밋 고정(`scripts/pin.sh --fill`) → `scripts/gen-docs.sh` → `scripts/validate.sh` → 실제 설치 → `CATALOG.md` 에 한 절 → PR 의 순서입니다. 단계별 명령, 이름 규칙(`SKILL.md` 의 `name:` 값), 모든 스크립트의 역할 표는 [`AGENTS.md`](AGENTS.md) 에 있습니다. 도구는 `manifest/tools.list` 에 `name | check | install | tags | 설명` 으로 추가하고, 고정 규칙은 그 파일 맨 위 주석에 있습니다.

## 이 저장소 자체를 스킬로 설치

```bash
npx skills add kc9302/ai_agent_setup -g
```

`ai-setup-sync` 스킬이 설치되어, 이후 어떤 에이전트에게든 "내 세팅 동기화해줘" 라고만 하면 됩니다.

## 설계 원칙

- **매니페스트가 유일한 진실.** 머신에 손으로 깔지 말고 매니페스트를 고쳐 커밋한다.
- **별 수는 기록하지 않는다.** 금방 낡기 때문에 `stars.sh` 로 실시간 조회한다.
- **필수 의존성은 적게.** 스킬만 설치할 때는 git + Node 22.20+ 만 있으면 된다(Windows PowerShell 포함). 도구까지 깔 때는 bash 와 각 도구의 설치기(npm, uv 등)가 필요하다. jq 는 discover·radar 에만 쓴다.
- **부분 실패 허용.** 하나가 실패해도 나머지는 계속 설치하고, 마지막에 실패 목록을 보여준다.
