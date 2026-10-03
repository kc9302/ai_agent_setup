# AGENTS.md — AI 에이전트를 위한 안내

이 저장소는 **AI 코딩 도구용 스킬과 오픈소스 도구를 한곳에 모아두는 매니페스트**다.
목적은 단 하나: 어떤 환경에서 어떤 AI 도구를 쓰든, 이 저장소만 보면 **똑같은 세팅**이 자동으로 갖춰지는 것.

## 이 저장소를 열었다면 가장 먼저 할 일

사용자가 "세팅해줘", "스킬 설치해줘", "환경 맞춰줘" 류의 요청을 했거나,
새 환경에서 이 저장소를 처음 열었다면 아래를 실행한다:

```bash
bash bootstrap.sh            # 전역 설치 (기본). 스킬 + 도구 모두
bash scripts/status.sh       # 설치 결과 확인
```

- Node.js 18+ 와 git 이 필요하다. 없으면 먼저 설치한다.
- 스킬은 `npx skills add` 로 설치되며 Claude Code / Codex / Cursor / Gemini CLI / OpenCode 등을 자동 감지한다.
- 실패한 항목은 요약에 나온다. 전체를 멈추지 말고 실패한 것만 보고한다.

## 저장소 구조

| 경로 | 역할 |
|---|---|
| `manifest/skills.list` | 설치할 Agent Skills 저장소 목록 (`owner/repo \| skills \| tags \| 설명`) |
| `manifest/tools.list`  | 설치할 오픈소스 도구 목록 (`name \| check \| install \| tags \| 설명`) |
| `bootstrap.sh`         | 매니페스트대로 전부 설치하는 진입점 |
| `scripts/stars.sh`     | 등록된 저장소의 GitHub 별 수 실시간 조회 |
| `scripts/discover.sh`  | 별이 많은 새 스킬 저장소 탐색 (매니페스트에 없는 것만 표시) |
| `scripts/validate.sh`  | 매니페스트/스크립트 형식 검사. 커밋 전 필수 |
| `scripts/status.sh`    | 현재 환경의 설치 상태 |
| `skills/`              | 이 저장소 자체가 제공하는 로컬 스킬 (`npx skills add kc9302/ai_agent_setup`) |
| `CATALOG.md`           | 등록된 각 스킬·도구가 무엇이고 왜 넣었는지, 사용법 상세 설명 |

## 새 스킬/도구를 추가할 때

1. `bash scripts/discover.sh [키워드]` 로 후보를 찾는다. 별 수, 최근 push 날짜, 설명을 본다.
2. `manifest/skills.list` 에 한 줄 추가한다. 저장소의 일부 스킬만 원하면 `*` 대신 이름을 쉼표로 나열한다.
3. `bash scripts/validate.sh` 가 통과해야 한다.
4. `bash bootstrap.sh --dry-run` 으로 실행될 명령을 확인하고, 가능하면 실제 설치까지 해 본다.
5. `CATALOG.md` 에 "무엇 / 왜 / 사용 예" 절을 추가한다.
6. 커밋 메시지에 **왜** 추가했는지 적는다 (예: 별 50k+, 아키텍처 다이어그램 용도).

## 하지 말 것

- 매니페스트에 별 수를 하드코딩하지 않는다. 금방 낡는다. `scripts/stars.sh` 가 실시간으로 보여준다.
- `tools.list` 의 `install` 은 그대로 셸에서 실행된다. 출처가 불분명한 명령은 넣지 않는다.
- 머신에 직접 설치하고 끝내지 않는다. 매니페스트를 고쳐 커밋해야 다른 환경에도 반영된다.
