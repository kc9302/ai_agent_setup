---
name: ai-setup-sync
description: Sync this machine's AI agent setup (skills + open-source tools) from the kc9302/ai_agent_setup manifest. Use when the user asks to set up, sync, update, or replicate their AI tool environment, or mentions ai_agent_setup, "내 세팅", "스킬 동기화", "환경 똑같이".
---

# ai-setup-sync

이 스킬은 `kc9302/ai_agent_setup` 저장소를 **단일 진실 공급원(source of truth)** 으로 삼아,
어떤 머신·어떤 AI 코딩 도구에서도 동일한 스킬/도구 세트를 갖추게 한다.

## 언제 쓰나
- 새 머신, 새 컨테이너, 새 AI 도구(Claude Code, Codex, Cursor, Gemini CLI, OpenCode …)를 처음 쓸 때
- "내 스킬 세팅 맞춰줘", "ai_agent_setup 동기화", "최신 스킬로 업데이트" 같은 요청
- 매니페스트에 새 스킬을 추가하고 싶을 때

## 절차

### 1. 설치 / 동기화
```bash
# 저장소가 없으면 클론하고, 있으면 main 최신으로 맞춘다 (clone 실패를 무시하고 오래된 사본으로 설치하지 않도록)
git clone --depth 1 --branch main https://github.com/kc9302/ai_agent_setup.git ~/.ai_agent_setup 2>/dev/null \
  || { git -C ~/.ai_agent_setup fetch --depth 1 origin main && git -C ~/.ai_agent_setup reset --hard FETCH_HEAD; }

bash ~/.ai_agent_setup/bootstrap.sh            # 전역 설치 (기본)
bash ~/.ai_agent_setup/bootstrap.sh --project  # 현재 프로젝트에만
```
클론이 불가능하면 한 줄로: `curl -fsSL https://raw.githubusercontent.com/kc9302/ai_agent_setup/main/bootstrap.sh | bash`

- `node`/`npx` 가 없으면 먼저 Node.js 18+ 를 설치한다.
- 특정 에이전트만: `--agent claude-code` (여러 번 가능). 자동 감지에 맡기는 것이 기본.
- 실패한 항목은 마지막에 목록으로 출력된다. 하나가 실패해도 나머지는 계속 진행된다.

### 2. 상태 확인
```bash
bash ~/.ai_agent_setup/scripts/status.sh
```

### 3. 새 스킬 추가 (사용자가 요청할 때만)
1. 후보 찾기: `bash scripts/discover.sh [키워드]` 또는 `bash scripts/stars.sh`
2. `manifest/skills.list` 에 한 줄 추가: `owner/repo | * | tags | 설명`
   - 저장소 전체가 아니라 일부 스킬만 원하면 `*` 대신 `skill-a,skill-b`
3. `bash scripts/validate.sh` 통과 확인
4. `bash bootstrap.sh` 로 실제 설치되는지 확인한 뒤 커밋

### 4. 오픈소스 도구 추가
`manifest/tools.list` 에 `name | check | install | tags | 설명` 형식으로 추가.
`check` 는 설치 여부를 판단하는 명령(종료코드 0 = 설치됨), `install` 은 설치 명령.

## 원칙
- 매니페스트가 유일한 진실이다. 머신마다 손으로 설치하지 말고 매니페스트를 고쳐 커밋한다.
- 별 수(인기도)는 매니페스트에 적지 않는다. `scripts/stars.sh` 로 실시간 조회한다.
- `tools.list` 의 install 명령은 그대로 셸에서 실행되므로, 신뢰할 수 있는 출처만 추가한다.
