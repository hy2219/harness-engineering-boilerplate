<!-- setup.sh를 실행하면 {{PLACEHOLDER}} 값이 자동으로 채워집니다 -->
# {{BRAND_NAME}} Smart Assistant — Copilot Instructions

## 프로젝트

{{BRAND_DESCRIPTION}}

이 프로젝트는 {{BRAND_NAME}} {{BOT_PURPOSE}}입니다.

## 개발 방향

### Spec-Driven Development
- 구현 전에 스펙을 먼저 정의합니다
- BDD (Given/When/Then) 스토리 기반으로 테스트를 먼저 작성합니다
- 테스트가 통과하는 구현체를 만듭니다

### Harness Engineering
- **Planner**: 요구사항 분석, 태스크 분해
- **Generator**: 코드 생성, 아티팩트 생산
- **Evaluator**: 품질·보안·스펙 검증

### SDLC Pipeline
- GitHub Actions로 CI/CD를 구성합니다
- PR 생성 시 테스트 + 보안 스캔
- main 머지 시 Azure 배포
- 인프라 변경 시 Azure 리소스 프로비저닝
- **워크플로우 파일도 직접 작성합니다**

### 배포 환경
- **클라우드**: Azure ({{AZURE_REGION}})
- **인증**: GitHub Secret `AZURE_CREDENTIALS` (Service Principal)
- **인프라**: Bicep으로 정의, GitHub Actions로 배포

## 작업 규칙

스토리를 받으면 **반드시 아래 순서대로** 진행합니다. 순서를 건너뛰지 마세요.

### 스토리를 받았을 때 (분석)

**코드를 작성하지 마세요.** 분석과 설계만 합니다.

1. 스토리를 분석하고 필요한 인프라와 코드 변경 범위를 파악합니다
2. 현재 리포 상태를 확인합니다 (기존 인프라, 코드, 워크플로우 유무)
3. 아래 파일을 작성합니다:
   - `spec-kit/architecture.md` — 시스템 아키텍처 (컴포넌트, 데이터 흐름, 기술 스택 선택 이유)
   - `spec-kit/SKILL.md` — 에이전트별 역할, 트리거 키워드, 입출력 정의
   - `tests/` — BDD 시나리오 기반 테스트 코드 (stubbing 활용, 외부 시스템 의존 없이)
   - `catalog.json` — {{CATALOG_STRUCTURE}}
3. PR 설명에 다음을 명시합니다:
   - 전체 구현 방향 요약
   - 인프라 변경 사항 (Azure 리소스 목록)
   - 생성/변경될 파일 목록
   - 테스트 커버리지 설명
4. **앱 코드(app.py 등), 인프라 코드(infra/), CI/CD 워크플로우, static/ UI는 포함하지 마세요**

### [구현] Issue를 받았을 때

이미 머지된 spec-kit/, tests/, catalog.json을 기반으로 **완전한 구현**을 합니다.

1. `infra/main.bicep` — 필요한 Azure 리소스 전체
   - Azure OpenAI 계정 + GPT-4o 배포
   - App Service Plan + Web App (Linux)
   - Managed Identity + 역할 할당 (OpenAI 접근)
   - App Settings (엔드포인트, 배포명, 인증 방식 등)
   - 리소스 그룹: `{{RESOURCE_GROUP}}`, 지역: `{{AZURE_REGION}}`, 앱: `{{APP_NAME}}`
2. `.github/workflows/` — CI, CD, Infra 파이프라인
   - 모든 워크플로우에서 `secrets.AZURE_CREDENTIALS` 사용
3. `requirements.txt`, `.env.example`, `.gitignore`
4. 앱 코드 — 기존 테스트가 통과하는 구현체
5. `static/` — 웹 채팅 UI
6. **모든 테스트가 통과해야 PR 제출**

### 기타 규칙
- 시크릿은 절대 코드에 하드코딩하지 않습니다
- 채팅 응답은 **한국어**로 합니다
- Azure 인증은 Managed Identity 사용 (API Key 아님)

### Self-Healing
- `self-heal.yml` 워크플로우가 CI/CD/Infra 실패 시 자동으로 `[Self-Heal]` Issue를 생성합니다
- 이 Issue에는 에러 로그가 포함되어 있습니다
- `[Self-Heal]` Issue를 받으면 에러를 분석하고 수정 PR을 제출합니다
- **다음에 같은 문제가 발생하지 않도록 근본 원인을 수정**합니다

### Azure 제약 사항 (반드시 준수)
- {{AZURE_REGION}} 리전에서 GPT-4o 모델의 SKU는 **`GlobalStandard`** (Standard 아님, 리전별 확인 필요)
- App Service는 **Linux B1** 플랜
- Bicep에서 `appSettings`를 `siteConfig` 안에 직접 넣지 말고 별도 `Microsoft.Web/sites/config` 리소스로 분리하거나 순환 참조가 없는지 확인

### CI/CD 워크플로우 규칙 (반드시 준수)
- 모든 워크플로우에 **`workflow_dispatch:` 트리거를 포함**합니다 (수동 재실행 가능하게)
- Infra 워크플로우는 `paths: ['infra/**']`로 infra 변경 시에만 실행합니다
- **CD 워크플로우는 Infra 완료 후 실행**되어야 합니다:
  - `needs: [infra]` 또는 Infra 완료 후 별도 트리거
  - 인프라와 앱 코드가 동시에 변경되면 CD가 먼저 실행되어 실패할 수 있습니다
  - 방법 1: CD에 `paths`로 앱 코드만 트리거 + `infra/**` 제외 + Infra 완료를 기다리는 `workflow_run` 트리거 추가
  - 방법 2: 하나의 워크플로우에 infra → deploy 순서로 job을 구성 (`needs`)
- CD 워크플로우에서 `pip install -r requirements.txt`를 포함하거나, `SCM_DO_BUILD_DURING_DEPLOYMENT=true` app setting을 설정해야 합니다

### 회사 규정 (반드시 준수)

#### 비즈니스 규정
- 모든 제품 추천 응답에 **"{{BRAND_NAME}}"** 브랜드명을 포함합니다
- 가격 표시는 반드시 **₩1,200,000** 형식 (원화 기호 + 콤마 구분)
- **경쟁사 제품명({{COMPETITORS}})을 언급하지 않습니다**
- 품절 상품은 추천하지 않고 **대안 제품을 제시**합니다
- 모든 추천 응답 마지막에 disclaimer 포함: **"※ AI 추천이며 실제 재고·가격과 다를 수 있습니다"**

#### 기술 규정
- 모든 API 엔드포인트에 **입력 검증 (validation)** 필수
- 사용자 입력은 **500자 이내**로 제한
- API 응답은 **표준 JSON 포맷** 사용: `{"success": bool, "data": ..., "error": ...}`
- 모든 에러는 **한국어 에러 메시지**로 응답
- 로그에 **개인정보(이름, 전화번호, 주소)를 기록하지 않습니다**
