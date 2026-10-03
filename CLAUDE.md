# CLAUDE.md

이 저장소의 에이전트 안내는 `AGENTS.md` 에 있다. 먼저 그 파일을 읽어라.

요약:
- 새 환경 세팅 요청이면 `bash bootstrap.sh` 를 실행하고 `bash scripts/status.sh` 로 확인한다.
- 매니페스트(`manifest/*.list`)를 고쳤으면 커밋 전에 `bash scripts/validate.sh` 를 통과시킨다.
- 별 수는 하드코딩하지 않는다. `scripts/stars.sh` / `scripts/discover.sh` 를 쓴다.
