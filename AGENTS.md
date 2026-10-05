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
| `manifest/skills.list` | 설치할 Agent Skills 저장소 목록 (`owner/repo#커밋 \| skills \| tags \| 설명`) |
| `manifest/tools.list`  | 설치할 오픈소스 도구 목록 (`name \| check \| install \| tags \| 설명`) |
| `bootstrap.sh`         | 매니페스트대로 전부 설치하는 진입점 |
| `scripts/stars.sh`     | 등록된 저장소의 GitHub 별 수 실시간 조회 |
| `scripts/discover.sh`  | 별이 많은 새 스킬 저장소 탐색 (매니페스트에 없는 것만 표시) |
| `scripts/validate.sh`  | 매니페스트/스크립트 형식 검사. 고정되지 않은 소스는 오류. 커밋 전 필수 |
| `scripts/pin.sh`       | 스킬 소스를 커밋에 고정(`--fill`)하고 올린다(`--update`). 인자 없이 실행하면 비교표만 출력 |
| `scripts/verify.sh`    | 정의한 스킬이 이 환경에 **실제로 전부** 설치됐는지 확인 (설치는 하지 않음) |
| `scripts/status.sh`    | 현재 환경의 설치 상태 |
| `scripts/export-swarm-forecast.sh` | `swarm-forecast` 를 독립 저장소 형태(README·LICENSE·테스트·CI 포함)로 내보낸다. 원본은 `skills/swarm-forecast/`, 테스트·README 원본은 `packaging/swarm-forecast/` |
| `skills/`              | 이 저장소 자체가 정의한 로컬 스킬. `bootstrap.sh` 가 클론한 저장소에서 바로 설치한다 (`ai-setup-sync`, 고정 사본 `web-design-guidelines`, 시뮬레이션 방법론 `swarm-forecast`) |
| `CATALOG.md`           | 등록된 각 스킬·도구가 무엇이고 왜 넣었는지, 사용법 상세 설명 |

## 새 스킬/도구를 추가할 때

1. `bash scripts/discover.sh [키워드]` 로 후보를 찾는다. 별 수, 최근 push 날짜, 설명을 본다.
2. `manifest/skills.list` 에 한 줄 추가한다. 저장소의 일부 스킬만 원하면 `*` 대신 이름을 쉼표로 나열한다.
   **이름은 폴더 이름이 아니라 `SKILL.md` 의 `name:` 값**이다(예: 폴더 `react-best-practices` 의 이름은 `vercel-react-best-practices`).
   틀리면 skills CLI 가 오류 없이 건너뛴다. `npx skills add owner/repo --list` 로 이름을 확인한다.
3. `bash scripts/pin.sh --fill` 로 커밋에 고정한다. **스킬 내용을 읽고** 확인한 커밋인지 본다(스킬은 에이전트가 따르는 지시문이다).
4. `bash scripts/validate.sh` 가 통과해야 한다.
5. `bash bootstrap.sh --dry-run` 으로 실행될 명령을 확인하고, 실제 설치까지 해 본다. 설치 후 `bootstrap.sh` 가 이름으로 지정한 스킬이
   전부 설치됐는지 스스로 검증한다. 설치 없이 다시 확인하려면 `bash scripts/verify.sh`.
6. `CATALOG.md` 에 "무엇 / 왜 / 사용 예" 절을 추가한다.
7. 커밋 메시지에 **왜** 추가했는지 적는다 (예: 별 50k+, 아키텍처 다이어그램 용도).

## 스킬을 올릴 때 (고정 갱신)

```bash
bash scripts/pin.sh                       # 고정한 커밋과 upstream 최신을 비교 (수정 없음)
bash scripts/pin.sh --update owner/repo   # 한 소스를 최신으로 올림. 비교 링크가 출력된다
```
출력된 비교 링크에서 **바뀐 내용을 읽은 뒤** 받아들인다. 읽지 않고 `--update` 만 반복하면 고정의 의미가 없다.

## 하지 말 것

- 매니페스트에 별 수를 하드코딩하지 않는다. 금방 낡는다. `scripts/stars.sh` 가 실시간으로 보여준다.
- `tools.list` 의 `install` 은 그대로 셸에서 실행된다. 출처가 불분명한 명령은 넣지 않는다.
- 머신에 직접 설치하고 끝내지 않는다. 매니페스트를 고쳐 커밋해야 다른 환경에도 반영된다.
- 스킬 소스를 고정하지 않은 채 두지 않는다. 최신 `main` 을 받으면 클론한 시점마다 설치되는 내용이 달라진다.
- 실행할 때마다 원격 파일을 내려받아 지시문으로 쓰는 스킬은 그대로 넣지 않는다. 고정한 사본을 `skills/` 에 두고(예: `web-design-guidelines`), `SOURCE.md` 에 출처 커밋과 해시를 적는다.
- 설치 명령이 성공했다고 스킬이 설치됐다고 믿지 않는다. `verify.sh` 로 확인한다.
- 선행 조건(예: Node 버전)이 맞지 않아 설치할 수 없는 도구를 실패로 처리하지 않는다. `tools.list` 의 `install` 이 사유를 stderr 에 출력하고
  **종료 코드 75** 로 끝나게 하면 `bootstrap.sh` 가 "건너뜀"으로 보고한다(예: `paperclipai`). 그 밖의 0 이 아닌 코드는 실패다.
