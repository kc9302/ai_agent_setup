# CATALOG — 등록된 스킬·도구 상세 설명

`manifest/` 에 등록된 각 항목이 **무엇이고, 왜 넣었고, 설치 후 어떻게 쓰는지** 정리한 문서입니다.
매니페스트에 항목을 추가하면 여기에도 한 절을 추가해 주세요. 별 수는 `bash scripts/stars.sh` 로 확인합니다.

---

## 스킬 (Agent Skills)

Agent Skills 는 `SKILL.md`(YAML frontmatter + 마크다운 지시문) 를 담은 폴더입니다.
에이전트는 skill 의 `description` 을 보고 상황에 맞을 때만 내용을 불러오므로, 많이 설치해도 컨텍스트를 거의 쓰지 않습니다.
설치 위치: Claude Code `~/.claude/skills/`, Codex `~/.codex/skills/`, Cursor `~/.cursor/skills/`, Gemini CLI `~/.gemini/skills/`, OpenCode `~/.config/opencode/skills/` (프로젝트 범위는 `.claude/skills/`, `.agents/skills/`).

### anthropics/skills — Anthropic 공식 스킬
- **무엇**: Anthropic 이 직접 관리하는 공식 스킬 모음. 문서 생성(`docx`, `pdf`, `pptx`, `xlsx`), 스킬 제작 도우미(`skill-creator`), Playwright 기반 웹앱 테스트(`webapp-testing`) 등.
- **왜**: 사실상의 표준 레퍼런스. 문서 산출물(워드/PDF/슬라이드/엑셀)이 필요한 작업에 바로 쓰이고, `skill-creator` 는 우리 스킬을 만들 때 기준이 된다.
- **설치 범위**: `docx, pdf, pptx, xlsx` (문서 산출물), `doc-coauthoring` (사용자와 함께 문서를 단계적으로 공동 작성), `mcp-builder` (MCP 서버 설계·구현 가이드), `frontend-design` (AI 티 안 나는 고품질 프론트엔드), `theme-factory` (테마/컬러 시스템 생성), `canvas-design` (캔버스 기반 시각 디자인), `web-artifacts-builder` (React/Tailwind 단일 파일 웹 아티팩트), `skill-creator`, `webapp-testing`. 나머지(brand-guidelines, slack-gif-creator 등)가 필요하면 `manifest/skills.list` 에 이름 추가.
- **사용 예**: "이 분석 결과를 pptx 로 만들어줘", "새 스킬 하나 만들어줘".

### obra/superpowers — 개발 방법론 프레임워크
- **무엇**: 브레인스토밍 → 계획 → TDD → 코드 리뷰 → 서브에이전트 활용까지, 소프트웨어 개발 **방법론** 자체를 스킬로 묶은 프레임워크. 에이전트가 요청을 받으면 바로 코딩하지 않고 먼저 설계·검증 절차를 밟도록 유도한다.
- **왜**: 가장 널리 쓰이는 스킬 프레임워크. "에이전트가 일하는 방식" 을 표준화하는 토대.
- **사용 예**: 복잡한 기능 요청 시 에이전트가 자동으로 brainstorming/planning 스킬을 꺼내 쓴다. 명시적으로 "superpowers 방식으로 진행해" 라고 해도 됨.

### addyosmani/agent-skills — 프로덕션급 엔지니어링 스킬
- **무엇**: Addy Osmani(Google Chrome 팀) 가 정리한 엔지니어링 실무 스킬 25종. spec-driven development, test-driven development, debugging-and-error-recovery, code-review-and-quality, security-and-hardening, performance-optimization, git-workflow, ci-cd, documentation-and-adrs 등.
- **왜**: superpowers 가 "절차" 라면 이쪽은 "각 단계의 품질 기준". 둘이 보완 관계.
- **사용 예**: "이 PR 리뷰해줘" → code-review-and-quality 스킬 적용. "성능 개선해줘" → performance-optimization.

### forrestchang/andrej-karpathy-skills — LLM 코딩 함정 회피 규칙
- **무엇**: Andrej Karpathy 가 지적한 LLM 코딩의 전형적 실수(과도한 추측, 불필요한 복잡성, 검증 없는 "완료" 선언, 요구 범위 이탈 등) 를 피하도록 하는 행동 규칙. 원래는 `CLAUDE.md` 한 장이었고, 스킬/플러그인 형태로도 제공된다.
- **왜**: 가볍지만 효과가 큰 "행동 교정" 레이어. 어떤 에이전트에나 공통 적용 가능.
- **사용 예**: 설치만 하면 됨. 에이전트가 가정을 먼저 확인하고, 작은 변경을 선호하고, 검증 후에만 완료를 보고하게 된다.

### DietrichGebert/ponytail — 최소주의 시니어 개발자 모드
- **무엇**: "가장 게으른, 그러나 동작하는 해법" 을 강제하는 스킬. 결정 사다리: 기능이 필요한지부터 의심(YAGNI) → 코드베이스 기존 패턴 재사용 → 표준 라이브러리 → 플랫폼 내장 기능 → 이미 설치된 의존성 → 한 줄 해법 → 그제야 새 코드. 강도 조절(lite/full/ultra) 가능.
- **함께 설치됨**: `ponytail-review` (과잉 설계만 잡는 코드 리뷰), `ponytail-audit` (저장소 전체 bloat 감사), `ponytail-debt` (`ponytail:` 주석으로 남긴 보류 사항 장부), `ponytail-gain`, `ponytail-help`.
- **왜**: 에이전트가 쓸데없이 긴 코드와 불필요한 의존성을 만드는 문제를 직접 겨냥한다. 저자 벤치마크 기준 생성 코드량·비용·시간이 모두 줄면서 검증·에러 처리·보안은 유지.
- **사용 예**: 설치만 하면 모든 코딩 작업에 적용. "ponytail 로 이 모듈 리뷰해줘", "/ponytail-audit".

### tt-a1i/archify — 인터랙티브 아키텍처 다이어그램
- **무엇**: 자연어 설명이나 코드(또는 Mermaid) 를 받아 아키텍처·워크플로우·시퀀스·데이터플로우·상태 다이어그램을 **단일 HTML 파일** 로 생성한다. 노드 탐색, 경로 추적(trace) 애니메이션, 다크/라이트 테마, PNG/SVG/WebM 내보내기 지원. 생성된 HTML 은 archify 없이도 어디서나 열린다.
- **왜**: 시스템 설계를 설명·공유할 때 Mermaid 보다 훨씬 보기 좋은 산출물. 저장소 코드를 읽어 **실제 구조를 반영한** 다이어그램을 그릴 수 있다.
- **함께 설치됨**: `archify-review` (archify 저장소의 이슈/PR 리뷰용. 필요 없으면 skills.list 에서 `*` 대신 `archify` 만 지정).
- **사용 예**: "이 저장소 아키텍처를 archify 로 그려줘", "브라우저→API→Redis→Postgres 요청 흐름 시퀀스 다이어그램".

### nextlevelbuilder/ui-ux-pro-max-skill — UI/UX 디자인 인텔리전스
- **무엇**: 디자인 데이터베이스를 내장한 스킬 묶음. `ui-ux-pro-max` 는 79개 스타일, 192개 제품 팔레트, 74개 폰트 페어링, 119개 UX 가이드라인, 아이콘·GSAP 프리셋·차트 타입·22개 스택별 구현 규칙을 검색해 디자인 결정을 내린다.
- **함께 설치됨** (총 7개): `design-system` (primitive→semantic→component 3계층 토큰, 컴포넌트 스펙), `ui-styling` (shadcn/ui + Tailwind, 다크모드, 접근성 컴포넌트), `banner-design` (SNS/광고/히어로/인쇄 배너, 22개 스타일), `slides` (**Chart.js 기반 HTML 발표자료**. 파일 산출물이 필요하면 anthropics `pptx` 와 함께 사용), `brand` (브랜드 보이스·비주얼 아이덴티티), `design` (로고·CIP·아이콘·소셜 이미지 통합).
- **왜**: 에이전트가 만드는 UI 가 "AI 가 만든 티" 나지 않게 하는 데이터 기반 가이드. 프론트엔드·마케팅 자산 양쪽을 덮는다.
- **사용 예**: "이 랜딩 페이지 디자인 리뷰해줘", "SaaS 대시보드용 컬러/폰트 추천", "발표자료 slides 로 만들어줘".

### vercel-labs/agent-skills — React / 웹 가이드라인
- **무엇**: Vercel 이 만든 프론트엔드 스킬. `react-best-practices`(성능·구조 규칙), `web-design-guidelines`(접근성·UX 점검), `composition-patterns`(컴포넌트 합성), `writing-guidelines`(기술 문서 작문).
- **왜**: React/Next.js 프로젝트에서 에이전트가 생성하는 코드 품질을 끌어올린다.
- **설치 범위**: 위 4개만. `vercel-deploy-claimable`, `react-native-guidelines` 등은 제외 (필요하면 추가).

### blader/humanizer — AI 말투 제거 (영어)
- **무엇**: Wikipedia 의 "Signs of AI writing" 을 바탕으로, AI 생성 글의 26가지 패턴("not X but Y" 대조, 한 줄 극적 마무리, "Here's the thing" 류 도입부, 억지 3단 나열, 과도한 대시, 부풀린 어휘, 세일즈 톤, 굵은 라벨 등) 을 찾아 **내용은 바꾸지 않고** 사람이 쓴 글처럼 고친다.
- **왜**: 문서·README·블로그 초안을 에이전트가 쓰면 티가 난다. 블라인드 테스트에서 원문보다 선호됨. 한국어는 별도 스킬(`humanize-korean`) 과 함께 사용.
- **사용 예**: "이 README AI 티 나는 부분 humanizer 로 고쳐줘".

### huggingface/skills — Hugging Face 공식 ML 스킬
- **무엇**: Hugging Face 가 직접 관리하는 스킬. 설치 범위 9개: `hf-cli` (Hub CLI: 모델/데이터셋/Spaces/잡/논문/Inference Endpoints), `huggingface-llm-trainer` (TRL/Unsloth 로 SFT·DPO·GRPO 학습, HF Jobs 클라우드 GPU, GGUF 변환), `huggingface-datasets` (Dataset Viewer API 로 조회·검색·필터·parquet), `huggingface-papers` (HF/arXiv 논문 읽기·메타데이터), `huggingface-gradio` (Gradio UI/데모), `huggingface-trackio` (학습 실험 추적·알림·대시보드), `huggingface-local-models` (llama.cpp/GGUF 로컬 실행, 양자화 선택), `huggingface-community-evals` (inspect-ai/lighteval 로컬 평가), `huggingface-spaces` (Spaces 배포·ZeroGPU·디버깅).
- **왜**: ML 작업을 에이전트에게 맡길 때 Hub 생태계 전반을 정확한 명령으로 다루게 한다.
- **미포함**: SageMaker 계열(`hf-cloud-*`), `huggingface-vision-trainer`, `transformers-js`, `trl-training` 등. 필요 시 `manifest/skills.list` 에 추가.

---

## 도구 (오픈소스 CLI / MCP 서버)

`manifest/tools.list` 의 `check` 명령이 성공하면 설치를 건너뛰고, 실패하면 `install` 을 실행합니다.

### skills — Agent Skills 설치 CLI
- **무엇**: [skills.sh](https://skills.sh) 의 공식 CLI(`npx skills`). `add / find / list / update / remove` 로 스킬을 관리하고, Claude Code·Codex·Cursor·Gemini CLI·OpenCode 등 75+ 에이전트의 스킬 디렉터리를 자동 감지한다.
- **왜**: 이 저장소의 `bootstrap.sh` 가 스킬 설치에 사용하는 핵심 도구. 전역 설치해 두면 `npx` 다운로드 없이 바로 실행된다.
- **사용 예**: `skills find typescript`, `skills list -g`, `skills update -g`.

### agent-browser — 에이전트용 브라우저 자동화 CLI
- **무엇**: Vercel Labs 의 Rust 기반 헤드리스 브라우저 CLI. 페이지를 열고 요소를 ref 로 지정해 클릭·입력·스크린샷을 수행한다. 에이전트가 셸에서 직접 호출하기 좋게 설계됨.
- **왜**: 웹앱 동작 확인, 스크래핑, E2E 점검을 MCP 없이 CLI 만으로 처리할 수 있다.
- **사용 예**: `agent-browser open https://example.com`, `agent-browser snapshot`, `agent-browser click @e3`.

### uv — Python 패키지/도구 관리자
- **무엇**: Astral 의 초고속 Python 패키지 관리자. `uv tool install` 로 Python CLI 를 격리 설치한다(pipx 대체).
- **왜**: LEANN 등 Python 기반 도구의 전제 조건. 설치 경로는 `~/.local/bin`.

### LEANN — 저장공간 97% 절감 로컬 벡터 DB / 시맨틱 검색
- **저장소**: https://github.com/StarTrail-org/LEANN
- **무엇**: 노트북에서도 수백만 문서를 **시맨틱 검색·RAG** 할 수 있는 벡터 데이터베이스. 임베딩을 전부 저장하지 않고 그래프 기반 **선택적 재계산**(graph-based selective recomputation) 으로 필요할 때만 계산해, 기존 벡터 DB 대비 저장공간을 약 97% 줄이면서 정확도를 유지한다 (예: 6천만 청크 → 201GB 대신 6GB).
- **대상 데이터**: 코드 저장소, 문서 폴더, 이메일, 브라우저 히스토리, 채팅 기록(WeChat/iMessage/ChatGPT/Claude), Slack 등.
- **왜**: 에이전트가 큰 코드베이스를 grep 대신 **의미 기반**으로 검색할 수 있게 해 준다. 공개 벤치마크(SWE-Bench Pro) 에서 키워드 검색 대비 초기 관련 코드 recall 약 2배. 모든 처리가 로컬이라 데이터가 외부로 나가지 않는다.
- **설치**: `uv tool install leann-core --with leann` (tools.list 가 수행). 소스 빌드/DiskANN 백엔드 등 고급 옵션은 저장소 README 참고.
- **사용 예**:
  ```bash
  leann build my-code --docs ./src          # 인덱스 생성
  leann search my-code "where is auth handled"
  leann ask my-code --interactive           # 로컬 LLM 과 RAG 대화
  leann list / leann remove my-code
  ```

### leann-mcp — LEANN 을 Claude Code MCP 서버로 등록
- **무엇**: LEANN 이 제공하는 MCP 서버(`leann_mcp`) 를 `claude mcp add --scope user leann-server -- leann_mcp` 로 등록한다. 등록 후 Claude Code 는 `leann-server` 도구로 코드베이스를 시맨틱 검색한다.
- **왜**: CLI 로 사람이 검색하는 것과 별개로, **에이전트가 스스로** 관련 코드를 찾게 하는 것이 목적.
- **동작 조건**: `claude` CLI 가 없으면 건너뛴다(실패로 치지 않음). 다른 에이전트(Codex/Cursor) 에서 쓰려면 해당 도구의 MCP 설정에 `leann_mcp` 를 직접 추가.
- **사용 예**: 프로젝트에서 `leann build <name> --docs .` 로 인덱스를 만든 뒤 Claude Code 에게 "leann 으로 결제 로직 찾아줘".

### markitdown — 문서 → Markdown 변환 CLI
- **저장소**: https://github.com/microsoft/markitdown
- **무엇**: PDF, Word, PowerPoint, Excel, HTML, 이미지(OCR/EXIF), 오디오(음성 전사), ZIP, YouTube URL 등을 LLM 이 읽기 좋은 Markdown 으로 바꾼다. 표·제목 구조를 보존.
- **왜**: 에이전트에게 사내 문서를 읽히려면 먼저 텍스트로 만들어야 한다. LEANN 인덱싱 전처리로도 쓸 수 있다.
- **설치**: `uv tool install 'markitdown[all]'` (tools.list 가 수행). `markitdown-mcp` MCP 서버 패키지도 있으나 CLI 만 등록.
- **사용 예**: `markitdown report.pdf -o report.md`, `markitdown deck.pptx > deck.md`.

### context7-mcp — 최신 공식 문서 MCP
- **저장소**: https://github.com/upstash/context7
- **무엇**: 에이전트가 라이브러리 이름을 말하면 **버전에 맞는 최신 공식 문서와 코드 예제**를 가져오는 MCP 서버. 학습 데이터에 없는 API 나 낡은 사용법 때문에 생기는 환각을 줄인다.
- **설치**: `claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp` (claude CLI 없으면 건너뜀). API 키 없이 동작하며, 키가 있으면 rate limit 이 완화된다.
- **사용 예**: 프롬프트에 "use context7" 을 붙이거나, 에이전트가 자동으로 호출.

### playwright-mcp — 브라우저 조작 MCP
- **저장소**: https://github.com/microsoft/playwright-mcp
- **무엇**: 에이전트가 실제 브라우저(Chromium 등) 를 열고 접근성 트리 기반으로 클릭·입력·탐색·스크린샷을 수행하는 MCP 서버. 스크린샷 대신 구조화된 스냅샷을 쓰므로 비전 모델 없이도 동작.
- **왜**: 웹앱 E2E 검증, 폼 테스트, 스크래핑을 에이전트가 직접 수행. CLI 인 `agent-browser` 와 역할이 겹치며, MCP 를 쓰는 에이전트는 이쪽, 셸 중심이면 agent-browser.
- **설치**: `claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest` (claude CLI 없으면 건너뜀).
