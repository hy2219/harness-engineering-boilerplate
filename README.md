# Harness Engineering Boilerplate

GitHub Copilot + Azure OpenAI 기반 **AI 챗봇 프로젝트 템플릿**입니다.

`setup.sh` 하나로 프로젝트를 초기화하면, Copilot이 BDD 스토리 기반으로 전체 코드를 생성합니다.

## 포함된 파일

```
.github/
  copilot-instructions.md   ← 프로젝트 청사진 (Copilot이 따르는 규칙)
  ISSUE_TEMPLATE/
    bdd-story.yml            ← BDD 스토리 입력 폼
setup.sh                     ← 프로젝트 초기화 (GitHub + Azure + 도메인 설정)
ghas.sh                      ← GitHub Advanced Security 토글
.env.example                 ← 환경변수 예시
.gitignore                   ← Python/Azure/IDE 무시 패턴
```

## 사용법

### 1. 이 템플릿으로 새 리포 생성

```bash
gh repo create my-smart-assistant --template hy2219/harness-engineering-boilerplate --public --clone
cd my-smart-assistant
```

### 2. 초기화

```bash
./setup.sh
```

실행하면 다음을 순서대로 진행합니다:

| 단계 | 내용 |
|------|------|
| Step 0 | gh CLI, az CLI 확인 |
| Step 0.5 | **프로젝트 설정** — 브랜드명, 설명, 챗봇 용도, 경쟁사, Azure 리전 입력 → `copilot-instructions.md`에 자동 주입 |
| Step 1 | GitHub Project 생성 + 리포 연결 |
| Step 2 | Copilot Agent 방화벽 허용 목록 |
| Step 3 | Slack 알림 설정 (선택) |
| Step 4 | Issue 템플릿 + 라벨 등록 |
| Step 5 | GHAS 안내 |
| Step 6 | Azure Service Principal + GitHub Secret 등록 |

### 3. 스토리 작성 → Copilot 할당

1. **Issues → New Issue → 📋 BDD 스토리** 로 기능 요청
2. Copilot에게 할당 → `spec-kit/`, `tests/`, `catalog.json` 자동 생성 (PR)
3. 머지 후 `[구현]` Issue 생성 → Copilot 할당
4. `infra/`, `app.py`, `workflows/`, `static/` 전부 자동 생성 (PR)
5. 머지 → Azure 배포 완료

## Copilot이 생성하는 것

| 단계 | 생성 파일 |
|------|----------|
| 스토리 분석 | `spec-kit/`, `tests/`, `catalog.json` |
| 구현 | `infra/main.bicep`, `.github/workflows/*`, `app.py`, `requirements.txt`, `static/` |
| Self-Heal | 실패 시 자동 수정 PR |

## 사전 조건

- [gh CLI](https://cli.github.com) 로그인
- [az CLI](https://aka.ms/installazurecli) 로그인
- GitHub Copilot 라이선스 (Business/Enterprise)
- Azure 구독

## 라이선스

MIT
