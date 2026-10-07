# CATALOG — 등록된 스킬·도구 상세 설명

`manifest/` 에 등록된 각 항목이 **무엇이고, 왜 넣었고, 설치 후 어떻게 쓰는지** 정리한 문서입니다.
매니페스트에 항목을 추가하면 여기에도 한 절을 추가해 주세요. 별 수는 `bash scripts/stars.sh` 로 확인합니다.

---

## 스킬 (Agent Skills)

Agent Skills 는 `SKILL.md`(YAML frontmatter + 마크다운 지시문) 를 담은 폴더입니다.
에이전트는 skill 의 `description` 을 보고 상황에 맞을 때만 내용을 불러오므로, 많이 설치해도 컨텍스트를 거의 쓰지 않습니다.
설치 위치: Claude Code `~/.claude/skills/`, Codex `~/.codex/skills/`, Cursor `~/.cursor/skills/`, Gemini CLI `~/.gemini/skills/`, OpenCode `~/.config/opencode/skills/` (프로젝트 범위는 `.claude/skills/`, `.agents/skills/`).


### 설치 안정화 — 어느 환경에서나 같은 스킬

이 저장소의 목적은 **클론하면 우리가 정의한 스킬이 모든 환경에 똑같이 설치되는 것**이다. 그래서 세 가지를 지킨다.

- **소스를 커밋에 고정한다.** `skills.list` 의 소스는 `owner/repo#<40자리 커밋>` 형식이다. 고정하지 않으면 클론한 시점의 최신 `main` 이 설치돼 환경과 시간에 따라 달라진다. 고정은 `bash scripts/pin.sh --fill`, 올릴 때는 `bash scripts/pin.sh --update owner/repo` 이고 비교 링크가 출력된다. 고정한 커밋은 **고정한 날(2026-10-05)의 upstream 최신**이며, 각 스킬을 처음 검토한 시점의 커밋과 다를 수 있다. 올릴 때마다 바뀐 내용을 읽는다(스킬은 에이전트가 따르는 지시문이다). `validate.sh` 는 고정되지 않은 소스를 오류로 처리한다.
- **설치 후 실제로 설치됐는지 검증한다.** skills CLI 는 `--skill` 을 폴더 이름이 아니라 `SKILL.md` 의 `name:` 값으로 찾고, 맞지 않는 이름은 **오류 없이 건너뛴 채 종료 코드 0** 으로 끝난다(예: `vercel-labs/agent-skills` 에서 4개 중 2개가 조용히 빠졌다). `bootstrap.sh` 는 설치 뒤 `skills ls --json` 과 대조해 이름으로 지정한 스킬이 하나라도 없으면 실패로 보고한다. 와일드카드(`*`) 소스는 스킬이 1개 이상 있는지 본다. 설치 없이 현재 환경만 점검하려면 `bash scripts/verify.sh [--project] [--agent …] [--tag …]`. 도구(`tools.list`)가 설치하는 스킬은 각 도구의 check 로 확인한다.
- **이 저장소의 스킬도 함께 설치한다.** `skills/` 의 스킬(`ai-setup-sync`, `web-design-guidelines`)은 `bootstrap.sh` 가 클론한 저장소에서 바로 설치한다(로컬 경로 설치는 파일을 복사하므로 임시 클론이 지워져도 남는다). 클론이 곧 고정이다.
- **알려진 한계**: 도구(`tools.list`)가 설치하는 스킬은 이 고정 방식이 아니라 각 도구의 방식을 따른다. `officecli` 는 바이너리 버전에, `im-not-ai`(스킬 `humanize-korean`)는 커밋에 묶여 있다. 도구 자체(`tools.list`)는 npm `@버전`·uv `==버전`·git 커밋·해시 확인한 스크립트로 고정하고, 설치기가 쓰는 skills CLI 는 `manifest/skills-cli.version` 으로 고정한다(`validate.sh` 가 강제). 고정되지 않는 것은 고정한 패키지의 전이 의존성이고, 업스트림이 고정한 버전·커밋을 지워도 아직 감시하지 않는다.

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

### mattpocock/skills — 설계 검증·인수인계 (선별 4개)
- **무엇**: Matt Pocock 의 스킬 37개 중 superpowers·addyosmani 와 겹치지 않는 4개만. `grill-me`(질문을 집요하게 던져 설계의 빈틈을 드러냄), `handoff`(세션을 다음 세션/사람에게 넘길 요약 작성), `to-spec`(대화를 스펙 문서로 정리), `writing-for-agents`(스킬·AGENTS.md·CLAUDE.md 를 에이전트가 잘 읽게 쓰는 법).
- **왜**: 방법론은 superpowers, 체크리스트는 addyosmani 가 이미 담당. 이쪽은 "대화 → 스펙", "세션 간 인계" 의 빈 곳을 채운다.
- **제외한 것**: `tdd`, `diagnosing-bugs`, `code-review` 등은 기존 스킬과 중복. `git-guardrails-claude-code` 는 확인 시점에 저장소에 없었다.

### cathrynlavery/diagram-design — 편집 디자인 다이어그램
- **무엇**: 아키텍처·플로우차트·시퀀스·ER·타임라인·간트·Sankey·Wardley map·org chart 등 42종을 HTML/SVG/PNG 로 생성. 웹사이트를 분석해 브랜드 색상·폰트를 반영하고, draw.io·Mermaid·Excalidraw 파일을 가져와 다시 그린다.
- **archify 와의 차이**: archify 는 "스키마 검증되는 구조도 + 경로 추적 애니메이션", 이쪽은 "발표·문서에 넣을 보기 좋은 그림". 용도가 달라 둘 다 둔다.

### Leonxlnx/taste-skill — 반(反) AI 슬롭 프론트엔드 (1개만)
- **무엇**: 13개 스킬 중 기본 `design-taste-frontend` 만. 브리프를 읽고 디자인 방향을 추론한 뒤, 템플릿 같지 않은 UI 를 만들고 사전 점검(pre-flight)을 거친다. 리디자인 시에는 먼저 감사한다.
- **왜 1개**: ui-ux-pro-max, frontend-design 과 취향이 겹쳐서 하나만 얹는다. `redesign-existing-projects`, `minimalist-ui`, `brandkit` 등은 필요할 때 skills.list 에 이름 추가.

### vercel-labs/agent-skills — React / 웹 가이드라인
- **무엇**: Vercel 이 만든 프론트엔드 스킬. `vercel-react-best-practices`(성능·구조 규칙), `vercel-composition-patterns`(컴포넌트 합성), `writing-guidelines`(기술 문서 작문). (주의: skills CLI 는 `--skill` 을 폴더 이름이 아니라 `SKILL.md` 의 `name:` 값으로 찾는다. 이름이 어긋나면 오류 없이 일부만 설치된다.)
- **왜**: React/Next.js 프로젝트에서 에이전트가 생성하는 코드 품질을 끌어올린다.
- **설치 범위**: 위 3개만 (`web-design-guidelines` 는 아래 "고정 사본" 참고). `vercel-deploy-claimable`, `react-native-guidelines` 등은 제외 (필요하면 추가).

### blader/humanizer — AI 말투 제거 (영어)
- **무엇**: Wikipedia 의 "Signs of AI writing" 을 바탕으로, AI 생성 글의 26가지 패턴("not X but Y" 대조, 한 줄 극적 마무리, "Here's the thing" 류 도입부, 억지 3단 나열, 과도한 대시, 부풀린 어휘, 세일즈 톤, 굵은 라벨 등) 을 찾아 **내용은 바꾸지 않고** 사람이 쓴 글처럼 고친다.
- **왜**: 문서·README·블로그 초안을 에이전트가 쓰면 티가 난다. 블라인드 테스트에서 원문보다 선호됨. 한국어는 별도 항목 `im-not-ai`(스킬 `humanize-korean`, 아래 도구 절)와 함께 사용.
- **사용 예**: "이 README AI 티 나는 부분 humanizer 로 고쳐줘".

### huggingface/skills — Hugging Face 공식 ML 스킬
- **무엇**: Hugging Face 가 직접 관리하는 스킬. 설치 범위 9개: `hf-cli` (Hub CLI: 모델/데이터셋/Spaces/잡/논문/Inference Endpoints), `huggingface-llm-trainer` (TRL/Unsloth 로 SFT·DPO·GRPO 학습, HF Jobs 클라우드 GPU, GGUF 변환), `huggingface-datasets` (Dataset Viewer API 로 조회·검색·필터·parquet), `huggingface-papers` (HF/arXiv 논문 읽기·메타데이터), `huggingface-gradio` (Gradio UI/데모), `huggingface-trackio` (학습 실험 추적·알림·대시보드), `huggingface-local-models` (llama.cpp/GGUF 로컬 실행, 양자화 선택), `huggingface-community-evals` (inspect-ai/lighteval 로컬 평가), `huggingface-spaces` (Spaces 배포·ZeroGPU·디버깅).
- **왜**: ML 작업을 에이전트에게 맡길 때 Hub 생태계 전반을 정확한 명령으로 다루게 한다.
- **미포함**: SageMaker 계열(`hf-cloud-*`), `huggingface-vision-trainer`, `transformers-js`, `trl-training` 등. 필요 시 `manifest/skills.list` 에 추가.

### trailofbits/skills — 보안 리뷰·테스트 (선별 4개)
- **무엇**: 보안 감사 회사 Trail of Bits 의 스킬 85개 중 범용 4개. `differential-review`(변경분 보안 리뷰: 코드 규모에 맞춰 분석 깊이를 조절하고 git blame 으로 맥락을 보며 영향 범위를 계산), `sharp-edges`(오용하기 쉬운 API·위험한 설정·footgun 설계 탐지), `property-based-testing`(Hypothesis·fast-check·proptest 등으로 속성 기반 테스트 작성·점검), `semgrep-rule-creator`(Semgrep 커스텀 룰 작성).
- **왜**: 내장 `/security-review` 와 `security-and-hardening` 이 일반 점검이라면, 이쪽은 "변경분 중심 리뷰"와 "API 설계 단계의 오용 방지"를 따로 다룬다. 4개 모두 마크다운 문서와 템플릿뿐이고 스크립트는 없다.
- **미포함**: 블록체인 감사(`building-secure-contracts`), 퍼징(`testing-handbook-skills`), C/Rust 전용 리뷰 등 특수 목적 다수. `modern-python` 은 세션 시작 시 pip/python 명령을 가로채는 hook 을 함께 제공해서 제외. `second-opinion`, `code-improver` 는 외부 CLI 를 호출하므로 제외.
- **라이선스**: CC BY-SA 4.0. 설치해서 쓰는 것은 자유롭지만, 내용을 이 저장소에 복사해 넣지는 않는다.
- **사용 예**: "이 PR 을 differential-review 로 봐줘", "이 설정 스키마에서 sharp-edges 찾아줘".

### muratcankoylan/Agent-Skills-for-Context-Engineering — 컨텍스트 엔지니어링 (선별 9개)
- **무엇**: 컨텍스트 윈도우를 다루는 이론과 실무를 스킬로 묶은 저장소(MIT)에서 9개. `context-fundamentals`(컨텍스트 구조·어텐션), `context-degradation`(lost-in-middle·오염·충돌 진단), `context-compression`(요약·압축·인수인계), `context-optimization`(예산·KV 캐시·토큰 절감), `multi-agent-patterns`(컨텍스트 격리·감독자/스웜·핸드오프), `memory-systems`(세션 간 기억·엔티티 추적), `tool-design`(에이전트가 고르기 쉬운 도구 설명·스키마), `filesystem-context`(파일 기반 스크래치패드·도구 출력 오프로딩), `evaluation`(에이전트 평가·회귀 스위트·품질 게이트).
- **왜**: 긴 세션에서 품질이 떨어지는 원인을 진단하고, 서브에이전트·MCP 도구를 설계할 때 근거로 삼을 수 있다. addyosmani 의 `context-engineering` 이 "프로젝트에 규칙 파일 세팅하기"라면 이쪽은 "컨텍스트가 왜 열화되고 어떻게 줄이는가"에 가깝다.
- **설치 주의**: 저장소 루트에 `SKILL.md` 가 있어 CLI 가 기본으로는 하위 스킬을 찾지 못한다. 그래서 `skills.list` 태그에 `full-depth` 를 두었고, `bootstrap.sh` 가 이 태그가 있는 항목에만 `--full-depth` 를 붙인다.
- **스크립트**: 스킬마다 파이썬 데모 스크립트가 있다. 점검 결과 표준 라이브러리 위주(일부 `tiktoken`, `numpy`)이고 네트워크·프로세스 실행·환경 변수 접근은 없다. `filesystem_context.py` 의 `rmtree` 는 데모 실행 시 현재 폴더의 `demo_scratch` 만 지운다. 에이전트가 자동 실행하지는 않는다.
- **미포함**: `advanced-evaluation`, `bdi-mental-states`, `harness-engineering`, `hosted-agents`, `latent-briefing`, `long-horizon-prompting`, `project-development`, `self-improvement-loops`, `self-managed-context` 와 `examples/`. 필요 시 추가.
- **사용 예**: "이 세션 컨텍스트가 왜 흐려졌는지 context-degradation 으로 진단해줘".

### hamelsmu/evals-skills — LLM 평가 (7개 전체)
- **무엇**: Hamel Husain(MIT) 의 LLM 파이프라인 평가 스킬. `error-analysis`(트레이스를 읽고 실패 유형 분류), `generate-synthetic-data`(차원 조합으로 다양한 테스트 입력 생성), `write-judge-prompt`(LLM-as-Judge 설계), `validate-evaluator`(사람 라벨로 심판의 TPR/TNR 보정), `evaluate-rag`(검색·생성 품질 평가), `build-review-interface`(트레이스 주석용 브라우저 UI), `eval-audit`(기존 평가 체계의 허점 점검).
- **왜**: `huggingface-community-evals` 가 모델 벤치마크 실행이라면 이쪽은 "내 LLM 앱을 어떻게 평가할까"의 방법론이다. 마크다운만 있고 스크립트는 없다.
- **사용 예**: "우리 RAG 챗봇 평가 체계를 eval-audit 으로 점검해줘".

### addyosmani/web-quality-skills — 웹 품질 (6개 전체)
- **무엇**: Lighthouse 관점의 웹 품질 스킬(MIT). `accessibility`(WCAG 2.2 점검·개선), `core-web-vitals`(LCP·INP·CLS 를 필드/랩 증거로 개선), `performance`(로딩 속도), `seo`(메타 태그·구조화 데이터·사이트맵), `best-practices`(보안·호환성·코드 품질), `web-quality-audit`(위 다섯 가지와 에이전트 브라우징까지 묶은 증거 기반 통합 감사). 통합 감사에는 HTML 소스를 `grep` 으로 훑는 읽기 전용 `analyze.sh` 가 딸려 있다.
- **왜**: 같은 저자의 `performance-optimization` 이 백엔드·DB 까지 다루는 범용 스킬이라면, 이쪽은 웹 페이지의 접근성·SEO·Core Web Vitals 를 직접 다룬다. 접근성과 SEO 는 기존 목록에 없던 영역.
- **사용 예**: "이 사이트 web-quality-audit 으로 감사해줘", "LCP 가 느린 원인 찾아줘".

### cloudflare/security-audit-skill — 코드베이스 보안 감사
- **무엇**: Cloudflare 가 공개한 보안 감사 스킬 1개(MIT). 정찰 → 공격 유형별 탐색(웹·인증, 프로토콜·RPC, 클라이언트, 클라우드·배포, 공급망, 메모리 안전, 데이터 격리, 자원 고갈, AI·LLM 등 영역별 체크리스트) → 검증 → `findings.json` 보고서 순으로 진행한다. 보고서를 스키마로 검사하는 `validate-findings.cjs`, 점검 범위를 기록하는 `validate-coverage-ledger.cjs` 가 함께 설치된다.
- **왜**: `security-review`(변경분 점검), Trail of Bits 스킬(변경분 리뷰·API 오용 탐지) 과 달리 **저장소 전체**를 체계적으로 훑고 확정/검증 필요/기각을 구분해 보고하는 절차를 제공한다.
- **스크립트**: 두 검증 스크립트는 Node 내장 모듈(`fs`, `path`, `util`)만 쓰고 네트워크·프로세스 실행·환경 변수 접근이 없다. 인자로 받은 파일이 일반 파일이 아니면 거부한다. 에이전트가 자동 실행하는 것은 아니고, 스킬 지침에 따라 보고서를 검증할 때 쓴다.
- **사용 예**: "이 저장소 security-audit 으로 감사하고 findings.json 으로 정리해줘".

### emilkowalski/skills — UI 마감·모션 (선별 5개)
- **무엇**: Emil Kowalski(MIT) 의 스킬 14개 중 웹 프론트엔드용 5개. `emil-design-eng`(UI 마감·컴포넌트·애니메이션 판단의 철학), `animate`(애니메이션 필요성·목적·도구 순서로 설계), `review-animations`(모션 코드를 높은 기준으로 리뷰), `break-ui`(긴 이름·빈 데이터·거대한 숫자 등 최악의 데이터로 UI 를 깨보기), `animation-vocabulary`("팝오버 열릴 때 통통 튀는 그거" → 정확한 용어).
- **왜**: `ui-ux-pro-max`, `taste-skill` 이 방향과 시스템을 잡는 쪽이라면 이쪽은 모션과 디테일 마감을 다룬다. 스크립트는 없고 외부 명령 실행 지시도 없다.
- **미포함**: `write-swift`, `animate-expo`, `mobile-native`(모바일 전용), `ask-sonner`, `pick-ui-library`(특정 라이브러리), `prototype`, `apple-design`, `find-animation-opportunities`, `improve-animations`. 필요 시 추가.
- **사용 예**: "이 모달 애니메이션 review-animations 로 봐줘", "이 카드 목록 break-ui 로 깨봐줘".

### opendataloader-project/opendataloader-pdf — PDF 추출 절차 (스킬 1개, 런타임은 별도)
- **무엇**: `opendataloader-pdf`(ODL, Apache-2.0)가 PDF 를 Markdown·JSON(요소별 bbox)·HTML 로 추출하는 도구이고, 이 항목은 그 저장소의 스킬 `odl-pdf` **1개만** 설치한다. 스킬은 옵션 목록이 아니라 **절차**다: 설치된 도구의 `--help` 를 먼저 읽고, 목표에 맞는 최소 명령을 만들고, **종료 코드 0 이 곧 추출 성공이 아니라는 전제**로 결과를 검증하며, 도구가 보고하지 않는 조용한 실패(표·OCR 누락 등)를 진단한다. 옵션 이름을 스킬이 고정하지 않고 런타임에 발견하게 해 버전이 바뀌어도 낡지 않는다. 포함 스크립트 4개: `detect-env.sh`(환경 감지), `hybrid-health.sh`(로컬 하이브리드 서버 상태 확인, 기본 `localhost:5002`), `verify-json.py`, `quick-eval.py`(추출 결과 점검).
- **⚠ 런타임은 설치하지 않는다**: 스킬은 `opendataloader-pdf` 가 설치돼 있다고 전제한다(`compatibility` 에 명시). 런타임은 `pip install -U opendataloader-pdf`(PyPI 2.5.12) 또는 `npm install @opendataloader/pdf`(Node 22.13 이상)이며 **Java 11 이상이 필요**하다. Java 가 환경마다 달라 이 저장소의 기본 설치(`tools.list`)에는 넣지 않았다. 런타임 없이 스킬만 있으면 에이전트가 설치 절차를 안내하는 정도로 동작한다.
- **왜**: `markitdown`·`pdf-inspector` 가 "변환 도구"라면 이 스킬은 ODL 을 쓸 때 조용한 실패를 막는 "사용 절차"다. 표·스캔본·수식은 ODL 의 하이브리드 모드(별도 서버를 띄워 AI 백엔드로 보냄)를 쓰는데, 이 서버가 데이터를 외부로 보내는지는 확인하지 못했다.
- **출처 확인**: PyPI·npm(`@opendataloader/pdf`, Apache-2.0)의 저장소 주소가 이 저장소와 일치한다. PyPI 의 라이선스 메타데이터는 비어 있다. 스킬의 `name:` 과 폴더 이름이 같아 `--skill odl-pdf` 로 정확히 선택된다. 같은 저장소의 `skills/odl-pdf-maintenance` 는 `SKILL.md` 가 없는 유지보수자용 자료라 제외했다.
- **벤치마크**: README 는 하이브리드 모드가 종합 0.907 로 1위라고 주장하지만 제작사 자체 측정이다. `pdf-inspector` README 의 다른 비교표에서는 ODL(로컬)이 0.831 로 나와 측정 조건에 따라 달라진다. 검증하지 못했다.
- **점검 결과**: 격리 환경에서 실제 매니페스트 항목으로 `bootstrap.sh --skills-only --tag pdf` 설치(`Selected 1 skill: odl-pdf`), 스킬 폴더에 `SKILL.md`·`references/`·`scripts/` 4개가 모두 들어옴을 확인했다. 스크립트에는 설치·삭제·외부 전송이 없다. ODL 런타임 설치와 PDF 추출은 실행하지 않았다.
- **사용 예**: "이 PDF 를 ODL 로 표까지 살려서 Markdown 으로 뽑아줘"

### Jakeschincariol/arena-skill — 에이전트 토너먼트 (⚠ 비용 큼)
- **무엇**: 같은 작업을 서브에이전트 N개에게 똑같이 맡기고, 각자 다른 전략 카드(추론 방식·작업 순서·전략)로 풀게 한 뒤 단판 토너먼트로 서로의 해법을 공격·방어시키고 심판이 루브릭으로 채점해 하나만 남긴다. 스킬 1개(`arena`, MIT)에 `bracket.py`(대진표·상태 관리), `rubric.md`, `strategies.json` 이 딸려 있다. 서브에이전트는 현재 폴더의 `.arena/` 안에만 쓰고, 결과를 프로젝트에 적용할지는 사용자가 정한다.
- **왜**: 답이 마음에 안 들 때 "다시 해줘"를 반복하는 대신 서로 다른 접근을 한꺼번에 시도해 보는 용도. 같은 모델이 전략만 바꿔 경쟁하는 방식이라 실제로 결과가 더 좋아지는지는 검증하지 못했다.
- **⚠ 비용**: 서브에이전트 호출 수는 `bracket.py plan` 으로 확인했다. 기본 100개는 **595회**, `--quick`(16개)은 **91회**, 30개는 175회. 토큰 소모는 측정하지 못했지만 일반 대화에 비해 매우 크다. 일상에는 `--quick` 을 쓰고 `--agents 100` 은 정말 필요할 때만.
- **자동 실행 주의**: 스킬 설명이 "불만족스러워할 때, '다시 해봐'라고 할 때" 자동 실행되도록 되어 있다. 사용자가 `/arena` 를 직접 부르지 않았다면 먼저 한 번 물어보도록 스킬이 지시하지만, 모델이 그 지시를 따르는지에 달려 있어 매니페스트로 강제할 수 없다. 원치 않으면 `~/.claude/skills/arena` 를 지우면 된다.
- **권한 확인**: 기본 권한 모드에서는 서브에이전트가 파일을 쓸 때마다 승인을 요구해 수백 번 뜬다. 실행 전에 accept-edits 모드(Shift+Tab)를 권한다.
- **점검 결과**: `bracket.py` 는 표준 라이브러리만 쓰고 네트워크·프로세스 실행·환경 변수 접근이 없으며 hook 도 없다. 포함된 테스트 27개 통과. 저장소는 2026-09-26 에 올라온 커밋 1개짜리 신생 프로젝트.
- **사용 예**: `/arena --quick README 첫 문단을 더 설득력 있게 다시 써줘`

---


### mikehasa/golive-skill — 프로덕션 배포 (알파, ⚠ 계정에 쓰기)
- **무엇**: 에이전트가 만든 앱을 사용자 **본인 계정**의 호스팅·DB·인증·결제·이메일·DNS(Vercel, Netlify, Supabase, Neon, Stripe, Resend, Cloudflare, Porkbun, GoDaddy, Sentry, PostHog)에서 실서비스로 올리는 절차다. 로컬 CLI(`golive`, 번들 `scripts/golive.mjs`)가 지원되는 연결 작업을 하고 검증 결과를 기록한다. `golive` 1개(MIT, `0.1.0-alpha.8`), 커밋 `7a55f26`에 고정.
- **안전장치(SKILL.md 의 "Hard rules")**: 비밀 값을 출력·채팅으로 받지 않는다. **사람이 계획을 승인하기 전에는 제공업체 계정에 쓰지 않는다.** 첫 프로덕션 배포는 `--confirm-live`, 삭제는 `--confirm-destroy` 로 따로 승인받는다. 설치만으로는 아무 계정에도 접속하지 않는다(`--help` 는 `golive.yaml` 이 없으면 사용법 오류만 내고 `~/.config` 에 아무것도 만들지 않음을 확인).
- **번들 검증**: 배포된 `scripts/golive.mjs`(1.2MB, 최소화 안 함)를 `src/` 에서 같은 `build.mjs` 설정으로 다시 빌드해 비교했다. 차이는 내장된 의존성 메타데이터의 `typescript` 버전 표기 한 줄뿐이다(`yaml` 경로 표기는 정규화). 즉 번들은 소스와 같은 코드다. 번들 안의 외부 접속처는 위 제공업체 API 와 업데이트 확인(`raw.githubusercontent.com/mikehasa/golive-skill/.../release.json`) 뿐이고 텔레메트리 호스트는 없다. `skills` CLI 로 설치한 사본은 "external manager" 라 스스로 업데이트하지 않는다(소스: `install-lib.mjs`). 코드 전체를 읽은 것은 아니다.
- **주의**: ① **알파**라 동작이 바뀔 수 있다 — 커밋 고정으로 막고, 올릴 때는 `bash scripts/pin.sh` 로 변경을 읽는다. ② 수동 API 키 입력이 필요하면 macOS 는 네이티브 대화상자, 그 밖의 OS 는 `~/.config/golive/credentials` **평문 파일**(권한 0600)에 저장한다. ③ "배포해줘" 류 요청에 반응하므로 실제로 쓸 때는 어느 계정에 무엇을 쓰는지 승인 단계에서 직접 읽을 것.
- **사용 예**: "이 앱을 Vercel + Supabase 로 올려줘".

### QingYunA/answer-me-with-html — 시각적 답변 (HTML 설명서)
- **무엇**: 구조가 있는 답(개념 3개 이상의 관계, 분기 있는 흐름·아키텍처, 3축 이상 비교, 계층, 단계)을 Markdown 초안으로 쓰면 번들 CLI(`scripts/am.mjs`, 단일 파일 324KB, 의존성 없음)가 한 페이지 HTML(템플릿, SVG 자동 배치, 문체 점검)로 만든다. `am video` 로 해설 영상 페이지도 만든다. `answer-me-with-html` 1개(MIT, `0.4.9`), 커밋 `6ab7221`에 고정. 상시 모드 플러그인(`answer-me-with-html-always`)은 매 턴 HTML 첨부를 강요하므로 **포함하지 않았다**.
- **점검 결과**: 설치된 사본으로 렌더링을 시험했다(`STE ✓ 0 warnings`, 외부 URL 로드 없음 — 스크립트 1개, 외부 주소 없음). 외부 접속은 ① 업데이트 확인(7일에 한 번, `raw.githubusercontent.com/.../package.json` 읽기 한 번, `CI` 나 `AM_NO_UPDATE_CHECK=1` 이면 안 함), ② `am video --voice elevenlabs` 를 **쓸 때만** ElevenLabs API 뿐이다. 업데이트 안내가 떠도 스킬은 스스로 업데이트하지 않고 사용자에게 묻도록 되어 있다.
- **주의**: 설명이 "묻지 않아도 적극적으로 사용"이라 복잡한 답에서 스스로 발동한다. 브라우저 자동 열기가 기본 설정이므로 끄려면 `am config set open false`. `diagram-design`, `archify` 와 일부 겹친다(그쪽은 다이어그램 전용).
- **사용 예**: "이 아키텍처를 한 페이지로 설명해줘".

### 이 저장소의 로컬 스킬 (`skills/`)

#### web-design-guidelines — Web Interface Guidelines 리뷰 (고정 사본)
- **무엇**: UI 코드를 Vercel Web Interface Guidelines(접근성, 폼, 포커스, 애니메이션, 타이포그래피, 성능, 다크 모드, i18n)에 맞는지 점검해 `file:line` 형식으로 출력한다. 규칙 파일 `references/command.md` 가 스킬 폴더에 **함께 들어 있다**.
- **왜 사본인가**: 원래 스킬(`vercel-labs/agent-skills` 의 `web-design-guidelines`)은 **실행할 때마다** `vercel-labs/web-interface-guidelines` 의 `main` 에서 `command.md` 를 내려받아 지시문으로 쓴다. 규칙과 에이전트가 따르는 지시가 upstream 이 바뀔 때마다 달라지고 머신·날짜마다 다르다. 그래서 원래 스킬은 `skills.list` 에서 빼고, 이 저장소에 고정한 사본을 둔다.
- **출처**: `command.md` 는 `vercel-labs/web-interface-guidelines` 커밋 `e3d624ba…`(2026-08-17)의 **바이트 그대로 복사**(SHA-256 `5a775e64…` 이 upstream 과 일치함을 확인), MIT 라이선스 사본을 함께 둔다. `SKILL.md` 는 이 저장소용으로 새로 썼다(원본 스킬 텍스트를 복사하지 않음. 원본 `agent-skills` 저장소에는 라이선스 파일이 없다). 갱신 방법과 해시는 `skills/web-design-guidelines/SOURCE.md`.
- **갱신**: upstream diff 를 **읽은 뒤** 새 `command.md` 로 교체하고 `SOURCE.md` 의 커밋·해시를 고친다.
- **사용 예**: "이 컴포넌트 UI 리뷰해줘", "접근성 점검".

#### ai-setup-sync — 이 저장소의 매니페스트로 환경 동기화
- **무엇**: 에이전트에게 `kc9302/ai_agent_setup` 로 스킬·도구를 설치·동기화하는 절차(클론 → `bootstrap.sh` → `status.sh`)를 알려 준다. 이전에는 `npx skills add kc9302/ai_agent_setup` 로만 설치할 수 있었고 `bootstrap.sh` 는 설치하지 않았다.

#### persona-sim-review — 가상 인물 여러 명에게 평가받는 출시·공개 점검
- **무엇**: 타깃 사용자, 회의적 사용자, 헤비 유저, VC, 운영 PM, 변호사, 보안·신뢰안전, 그로스 같은 가상 인물 6~10명을 서브에이전트로 연기시켜 독립 평가(1라운드)와 쟁점 토론(2라운드)을 받고 종합 보고서를 만든다. 출시·공개 전 **놓친 위험과 점검 우선순위**를 뽑는 용도이고 수요·가격·성과(별 수 등) 예측은 하지 않는다. 사용자가 자기 PC 에 둔 스킬을 저장소로 옮긴 것이다.
- **일반화한 것**: 원본의 개인 프로젝트 사례(앱 이름과 해당 시행 수치)를 빼고 절차만 남겼다. 오픈소스 공개 점검에 쓸 때의 인물 구성 예시를 추가했다.
- **보강한 것**(오픈소스 공개 점검에 직접 써 보며 확인): ① 서브에이전트의 답장은 요약문으로 와서 내용이 빠질 수 있으므로 **인물이 결과를 파일에 쓰고** 오케스트레이터가 파일을 읽는다, ② 인물 전원이 비슷한 점수대로 수렴하는 현상과 대응(반대 동기 인물, 블라인드 시드와 공개 시드 비교), ③ 관찰한 호출 비용(인물 호출 1회 약 6만 토큰, 보장 아님), ④ 인물이 말한 수치(별 수, 매출 등)는 사실로 옮기지 않는다는 규칙, ⑤ 반응 전개 시뮬레이션이 필요하면 `stakeholder-rehearsal` 로 안내.
- **한계**: 같은 모델이 연기한 인물이라 실제 사용자 반응이 아니다. 결과로 출시·투자 결정을 내리지 않고 다음 단계로 실제 사용자 5~10명 인터뷰를 권한다.
- **사용 예**: "이 프로젝트 공개해도 될지 가상 인물들로 평가해줘".

#### stakeholder-rehearsal — 이해관계자 시뮬레이션으로 반응 리허설
- **이름**: 처음 이름은 `swarm-forecast` 였으나 가상 인물 평가에서 "forecast 가 예측을 약속하는 단어"라는 지적이 나와 `stakeholder-rehearsal` 로 바꿨다(작업 폴더도 `forecast/` → `rehearsal/`). 이 도구는 예측이 아니라 시나리오 리허설이다.
- **무엇**: 시드 자료(뉴스, 정책안, 출시 계획, 위기 상황, 이야기)로 사실표·이해관계자 유형·페르소나를 만들고, 서브에이전트가 라운드별로 SNS 에서 행동하는 시뮬레이션을 돌려 근거가 있는 시나리오 리포트를 쓴다. 서버·API 키·그래프 DB 없이 Claude Code 안에서 돈다. `lite`(6~10명 × 6~12라운드)가 기본.
- **출처**: `666ghj/MiroFish`(AGPL-3.0, 커밋 `7657031`)의 워크플로를 분석해 **방법론만** 새로 구현했다. 코드·프롬프트 문구는 복사하지 않았다(`skills/stakeholder-rehearsal/SOURCE.md`). MiroFish 자체는 앱이라 설치 대상에서 보류 목록에 있다.
- **원본과 다른 점**: 활성화 규칙(시간대 × 활동 확률)은 `pick_agents.py` 로 재현. 원본이 생성만 하고 쓰지 않던 값(입장 수치, 영향력 가중, 예약 이벤트)은 빼고 **예약 주입을 실제로 적용**한다. 원본에서 프롬프트로만 요구하던 인용 조작 금지를 `verify_quotes.py` 가 **인용문이 인용 표기된 로그 id 안에 실제로 있는지** 검사한다. 시나리오 분기 비교를 추가했다.
- **시험**: 가상 시나리오(도시의 보도 전동킥보드 금지령)로 6명 × 4라운드 + 인터뷰 2건을 실제로 돌려 리포트를 만들고 인용 9건을 검증했다(`examples/scooter/`). 이 시험에서 고친 것: 서브에이전트의 답장은 요약문이라 행동 내용이 빠지므로 **파일에 쓰게** 함, 에이전트가 시드에 없는 연도(2028)를 지어내 3명이 따라 쓴 현상을 막는 지시와 리포트 규칙 추가, 인터뷰 답이 로그와 모순될 수 있다는 경고. 깨끗한 HOME 에서 `skills add` 로 설치해 스크립트 6개와 예제가 들어가고 설치된 위치에서 검증이 통과함을 확인했다.
- **오픈소스 준비**: `packaging/stakeholder-rehearsal/` 에 영문 README, MIT LICENSE, CI, 스크립트 단위 테스트 34개를 두었다. `bash scripts/export-stakeholder-rehearsal.sh <빈 디렉터리>` 로 독립 저장소 형태를 만들고, 그 결과에서 테스트가 통과함을 확인했다(`python3 -m unittest discover -s packaging/stakeholder-rehearsal/tests`). 테스트가 `--seed N` 이 N번째 라운드 인자를 지워 버리는 버그를 잡아 고쳤다(12라운드 실행이면 7라운드에서 실패했을 것). 공개 전에 README 의 `<owner>` 와 LICENSE 저작권자를 확인할 것.
- **가상 인물 평가 후 보강(0.2.0)**: 6명 평가에서 나온 공통 지적을 반영해 ① 모든 리포트가 표준 경고 블록으로 시작해야 하고 `verify_quotes.py` 가 없으면 실패시킨다, ② `estimate_cost.py` 가 실행 전에 서브에이전트 호출 수를 센다(예제는 22회, 토큰은 예측하지 않고 이번 시험에서 관찰한 호출당 약 41~44k 토큰만 적음), ③ `make_baseline.py` 로 같은 시드의 단일 호출 대조군을 만들고 리포트에 "시뮬레이션이 더한 것" 절을 둔다. 예제에서는 대조군이 "예산 의혹 프레임이 지배한다"고 단정했지만 시뮬레이션에서는 그 소식에 아무도 반응하지 않았다(표본은 각 1개뿐). 데모 GIF, 보정 사례(과거 사건 역검증), 다른 모델 시험, 저장소 이름은 아직 없다.
- **한계**: 한 모델이 여러 역할을 연기하는 것이라 실제 군중보다 말이 조리 있고 일관된다. 작은 캐스트로는 군중 효과를 볼 수 없고 같은 입력도 결과가 갈린다. 실제 결과와 대조한 보정이 없으므로 **확률이 아니라 시나리오와 그 메커니즘**으로만 읽을 것. 시험은 소형 모델·6명·1시드 한 번뿐이다.
- **사용 예**: "이 정책 발표에 이해관계자들이 어떻게 반응할지 시뮬레이션해줘".

#### skill-radar — 인기·신규 스킬 후보를 카드로 보고, 요청할 때만 설치
- **무엇**: `radar` workflow(`scripts/radar.sh`)가 매일 GitHub 에서 인기 있는/새로 뜨는 스킬 저장소를 찾아 `radar-data` 브랜치에 `candidates.json` 으로 발행한다. `skill-radar` 스킬은 그 파일을 받아 카드로 보여준다.
- **왜 이렇게**: 새 스킬이 매일 나오지만 자동 설치는 공급망 위험이 크다(스킬은 에이전트가 따르는 지시문이다). 그래서 **발견은 자동, 설치는 사용자가 요청할 때만, 저장소 편입은 PR 을 사람이 머지**로 나눴다.
- **안전 장치**: 후보는 모두 커밋에 고정된 설치 명령을 갖는다. 후보의 설명·README 는 데이터로만 다루고 그 안의 지시는 따르지 않는다. 설치 전에 `SKILL.md` 원문을 읽고 위험 신호를 알린다(보안 감사는 아님).
- **알아 둘 것**: 별 수는 적합성이 아니다(실제 첫 수집에서 별 4만 개가 넘는 생활 정보 저장소가 후보에 올랐다). 수집은 GitHub 토픽에 의존하므로 토픽이 없는 저장소는 빠진다. 데이터는 `https://raw.githubusercontent.com/kc9302/ai_agent_setup/radar-data/candidates.json`.

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

### graphify — 코드·문서 지식 그래프
- **저장소**: https://github.com/Graphify-Labs/graphify
- **무엇**: tree-sitter 로 코드를 로컬 파싱해 import·호출·상속 관계를 **지식 그래프**로 만든다. 벡터 DB 가 필요 없다. 결과물은 `graph.html`(인터랙티브), `GRAPH_REPORT.md`(핵심 요약), `graph.json`(질의용).
- **LEANN·archify 와의 차이**: LEANN 은 의미 기반 검색, archify 는 사람이 설명한 구조의 시각화, graphify 는 **실제 코드에서 관계를 추출해 질의**한다. "인증은 DB 와 어떻게 연결되나" 같은 질문에 강하다.
- **설치**: `uv tool install graphifyy` (PyPI 이름은 y 가 두 개) 후 `graphify install` 로 `/graphify` 스킬 등록 (tools.list 가 둘 다 수행).
- **사용 예**: `/graphify .`, `/graphify query "what connects auth to the database?"`, `/graphify path "UserService" "DatabasePool"`.

### llmfit — 내 하드웨어에 맞는 로컬 LLM 추천
- **저장소**: https://github.com/AlexsJones/llmfit
- **무엇**: CPU·RAM·GPU/VRAM 을 감지해 돌릴 수 있는 오픈 LLM 을 양자화별 성능 추정과 함께 순위로 보여준다. TUI, `--json` 출력, HTTP API 지원.
- **사용 예**: `llmfit`, `llmfit recommend --json`. huggingface-local-models 스킬과 함께 쓰면 "모델 고르기 → GGUF 실행" 이 이어진다.

### kordoc — 한국 문서(HWP/HWPX) 변환
- **저장소**: https://github.com/chrisryugj/kordoc
- **무엇**: HWP 3.x/5.x, HWPX, HWPML, PDF, XLS/XLSX, DOCX, PPTX, 이미지(OCR 자동) 를 Markdown·구조화 데이터·RAG 청크로 변환. 양식 채우기와 MCP 서버도 지원.
- **왜**: markitdown 은 HWP 를 못 읽는다. 한국 공공·기업 문서에는 필수.
- **설치 범위**: CLI 만 (`npm install -g kordoc`). MCP 연결은 `npx -y kordoc setup` 또는 플러그인(`/plugin marketplace add chrisryugj/kordoc`)으로 필요할 때 따로.
- **사용 예**: `kordoc 문서.hwpx -o 문서.md`, `kordoc *.pdf --jobs 4 -d ./결과`.

### officecli — Office 파일 읽기·편집 CLI
- **저장소**: https://github.com/iOfficeAI/OfficeCLI
- **무엇**: Word·Excel·PowerPoint 를 에이전트가 CLI 로 읽고 고치고 만든다. 렌더링 엔진, 수식 평가, 템플릿 병합 내장. `officecli mcp <agent>` 로 MCP 서버로도 쓸 수 있다.
- **왜**: 내장 docx/xlsx/pptx 스킬을 보완. **기존 파일 편집 품질은 실제 비교가 필요**하다. 중복이라 판단되면 tools.list 에서 제거.
- **설치와 버전 고정**: `npm install -g @officecli/officecli@1.0.153`. 이 npm 패키지(Apache-2.0, SLSA 출처 증명 있음)는 설치 때 `postinstall` 로 **플랫폼 바이너리를 내려받는다**: 패키지 버전에 맞는 릴리스 태그의 불변 경로에서 `d.officecli.ai` 미러를 먼저, GitHub 릴리스를 대체로 쓴다. `SHA256SUMS` 로 검증하지만 체크섬 파일이 바이너리와 **같은 미러**에서 오고, 체크섬 파일을 받지 못하면 검증을 **조용히 건너뛴다**. 설치 중에는 `~/.claude` 에 아무것도 쓰지 않는다(확인함).
- **⚠ 자동 업데이트(기본 켜짐)**: 바이너리는 백그라운드에서 스스로 업데이트를 확인하고(`~/.officecli/config.json` 의 `autoUpdate: true`), 설정 파일에 `lastSkillRefreshVersion` 도 있어 업데이트 때 스킬도 갱신하는 것으로 보인다. 그러면 버전을 고정해도 시간이 지나며 환경마다 달라진다. 그래서 설치 직후 `officecli config autoUpdate false` 로 끈다(영구 적용·재실행에도 유지됨을 확인). 일회성으로는 `OFFICECLI_SKIP_UPDATE=1`. 이미 설치돼 있던 환경에는 이 설정이 적용되지 않으므로 직접 `officecli config autoUpdate false` 를 실행한다.

### officecli-skills — officecli 에 내장된 스킬 11개
- **무엇**: `officecli skills install` 은 바이너리에 **내장된** 스킬을 감지된 에이전트에 설치한다. 기본 `officecli` 1개와 `officecli-pptx`·`officecli-docx`·`officecli-xlsx`(파일 형식별), `officecli-word-form`(채울 수 있는 Word 양식), `officecli-pitch-deck`(투자 유치 덱), `officecli-academic-paper`(논문 형식 docx), `officecli-data-dashboard`(Excel 대시보드), `officecli-financial-model`(재무 모델), `morph-ppt`·`morph-ppt-3d`(Morph 전환 효과 pptx) 10개. 총 2.5MB, 파일 121개.
- **왜 저장소 스킬이 아니라 내장 설치인가**: 이 저장소는 루트에 `SKILL.md` 가 있고 `skills/officecli` 와 `name:` 이 같아 `npx skills add` 로 쓰면 하위 스킬을 못 찾거나 이름이 겹친다. 내장 설치는 **고정한 바이너리 버전과 항상 같은 스킬**을 주고 인터넷 없이도 동작한다(오프라인 설치 확인). 저장소 `main` 이 바뀌어도 영향이 없다.
- **조용한 성공 방지**: 에이전트가 하나도 감지되지 않으면 `officecli skills install`(인자 없음)은 "No supported AI tools detected."를 출력하고 **종료 코드 0** 으로 끝난다. 이름을 지정하면 종료 코드 1 이다. 그래서 이 항목은 스킬마다 설치하고 마지막에 `officecli skills list` 로 11개 중 10개 상태가 `[installed]` 인지 확인해, 에이전트가 없는 환경에서는 **명확히 실패로 보고**한다. 에이전트를 설치한 뒤 `bootstrap.sh --tools-only` 를 다시 실행한다.
- **⚠ 기존 docx/xlsx/pptx 스킬과 겹침**: `anthropics/skills` 의 `docx`·`xlsx`·`pptx` 와 `officecli-docx`·`officecli-xlsx`·`officecli-pptx` 는 설명이 거의 같은 문구("해당 확장자 파일이 관련되면 언제든 사용")라 같은 요청에 둘 다 후보가 된다. 어느 쪽이 더 나은지는 비교하지 못했다. 쓰다가 하나로 줄이려면 `officecli skills` 쪽을 빼거나 `anthropics/skills` 의 해당 항목을 뺀다.
- **스킬이 에이전트에게 시키는 설치**: 스킬 지침(`officecli`, `officecli-pptx` 등)에는 "officecli 가 없으면 `curl -fsSL https://d.officecli.ai/install.sh | bash` 로 설치하라"는 문장이 있다. 이 저장소가 바이너리를 먼저 고정 설치하므로 발동하지 않지만, 없는 환경에서는 에이전트가 벤더 서버의 스크립트를 실행하려 할 수 있다.
- **점검 결과**: 설치된 스킬의 `name:` 이 저장소 폴더 이름과 같고, 포함된 스크립트 29개(`morph-ppt` 의 스타일 템플릿 `build.sh` 27개와 헬퍼 2개)에는 `curl`·`sudo`·`eval`·`base64`·외부 접속이 없다. 격리 환경에서 실제 매니페스트 항목으로 확인: Claude 가 있으면 스킬 11개가 설치되고 재실행 시 건너뛴다. 에이전트가 없으면 실패로 보고된다. 에이전트가 Claude 외(Cursor 등)인 환경은 시험하지 못했다.

### hyperresearch — 딥 리서치 에이전트
- **저장소**: https://github.com/jordan-gibbs/hyperresearch
- **무엇**: Claude Code 를 16단계 파이프라인의 리서치 에이전트로 바꾼다. 출처를 모으고 교차 검증해 **인용이 달린 보고서**를 쓰고, 결과를 SQLite 로 색인되는 지식 볼트에 쌓아 세션을 넘어 재사용한다. 인용문 무결성 검증(환각 인용 차단), 철회 논문 확인, 파생 출처 독립성 감사, 적대적 리뷰, 중단 후 재개를 지원한다.
- **내장 deep-research 와의 차이**: 내장 스킬은 가볍게 여러 출처를 훑어 요약한다. 이쪽은 검증 단계와 누적 지식 볼트가 핵심이라 **시간과 토큰을 훨씬 많이 쓴다**. 가벼운 조사는 내장, 보고서급 조사는 hyperresearch 로 나눠 쓴다.
- **설치**: `uv tool install hyperresearch` 후 `hyperresearch install --global` (tools.list 가 수행). `--global` 은 `~/.claude/` 에 `/hyperresearch` 스킬 1개와 에이전트 16개만 둔다. 프로젝트 파일, 훅, settings.json 은 건드리지 않는다. 볼트와 16개 단계 스킬은 프로젝트에서 처음 `/hyperresearch` 를 실행할 때 그 프로젝트에 만들어진다.
- **API 키 (모두 선택)**: OpenAlex, Crossref, DOAB, ClinicalTrials.gov, Europe PMC 는 무료로 키가 필요 없다. `CORE_API_KEY`, `FRED_API_KEY`, `HYPERRESEARCH_CONTACT_EMAIL`(SEC EDGAR, Unpaywall 용) 은 해당 소스를 쓸 때만 필요하다. Exa, Tavily 등 웹 검색 제공자도 선택이다.
- **사용 예**: `/hyperresearch 2026년 로컬 LLM 양자화 기법 비교`

### paperclipai — AI 에이전트 팀 관리 서버의 CLI
- **무엇**: Paperclip 은 여러 AI 에이전트를 조직도·예산·목표·승인 흐름으로 관리하는 Node.js 서버 + React UI 다(MIT, `paperclipai/paperclip`). 이 항목은 npm 패키지 `paperclipai` 의 **CLI 만** 전역 설치한다. 서버 시작은 직접 한다: `paperclipai onboard` (README 의 빠른 시작은 `npx paperclipai@latest onboard --yes`). 로컬에서는 설정 파일과 내장 Postgres, 로컬 파일 저장소를 만든다.
- **왜**: 에이전트 여러 개를 태스크·비용 단위로 관리하는 대시보드가 필요할 때. 일상 개발 도구가 아니라 선택 도구라서 기본 설치는 CLI 까지만 하고 `onboard` 는 자동 실행하지 않는다.
- **요구 사항**: **Node 24.11 이상**. 그보다 낮으면 설치 명령이 "Node 24.11 이상이 필요해 건너뜁니다 (현재 …)"를 출력하고 종료 코드 75 로 끝나, 부트스트랩이 **실패가 아니라 "건너뜀"** 으로 보고한다(종료 코드 0, 마지막에 "건너뛴 도구" 목록을 출력). Node 를 올린 뒤 `bash bootstrap.sh --tools-only` 를 다시 실행하면 설치된다. (이전에는 Node 24 미만 머신이 모두 실패 1건과 종료 코드 1 로 끝났다.)
- **점검 결과**: npm 패키지의 저장소 주소가 `paperclipai/paperclip` 과 같고 MIT 이며, 설치 스크립트가 없다(npm 메타데이터 기준). 의존성에 `@anthropic-ai/sdk`, `postgres`, `ws` 와 ACP 어댑터가 있다. Node 24 에서 설치·`--version`·재실행 건너뛰기를 확인했고 HOME 에 파일을 만들지 않는다. Node 22 에서는 건너뜀(종료 코드 0)으로 처리됨을 확인했다.
- **같이 오지 않는 것**: 저장소 최상위 `skills/` 의 7개는 대부분 Paperclip 서버가 있어야 쓸 수 있다(`paperclip`, `paperclip-board`, `agentmail`, `slack` 등). 서버 없이 쓸 만한 것은 `para-memory-files`(파일 기반 PARA 메모리) 정도이며 이 항목은 설치하지 않는다.
- **사용 예**: `paperclipai --help`, 서버 시작은 `paperclipai onboard`

### graft — 코드베이스 컨텍스트 레이어 CLI
- **무엇**: 코드를 그래프로 만들어 Claude Code·Codex·Cursor 등에 연결하는 CLI(MIT). npm 패키지 `@nanonets/graft`(Node 20 이상). 전역 설치만으로는 설정이 바뀌지 않는다. 프로젝트에서 `graft init` 을 실행하면 `.claude/` 에 상태 표시줄과 훅을 병합해 넣고 MCP 서버를 등록한다(`graft init --dry-run` 으로 건드릴 파일을 먼저 볼 수 있고, `--agents claude`, `--no-hooks` 옵션이 있다). 이 저장소의 `bootstrap.sh` 는 `graft init` 을 실행하지 않는다.
- **왜**: `graphify`, LEANN 과 같은 "코드를 에이전트에게 먼저 이해시키는" 용도다. 셋을 다 쓰면 겹치므로 실제로 쓰면서 하나로 줄이는 것을 권한다. README 의 토큰·시간 절감 수치는 제작사 자체 측정이라 검증하지 못했다.
- **⚠ 텔레메트리**: npm `postinstall` 이 설치 이벤트를 기록하고 백그라운드로 전송한다. 이 항목은 설치할 때만 `DO_NOT_TRACK=1` 로 이를 막는다(설치 후 `~/.graft/` 에는 하루 한 번 버전 확인용 `update-check.json` 만 생긴 것을 확인). **실행 중 텔레메트리는 도구 기본값(켜짐, 익명 집계)** 이고, 끄려면 `graft telemetry disable` 또는 환경 변수 `DO_NOT_TRACK` 을 쓴다. 내용은 `TELEMETRY.md` 에 허용 목록으로 공개돼 있고 `graft telemetry debug` 로 보낼 내용을 볼 수 있다. 패키지 안에 `events.nanonets.com`, PostHog(`eu.i.posthog.com`), `app.trailhq.com` 주소가 있다.
- **출처 주의**: GitHub 저장소는 `trailhq/Graft`, README 배지는 `NanoNets/Graft`, npm 패키지의 저장소 주소는 `NanoNets/context-graph-engine` 로 서로 다르다. npm 패키지가 이 저장소의 코드로 빌드됐는지는 확인하지 못했다. 설치되는 것은 npm 타르볼이고, 그 안의 `postinstall` 은 텔레메트리 기록과 분리 프로세스 실행만 하는 것을 읽어 확인했다.
- **Trail 연동 주의**: `graft trail push/pull` 은 클라우드 서비스(Trail)에 가입해 연결하고 `CLAUDE.md`/`AGENTS.md` 를 갱신한다. 의도하지 않았다면 쓰지 않는다.
- **점검 결과**: Node 22 에서 설치와 `graft --version`(0.21.1) 확인. `tree-sitter` 네이티브 모듈 등 18개 의존성이 있다.
- **사용 예**: `graft init --dry-run`, `graft init --agents claude`
- **Windows**: `@nanonets/graft` 가 `tree-sitter-kotlin` 같은 네이티브 모듈을 `node-gyp` 로 빌드하므로 Visual Studio Build Tools 의 "Desktop development with C++" 워크로드가 없으면 `npm install` 이 실패한다(사용자 Windows 실행에서 확인). 이때 `graft` 명령은 남아 있어 설치 항목은 명령이 동작하면 경고만 남기고 통과시킨다. 일부 언어 분석이 빠진 반쪽 설치일 수 있으므로 쓸 계획이면 빌드 도구를 설치하고 다시 설치한다.

### specify — GitHub Spec Kit (스펙 주도 개발)
- **무엇**: GitHub 공식 Spec Kit 의 CLI `specify-cli`(MIT, Python 3.11+). 프로젝트에 `specify init <이름> --integration claude` 를 실행하면 스펙 주도 개발 골격을 만든다: `.specify/`(프로젝트 원칙 `constitution.md`, 스펙·계획·작업 템플릿, 스크립트, 워크플로)와 `.claude/skills/speckit-*` 10개(`constitution`, `specify`, `clarify`, `plan`, `tasks`, `analyze`, `checklist`, `implement`, `converge`, `taskstoissues`). 흐름은 원칙 → 스펙 → (질문) → 계획 → 작업 → (분석) → 구현. Claude 외에 Copilot, Codex 등 여러 에이전트 통합을 지원한다.
- **설치**: `uv tool install specify-cli`(PyPI 최신판). 버전을 고정하려면 `uv tool install specify-cli==1.0.13` 또는 `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v1.0.13`. 이 저장소의 `bootstrap.sh` 는 CLI 만 설치하고 `specify init` 은 실행하지 않는다. 스킬은 **프로젝트마다** 만들어지며 전역 설치가 아니다.
- **출처 확인**: 공식 문서가 GitHub 태그와 PyPI `specify-cli` 두 채널을 공식 배포처로 밝힌다. 다만 PyPI 페이지의 프로젝트 URL·저자·라이선스 메타데이터가 비어 있어 PyPI 만 봐서는 출처가 드러나지 않는다. 그래서 1.0.13 휠을 받아 저장소 태그 `v1.0.13` 과 대조했다: 파이썬 소스가 동일하고, 휠에 들어 있는 `core_pack`(템플릿·스크립트·워크플로 등)도 저장소 파일과 내용이 같다(저장소에만 있는 파일이 빠진 부분집합). 텔레메트리 코드는 없다.
- **네트워크**: `init` 은 휠에 번들된 템플릿을 쓰며 실행 중 접속한 주소를 출력하지 않았다. 확장·번들 카탈로그 기능을 쓸 때만 `raw.githubusercontent.com` 의 카탈로그를 읽는다.
- **겹침**: addyosmani 의 `spec-driven-development`, mattpocock 의 `to-spec`, superpowers 의 `brainstorming`·`writing-plans` 와 역할이 겹친다. 한 프로젝트에서는 한 방식만 쓰는 것을 권한다. 이쪽은 스펙·계획·작업을 `.specify/` 에 파일로 남기고 명령이 단계별로 나뉘어 있다.
- **점검 결과**: Python 3.11 에서 uv(pip 폴백으로 설치)로 `bootstrap.sh --tag spec` 설치, `specify version`(1.0.13), 재실행 건너뛰기 확인. 임시 폴더에서 `specify init demo --integration claude` 를 실행해 위 파일들이 프로젝트 안에만 만들어지고 HOME 에는 아무것도 쓰지 않는 것을 확인했다. Claude 외 통합과 워크플로 실행은 확인하지 않았다.
- **사용 예**: `specify init my-app --integration claude` 후 Claude Code 에서 `/speckit-constitution`, `/speckit-specify 사용자가 오프라인에서도 일하고 재접속하면 동기화한다`

### agent-reach — 플랫폼별 인터넷 읽기 CLI (⚠ 영향 범위 큼)
- **무엇**: Twitter/X, Reddit, YouTube, Bilibili, 샤오홍슈, V2EX, LinkedIn, BOSS直聘(Boss Zhipin), 웹, RSS 등 16개 플랫폼의 **읽기**(검색·조회) 백엔드를 골라 연결해 주는 Python CLI(`Panniantong/Agent-Reach`, MIT, Python 3.10+). `agent-reach doctor` 로 어떤 채널이 지금 동작하는지 본다. 글쓰기(게시·댓글·좋아요)는 범위 밖이라고 스킬에 명시돼 있다.
- **⚠ 이름 충돌**: **PyPI 의 `agent-reach` 는 이 프로젝트가 아니다**(`jgalea/agent-reach`, v0.1.0, 별개 프로젝트). `pip install agent-reach`, `uv tool install agent-reach` 는 엉뚱한 패키지를 설치한다. README 는 GitHub 아카이브 URL 로 설치하라고 안내한다.
- **설치 방식**: 이 항목은 PyPI 가 아니라 **검토한 커밋에 고정**해 설치한다: `uv tool install --from git+https://github.com/Panniantong/Agent-Reach.git@a19a171fa980a0785849596492e0af4db800c82f agent-reach` (v1.5.0 표기, 릴리스 태그 `v1.5.0` 보다 이후 커밋이며 BOSS直聘(Boss Zhipin) 채널이 추가됨). 최신으로 올리려면 커밋 해시를 갱신한다. 설치는 CLI 만 하며 `~/.agent-reach/`, 스킬, 외부 도구는 만들지 않는다(확인함).
- **기본 동작은 읽기 전용**: `agent-reach install` 은 기본이 "SAFE MODE"(시스템 변경 없음)이고 `agent-reach doctor` 는 설정을 만들지 않는다(둘 다 실행해 확인). 다만 `doctor` 는 V2EX 등 외부 서비스에 접속을 시도한다.
- **`--system` 은 영향이 크다**: `agent-reach install --system` 은 apt/brew 로 시스템 패키지를, npm 으로 OpenCLI 를, pipx/uv 로 `twitter-cli`·`boss-agent-cli`·`rdt-cli`(커밋 고정) 같은 서드파티 도구를 설치한다. 명시적으로 승인할 때만 실행한다. 이 저장소의 `bootstrap.sh` 는 실행하지 않는다.
- **쿠키**: `agent-reach configure twitter-cookies` 등으로 로그인 쿠키를 `~/.agent-reach/config.yaml`(권한 600)에 저장한다. 브라우저 쿠키 추출(`--from-browser`)은 플랫폼 하나씩 명시한 경우에만 하도록 설계돼 있다(소스에서 확인, 실행은 하지 않음). 로그인 계정으로 플랫폼을 긁는 방식이라 **해당 서비스의 약관·계정 제한 위험**이 있다.
- **외부 서비스로 전송**: 웹 읽기는 `r.jina.ai`(Jina Reader), 웹 검색은 Exa MCP(`mcporter`)를 거친다. 즉 읽을 URL 과 검색어가 제3자 서비스로 전송된다. 사내·비공개 URL 에는 쓰지 않는다. 텔레메트리 코드는 찾지 못했다.
- **스킬은 설치하지 않았다**: 저장소의 스킬(`agent-reach`)은 설명이 "사용자가 **어떤 URL 이나 플랫폼 이름을 언급하거나 검색을 요청하기만 해도 반드시 사용**"하도록 되어 있어, 설치하면 모든 URL·검색 요청이 이쪽(Jina·Exa 경유)으로 라우팅된다. 기존 Playwright MCP, `agent-browser`, `markitdown`, 내장 WebFetch 와 충돌한다. 쓰고 싶으면 `agent-reach skill --install`(CLI 버전에 맞는 스킬을 `~/.claude/skills/` 등에 설치) 후 필요 없으면 `agent-reach uninstall --keep-config` 로 스킬만 제거한다.
- **스킬이 가리키는 원격 문서**: 스킬과 README 는 `raw.githubusercontent.com/.../main/docs/install.md`·`update.md` 를 에이전트가 읽고 따르게 한다. `main` 의 문서는 언제든 바뀔 수 있어, 에이전트가 읽는 즉시 지침이 되는 구조라는 점을 알고 쓴다.
- **점검 결과**: Python 3.11 에서 uv 로 `bootstrap.sh --tag research` 설치, `agent-reach --version`(v1.5.0), 재실행 건너뛰기 확인. `install`·`doctor` 실행으로 읽기 전용 확인. 로그인이 필요한 채널(Twitter, 샤오홍슈, BOSS直聘(Boss Zhipin) 등)과 `--system`, 쿠키 추출은 실행하지 않았다. 샌드박스에서 `doctor` 는 16개 중 2개 채널만 사용 가능으로 나왔다(외부 접속 제한 포함).
- **사용 예**: `agent-reach doctor`, `agent-reach check-update`

### orx — alphaXiv OpenResearch (자율 연구 워크스페이스 CLI, ⚠ 텔레메트리 기본 켜짐)
- **무엇**: 연구 에이전트(Claude Code, Codex, OpenCode, Cursor, Antigravity)를 위한 로컬 우선 워크스페이스(`alphaXiv/OpenResearch`, MIT). Rust CLI `orx` 와 데스크톱 앱이 있고, `orx up` 이 `http://127.0.0.1:4791` 에 로컬 대시보드(SQLite)를 연다. 연구 방향마다 독립 에이전트 세션과 git worktree 를 주고, git 기반 실험 트리에 변형을 기록하며 실행마다 커밋 스냅샷을 불변 아카이브로 남긴다. 연산은 로컬, SSH, Slurm, Kubernetes, Ray, Hugging Face Jobs, Modal, Tinker, 관리형 OpenResearch 연산에서 실행할 수 있다. 에이전트가 아이디어 제안 → 코드 수정 → 실험 실행 → 증거 확인을 스스로 돌리는 "autoresearch" 루프도 지원한다.
- **설치 범위**: `orx` CLI 만, **v0.2.15 릴리스에 고정**해 설치한다(`~/.local/bin/orx`). `orx up`(서버), `orx install-skills`(스킬 설치), 연산 백엔드 연결은 자동 실행하지 않는다.
- **설치 경로를 README 와 다르게 잡은 이유**: README 는 `curl https://openresearch.sh/install.sh | sh` 를 안내한다. 이 스크립트는 저장소에 없고 벤더 도메인에서 내려받는 구조인데, 이 환경의 외부 접속 정책이 그 도메인을 막아(403) 읽어 볼 수 없었다. 대신 저장소의 릴리스 파이프라인(cargo-dist)이 GitHub 릴리스에 올리는 `openresearch-cli-installer.sh` 를 받아 읽었다: 1660줄, 내려받는 곳은 `releases/download/v0.2.15` 뿐이고 플랫폼별 SHA-256 이 스크립트에 박혀 있어 설치 중 검증하며, 값은 릴리스의 `sha256.sum`·`dist-manifest.json` 과 일치한다.
- **설치가 하는 일**: `CARGO_HOME=$HOME/.local` 로 지정해 `~/.local/bin/orx` 에 두고(다른 도구와 같은 위치), `OPENRESEARCH_CLI_NO_MODIFY_PATH=1` 로 셸 설정 파일(`.bashrc` 등)을 건드리지 않는다. 만들어지는 파일은 `~/.local/bin/orx` 와 `~/.config/openresearch-cli/openresearch-cli-receipt.json` 둘뿐이다(확인함). 서명되지 않은 바이너리다(README 도 macOS 관리형 기기에서 차단될 수 있다고 안내).
- **⚠ 텔레메트리(기본 켜짐)**: 공식 릴리스 빌드는 **`orx` 를 처음 실행하는 순간**부터 익명 사용 이벤트를 쌓는다. 설치만으로는 만들어지지 않는다. 첫 실행에서 `~/.config/openresearch/settings.json`(임의 설치 ID 포함), `~/.local/share/openresearch/orx.db`, 전송 대기열 파일이 생긴다. 대기열의 이벤트는 직접 열어 확인했다: 명령 이름, OS, 아키텍처, CLI 버전, 설치 ID 뿐이고 코드·프롬프트·경로는 없었다. 끄려면 **설치 직후 `orx telemetry off`**(끈 뒤 명령을 실행해도 대기열이 생기지 않음을 확인). 명령 하나만 끄려면 `--no-telemetry`. 이 항목은 텔레메트리를 자동으로 끄지 않는다(사용자가 정할 일).
- **`orx feedback`**: 스킬 `orx-feedback` 는 사용자가 불만을 표현하면 에이전트가 `orx feedback` 으로 제품 피드백을 보내게 한다. 공식 빌드에서만 전송되고, 로그인했다면 계정에 연결되며, `orx telemetry off` 로 꺼진다.
- **⚠ 비용·보안**: 원격 연산 백엔드와 관리형 연산은 비용이 들 수 있고, 자율 루프는 실험을 계속 실행한다. `orx up --remote user@host` 는 원격 서비스가 루프백에 바인딩되지만 **앱 수준 인증이 없어 그 호스트의 다른 사용자가 접근할 수 있다**고 README 가 경고한다.
- **같이 오지 않는 것**: 저장소의 `agent-skills/` 13개(`orx-create`, `orx-compute`, `orx-experiment-tree`, `orx-evidence`, `orx-figures`, `orx-paper`, `orx-lit-review` 등)는 `orx` 명령과 앱의 프로젝트·실험 트리를 전제로 하는 앱 전용 스킬이라 `skills.list` 에 넣지 않았다. 필요하면 프로젝트에서 `orx install-skills`(기본은 이미 설치된 에이전트에 핵심 스킬만, `--full` 은 모듈형 `orx` 스킬 전체).
- **겹침**: `hyperresearch`(딥 리서치), Hugging Face 스킬(모델·데이터셋·학습)과 용도가 다르다. 이쪽은 실험을 git 트리로 기록하고 연산에서 실행하는 쪽이다.
- **점검 결과**: Linux x86_64 에서 실제 매니페스트 항목으로 `bootstrap.sh --tag autoresearch` 설치, `orx --version`(0.2.15), 재실행 건너뛰기 확인. `orx telemetry status/off` 동작 확인. `orx up`, `orx install-skills`, 연산 백엔드, macOS·Windows·aarch64 설치는 실행하지 않았다. 별 수와 관리형 연산 요금은 확인하지 못했다.
- **사용 예**: `orx telemetry off`, `orx --help`, 프로젝트에서 `orx up`

### pdf-inspector — PDF 분류·Markdown 변환 CLI
- **무엇**: Firecrawl 이 만든 Rust 기반 PDF 라이브러리(`firecrawl/pdf-inspector`, MIT)의 npm CLI `pdf-inspector`. PDF 가 텍스트 기반인지 스캔본인지 분류하고(`detect`), 텍스트 PDF 를 OCR 없이 로컬에서 Markdown 으로 바꾼다. 제목(글꼴 크기 비율), 목록, 코드 블록, 표, 다단 읽기 순서를 처리한다. 사용법: `pdf-inspector 문서.pdf`(Markdown), `--json`, `--pages 1,3,5`, `-o 파일`, `pdf-inspector detect 문서.pdf --json`(`TextBased`/`Scanned`/`ImageBased`/`Mixed`, 신뢰도, OCR 이 필요한 쪽 번호).
- **왜**: `markitdown` 과 같은 용도의 대안이다. 제작사 README 의 벤치마크(opendataloader-bench 200개 PDF, Apple M4 Pro, 2026-07-31 갱신)는 pdf-inspector 종합 0.875 · 200개 처리 0.47초, markitdown(0.1.5) 종합 0.589 · 16초로 보고한다. **제작사가 직접 측정한 값이라 검증하지 못했고**, 이 환경의 markitdown 은 0.1.8 이다. `markitdown` 은 Word·PPT·Excel·HTML 등도 다루고 이쪽은 PDF 만 다룬다.
- **설치**: `npm install -g @firecrawl/pdf-inspector@1.25.2`(**버전 고정**). 갱신하려면 `tools.list` 의 버전을 올린다.
- **출처 확인**: npm, PyPI(`pdf-inspector`), crates.io 세 곳 모두 저장소 주소가 `firecrawl/pdf-inspector` 이고 버전이 1.25.2 로 같다. npm 패키지에는 SLSA 출처 증명이 붙어 있고 설치 스크립트가 없다. 플랫폼별 네이티브 바이너리는 `@firecrawl/pdf-inspector-<플랫폼>` 별도 패키지(optionalDependencies)로 받는다. CLI 래퍼 소스(`napi/bin/pdf-inspector.mjs`)에는 네트워크·프로세스 호출이 없다. 네이티브 바이너리 자체는 감사하지 않았다.
- **점검 결과**: Linux x86_64 에서 실제 매니페스트 항목으로 `bootstrap.sh --tag pdf` 설치, `pdf-inspector --version`(1.25.2), 재실행 건너뛰기 확인. 직접 만든 2쪽짜리 텍스트 PDF 로 `detect`(TextBased)와 변환을 실행해 제목(`#`, `##`)과 목록이 정상 변환되고 홈 디렉터리에 파일을 만들지 않는 것을 확인했다.
- **알아둘 점**: ① 제목 판정이 추출 범위의 글꼴 크기 분포에 상대적이라, 한 쪽만 뽑으면(`--pages 2`) 본문 한 줄이 제목으로 오인되는 경우를 봤다. ② 짧은 문서에서는 `detect` 신뢰도가 낮게(0.5) 나왔다. ③ 스캔본·표·다단·한국어 PDF·선택적 OCR 은 시험하지 않았다. 선택적 OCR 은 네이티브 Python·Node 패키지에 들어 있고 PDFium·ONNX 런타임·모델이 별도로 필요하다고 README 가 밝힌다.
- **Python 라이브러리로 쓰려면**: `pip install pdf-inspector`(PyPI 패키지의 저장소 주소가 이 저장소와 일치). `pdf_inspector.process_pdf("문서.pdf")` 로 분류와 Markdown 을 얻는다. `bootstrap.sh` 는 설치하지 않는다.
- **사용 예**: `pdf-inspector detect 보고서.pdf --json` 으로 스캔본인지 먼저 확인한 뒤, 텍스트 PDF 만 `pdf-inspector 보고서.pdf -o 보고서.md`

### im-not-ai — 한글 AI 글투 제거 (스킬 `humanize-korean` 외 3개)
- **무엇**: `epoko77-ai/im-not-ai`(MIT, v2.3.2). AI 가 쓴 한글에서 번역투, 영어 인용 과다, 기계적 병렬("첫째·둘째·셋째"), "결론적으로" 류 관용구, 피동 남용 같은 티를 **문체·리듬만** 고쳐 사람이 쓴 글로 되돌린다. 스킬 4개: `humanize-korean`(오케스트레이터), `humanize`(진입 명령, 분량에 따라 light 1콜·standard 2콜·heavy 3+콜 경로 선택), `humanize-scan`(AI 티가 얼마나 있는지 재고 표본으로 보여줌), `humanize-redo`(직전 결과를 2차로 다듬음). 서브에이전트 4개(`humanize-monolith`, `humanize-diagnostician`, `humanize-finalizer`, `korean-ai-tell-taxonomist`)를 호출한다.
- **왜**: 위의 `blader/humanizer` 는 영어 전용이고, 한글 AI 글의 티는 대부분 영어 번역투에서 나온다. 한국어 쪽 짝으로 쓴다.
- **설치 방식이 다른 이유**: 스킬 폴더만 복사하는 `npx skills add` 로는 서브에이전트와 검증 스크립트 경로가 빠져 동작하지 않는다. 그래서 저장소 자체 설치기를 쓴다: `~/.local/share/im-not-ai` 에 클론(**검토한 커밋 `2f3d943` 에 고정**)하고 `install.sh --claude-only` 로 `~/.claude/skills/` 의 스킬 4개와 `~/.claude/agents/` 의 에이전트 4개를 **심볼릭 링크**로 연결한다. **클론을 지우면 링크가 끊긴다.** 저장소가 `--copy` 모드는 검증 게이트가 깨진다고 밝히므로 링크 방식만 쓴다. 기존 같은 이름의 파일이 있으면 덮어쓰지 않고 거부하며(`--force` 는 쓰지 않음), `settings.json` 은 건드리지 않는다.
- **Claude Code 필요**: `claude` 명령이나 `~/.claude` 가 없으면 설치기가 아무것도 하지 않고 **성공으로 끝나므로**, 이 항목은 앞단에서 확인해 명확한 메시지와 함께 **실패로 보고**한다. Claude Code 를 설치한 뒤 `bootstrap.sh --tools-only` 를 다시 실행한다. Codex·Gemini·Copilot 설치와 부속 스킬(`commit-ko`, `--extras`)은 하지 않는다.
- **갱신**: 링크가 클론을 가리키므로 `git -C ~/.local/share/im-not-ai checkout <새 커밋>` 으로 옮기면 반영된다(에이전트 목록이 바뀐 버전이면 `install.sh --claude-only` 재실행). 저장소의 `update.sh` 는 `git pull` 이라 고정과 맞지 않아 쓰지 않는다. `tools.list` 의 해시만 바꿔서는 이미 설치된 환경에 적용되지 않는다(링크가 있으면 건너뜀).
- **전역 에이전트 4개**: `humanize-*` 에이전트는 설명 매칭으로 자동 호출될 수 있어, 저장소는 윤문과 무관한 개발용 에이전트 5종을 일부러 설치에서 뺐다(`--all-agents` 로만 설치). 이 항목도 그 기본값을 따른다.
- **비용**: 한 번 윤문에 서브에이전트가 1~3+회 호출된다(light 1콜 · standard 2콜 · heavy 3+콜). `arena` 같은 대규모 호출은 아니다.
- **점검 결과**: 설치기(278줄)와 스킬이 쓰는 스크립트에 **네트워크 호출이 없고**, 서브프로세스는 개발용 `eval_baseline.py` 에만 있으며 설치되지 않는다. 훅이 없다(`.githooks/commit-msg` 는 저장소 개발용). 격리 환경에서 실제 매니페스트 항목으로 확인: `~/.claude` 가 없으면 명확한 메시지로 실패, 있으면 스킬 4개·에이전트 4개 설치, 재실행 건너뛰기. 설치된 클론에서 결정적 게이트 `verify_change_rate.py`·`verify_gates.py` 가 한국어 전후 예시 쌍(변경률 17%)에 대해 동작하고 통과를 보고했다.
- **미확인**: 스킬을 실제로 실행해 윤문 품질을 비교하지는 못했다. README 의 "내용은 한 글자도 건드리지 않는다"는 제작자의 설명이고, 게이트가 변경률 등은 검사하지만 의미 보존을 직접 검증하지는 못했다. 별 수도 확인하지 못했다.
- **사용 예**: Claude Code 에서 `/humanize-korean` 또는 "이 글 AI 티 없애줘", 먼저 재어 보려면 `/humanize-scan`
- **Windows**: 설치 스크립트가 심볼릭 링크를 요구한다. Git Bash 는 관리자 권한/개발자 모드가 없으면 `ln -s` 가 링크 대신 복사본을 만들고, 스크립트는 이를 감지해 중단하며 `--copy` 는 `scripts/` 게이트가 깨지므로 쓰지 말라고 안내한다(사용자 Windows 실행에서 확인). 그래서 Windows(Git Bash)에서는 `MSYS=winsymlinks:nativestrict` 없이 실행하면 설치를 시도하지 않고 "건너뜀"(종료 코드 75)으로 표시한다. WSL 설치가 권장이다. 이전 실행이 남긴 복사본이 있으면 확인해 정리한다.

---

## 검토 후 보류한 후보

| 프로젝트 | 보류 이유 |
|---|---|
| firecrawl/anydoc | markitdown 과 같은 용도. 속도·품질 비교 후 하나만 쓸 것. `npx @firecrawl/anydoc 파일` 로 즉시 시험 가능 |
| alibaba/open-code-review | 내장 `/code-review` 와 중복. 별도 LLM provider 설정(`ocr config provider`)이 필요 |
| StarTrail-org/PixelRAG | 스크린샷 기반 RAG. 저장소는 production-ready 라고 설명하지만 LEANN 과 역할이 겹쳐 필요할 때 추가. Claude Code 플러그인 `pixelbrowse` 제공 |
| MakazhanAlpamys/Soup | 이 PC 에 GPU 가 없어 검증 불가. 저장소는 RTX 3050 4GB 에서 8B 측정치와 논문을 제시하지만, 같은 문서의 최소 요구사양은 7B QLoRA 에 8GB VRAM 이라 서로 어긋난다 |
| mvanhorn/last30days-skill | 스킬 1개에 스크립트가 359개이고 Reddit·X 등 외부 서비스를 직접 수집한다. API 키와 수집 범위를 검토한 뒤 필요할 때 추가 |
| OthmanAdi/planning-with-files | 같은 스킬이 에이전트별 폴더와 번역본까지 18벌 들어 있는 구조라 `--skill` 이름이 모호하다. 내장 계획 기능과 `writing-plans` 와도 겹침 |
| Lum1104/Understand-Anything | 코드베이스 지식 그래프라 `graphify` 와 역할이 같다. 하나만 쓸 것 |
| JuliusBrussee/caveman | 에이전트 응답을 극단적으로 줄이는 스킬. 28개 스킬에 코드 파일 500여 개와 hook 이 있어 검토 범위가 크다. 쓰고 싶은 스킬만 골라 점검한 뒤 추가 |
| zarazhangrui/codebase-to-course | 코드베이스를 HTML 강의로 바꿔 주지만 LICENSE 파일이 없다. 라이선스 확인 후 추가 |
| sanyuan0704/code-review-expert | 내장 `/code-review`, `code-review-and-quality` 와 겹친다. SOLID 체크리스트가 필요할 때만 `code-review-expert` 1개 추가 |
| Orchestra-Research/AI-research-SKILLs | ML 연구 스킬 98개(RAG, 분산 학습, 멀티모달 등)로 범위가 너무 넓다. 필요한 분야(예: `11-evaluation`, `15-rag`)만 골라 추가 |
| dream-num/univer | 앱에 임베드하는 Office SDK(Apache-2.0) 모노레포라 에이전트 환경에 설치할 항목이 없다. 에이전트용은 별도 저장소다: `univer-cli`(Node 24 필요, 설치 경로가 `dream-num/skills` 를 거치고 `officecli` 와 역할이 겹침), `univer-sdk-skills`(스킬 4개, Univer 로 앱을 만들 때만 유용). 필요하면 후자만 추가 |
| ronald-koh/mattpock-skills-copilot | `mattpocock/skills` 를 GitHub Copilot 용으로 개작한 포크(14개). 컨텍스트·ADR 경로를 `.github/` 기준으로 바꿔 놓았고 LICENSE 파일이 없다. 겹치는 스킬은 이미 superpowers·addyosmani 에 있고 필요한 4개는 원본에서 직접 선별해 둠 |
| 21st-dev/skill | 스킬 7개(Apache-2.0, 작고 `name:` 이 폴더 이름과 같음)이지만 **전부 `21st` CLI(`@21st-dev/cli`)와 21st.dev 서비스**를 전제로 한다. CLI 와 계정·API 키는 이 저장소가 마련하지 못해 스킬만 있으면 동작하지 않는다. `21st-registry`·`21st-design-sync` 는 **공개 게시**를 한다(테마는 비공개 옵션이 없다고 스킬이 명시하고 게시 전 사용자 확인을 지시). `21st-ui-build`·`21st-ui-explore`·`21st-ui-review` 는 UI 작업 일반에 반응하고 `21st init --design-context`(프로젝트에 `.21st/` 생성)와 21st 검색을 쓰도록 해서 `ui-ux-pro-max`·`frontend-design`·`design-taste-frontend` 와 트리거가 겹친다. npm `@21st-dev/cli`(1.17.1, MIT)에는 저장소 주소 메타데이터가 없고 유지보수자는 개인 계정이다. 쓰고 싶으면 CLI 설치·로그인 뒤 명시적 의도가 필요한 `21st-cli-use`·`21st-ai` 부터 `npx skills add 21st-dev/skill --skill <이름>` 으로 추가한다. 설치·실행은 하지 않았다 |
| ruvnet/ruflo (구 claude-flow) | 스킬 저장소가 아니라 **에이전트 메타 하네스 시스템 전체**(MIT, 저장소 136MB)다. `SKILL.md` 379개(대부분 `.agents/`·`.claude/`·`plugins/` 등에 복제), 에이전트 381개, 명령 486개. `npx ruflo init` 은 훅 8개 이벤트(`PreToolUse`·`PostToolUse`·`UserPromptSubmit`·`SessionStart`·`SessionEnd`·`Stop`·`PreCompact`·`SubagentStop`)에서 `hook-handler.cjs` 를 실행하게 하고, MCP 서버(README 기준 도구 314개), 데몬·백그라운드 워커, 메모리 DB, 다른 머신과 통신하는 에이전트 연합 기능을 프로젝트에 심는다. 프로젝트 `.claude/skills` 39개 중 24개가 ruflo CLI·MCP 를 참조해 **시스템 없이는 동작하지 않는다**. 이 저장소의 목적(정의한 스킬이 모든 환경에 똑같이 설치됨)과 맞지 않고, 모든 도구 호출과 프롬프트를 가로채는 훅은 다른 스킬과 충돌할 수 있어 제외했다. 쓰고 싶으면 프로젝트별로 검토한 뒤 `npx ruflo init`, 또는 훅 없이 슬래시 명령·일부 스킬·에이전트 정의만 주는 Claude Code 플러그인 방식(README 비교표)을 쓴다. npm 패키지 `ruflo` 의 저장소 주소는 `ruvnet/claude-flow` 이다. 설치·실행은 하지 않았다 |
| genspark-ai/genoffice | 스킬 저장소가 아니라 **AI 오피스 스위트 데스크톱 앱**(Electron, macOS·Windows·Linux, Apache-2.0)이다. `genoffice` CLI(`@genoffice/cli`)는 `private` 패키지라 npm 에 없고 **앱과 함께 설치**되며, PDF 변환은 앱을 숨긴 창으로 띄워 처리하므로 앱 없이는 쓸 수 없다. 스킬(`npx skills add genspark-ai/genoffice`)만 설치하면 `genoffice` 명령이 없어 동작하지 않는다. 쓰고 싶으면 앱을 GitHub 릴리스(dmg·AppImage·deb·exe)에서 직접 설치한 뒤, 앱 Settings → Integrations 또는 `genoffice skill install claude` 로 스킬을, `genoffice mcp` 로 MCP(README 기준 도구 29개)를 연결한다. **⚠ 텔레메트리**: 공식 빌드는 GA4 익명 사용 통계가 기본 켜짐이고 온보딩 안내가 뜨기 전 첫 실행도 포함하며, Settings → General 에서 끈다(PRIVACY.md). 이미 있는 `officecli`, `docx`·`xlsx`·`pptx` 스킬, `pdf-inspector` 와 용도가 겹친다. 앱을 설치·실행하지 않았다 |
| MadsLorentzen/ai-job-search | 스킬 모음이 아니라 **프로젝트로 복제해서 프로필을 채워 쓰는 구직 워크플로 템플릿**(MIT)이다. 슬래시 명령 12개(`/setup`, `/apply`, `/interview`, `/rank` 등), 프로젝트 안의 프로필·문서·CV 템플릿, LaTeX(`lualatex`·`xelatex`)와 `bun` 이 전제라 스킬만 전역 설치해서는 동작하지 않는다. 포털 검색 스킬 6개 중 4개(`jobindex`, `jobnet`, `jobbank`, `jobdanmark`)는 덴마크 전용이고 `linkedin-search`·`freehire-search` 만 전 지역 대상이며, LinkedIn 을 긁는 방식이라 약관 위험이 있다. **⚠ 개인정보**: README 는 포크가 항상 공개이고 `/setup` 이 이름·연락처·경력·희망 연봉을 **git 이 추적하는 파일**에 쓰므로, 본인 구직용이면 포크하지 말고 **비공개 저장소에 이 저장소를 `upstream` 으로 연결**하라고 안내한다(SETUP.md 8절). 실제 구직에 쓸 때 별도 프로젝트로 그렇게 쓰는 것이 맞고, 이 저장소의 기본 설치에는 맞지 않는다. 설치·실행은 하지 않았다 |
| firecrawl/firecrawl | 크롤링·스크래핑 플랫폼 본체(AGPL-3.0)이고 에이전트용 CLI(`firecrawl-cli`)·MCP(`firecrawl-mcp`)는 별도 저장소다. 호스팅 서비스는 API 키가 필요해 `bootstrap.sh` 가 자동 설정할 수 없고, URL·페이지 내용이 `api.firecrawl.dev` 로 전송된다. 단일 페이지 읽기는 Playwright MCP·`agent-browser`·`markitdown`·내장 WebFetch 로 충분하다. 사이트 전체 크롤링·구조화 추출이 필요할 때 추가: 스킬은 `firecrawl/skills`(`npx skills add firecrawl/skills`), MCP 는 `FIRECRAWL_API_KEY` 환경 변수가 있을 때만 등록. 이 저장소 안의 `skills/firecrawl-build*` 5개는 자기 앱 코드에 Firecrawl API 를 통합할 때용. 요금제·`firecrawl/skills` 내용·CLI 텔레메트리는 확인하지 못했다 |
| multica-ai/andrej-karpathy-skills | 이미 설치 중인 `forrestchang/andrej-karpathy-skills` 와 같은 커밋(`2c60614`)·같은 파일 구성이고 `SKILL.md` 내용이 동일하다. 둘 다 넣으면 `karpathy-guidelines` 가 중복되므로 하나만 쓴다 |
| 666ghj/MiroFish | 스킬·CLI 저장소가 아니라 **멀티 에이전트 예측 시뮬레이션 웹 앱**(AGPL-3.0)이다. `SKILL.md` 가 없고, Flask 백엔드(5001)와 Vue 프런트엔드(3000)를 `npm run dev` 또는 Docker 로 띄워 쓰며 Node 18+·Python 3.11~3.12·uv 가 필요하다. LLM API 키(`LLM_API_KEY`)와 Zep Cloud 키(`ZEP_API_KEY`)가 있어야 동작하고 시뮬레이션 비용도 크다(저장소가 40라운드 미만 시험을 권장). 키·서버가 필요한 앱은 "클론하면 어디서나 같은 스킬" 이라는 이 저장소의 목적과 맞지 않는다. 필요하면 해당 저장소를 따로 클론해 실행할 것 (검토 커밋 `7657031`) |
| debpalash/VoiceStudio | 스킬 저장소가 아니라 **음성 복제·더빙·받아쓰기 데스크톱 앱**(Electron + Python, AGPL-3.0, 클론 44MB 와 서브모듈 1개)이다. 스킬 2개 중 `voicestudio`(87줄)는 **로컬에서 실행 중인 VoiceStudio 백엔드(`localhost:3900`) REST/MCP 를 부르는 클라이언트용**이라 앱과 모델이 없으면 쓸 수 없고, `voicestudio-maintainer` 는 이 앱의 이슈·PR·릴리스 관리자용이다. 스킬 하나를 위해 모든 환경이 44MB 를 클론하게 하지 않는다. 앱을 쓰는 사람만 `npx skills add debpalash/VoiceStudio --skill voicestudio` 로 따로 추가할 것 (검토 커밋 `28801c8`) |
