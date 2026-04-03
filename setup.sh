#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════
#  Smart Assistant — Project Setup
#  새 리포에서도 그대로 재현 가능합니다.
#
#  사전 조건:
#    - gh CLI 로그인 (gh auth login)
#    - az CLI 로그인 (az login)
#    - GitHub Copilot 라이선스 (Business/Enterprise)
#    - Fine-grained PAT (Issues + PRs + Contents RW)
# ═══════════════════════════════════════════════════════════

echo "╔══════════════════════════════════════════════════╗"
echo "║  Smart Assistant — Project Setup                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────
# Step 0: 사전 조건 확인
# ─────────────────────────────────────────────────────────
echo "📌 Step 0: 사전 조건 확인..."

# gh CLI
if ! command -v gh &>/dev/null; then
  echo "  ❌ gh CLI가 필요합니다: https://cli.github.com"
  exit 1
fi
echo "  ✅ gh CLI"

# az CLI
if ! command -v az &>/dev/null; then
  echo "  ❌ az CLI가 필요합니다: https://aka.ms/installazurecli"
  exit 1
fi
echo "  ✅ az CLI"

# 현재 리포 감지
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  echo "  ❌ GitHub 리포 루트에서 실행해주세요"
  exit 1
fi
OWNER=$(echo "$REPO" | cut -d'/' -f1)
echo "  ✅ 리포: $REPO"
echo ""

# ─────────────────────────────────────────────────────────
# Step 0.5: 프로젝트 설정 (도메인 정보 주입)
# ─────────────────────────────────────────────────────────
INSTRUCTIONS_FILE=".github/copilot-instructions.md"
if grep -q '{{BRAND_NAME}}' "$INSTRUCTIONS_FILE" 2>/dev/null; then
  echo "📌 Step 0.5: 프로젝트 설정..."
  echo ""

  read -rp "  브랜드명 (예: NovaHome): " BRAND_NAME
  if [ -z "$BRAND_NAME" ]; then
    echo "  ❌ 브랜드명은 필수입니다"; exit 1
  fi

  echo ""
  read -rp "  브랜드 설명 — 한 문장으로
  (예: NovaHome은 가전과 가구를 판매하는 스마트홈 브랜드입니다): " BRAND_DESC
  if [ -z "$BRAND_DESC" ]; then
    echo "  ❌ 브랜드 설명은 필수입니다"; exit 1
  fi

  echo ""
  read -rp "  챗봇 용도 (예: 고객을 위한 AI 제품 추천 챗봇): " BOT_PURPOSE
  if [ -z "$BOT_PURPOSE" ]; then
    echo "  ❌ 챗봇 용도는 필수입니다"; exit 1
  fi

  echo ""
  read -rp "  카탈로그 구조 설명 (예: 제품 카탈로그 (가전 + 가구, compatible_with 포함)): " CATALOG_STRUCTURE
  CATALOG_STRUCTURE=${CATALOG_STRUCTURE:-"제품 카탈로그"}

  echo ""
  read -rp "  경쟁사 목록 (예: 삼성, LG, 소니 등) [Enter=건너뛰기]: " COMPETITORS
  COMPETITORS=${COMPETITORS:-"경쟁사"}

  echo ""
  read -rp "  Azure 리전 [기본: koreacentral]: " AZURE_REGION
  AZURE_REGION=${AZURE_REGION:-koreacentral}

  BRAND_SLUG=$(echo "$BRAND_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
  APP_NAME="${BRAND_SLUG}-assistant"
  RESOURCE_GROUP="rg-${BRAND_SLUG}-demo"

  echo ""
  echo "  📋 설정 확인:"
  echo "    브랜드명:       $BRAND_NAME"
  echo "    앱 이름:        $APP_NAME"
  echo "    리소스 그룹:    $RESOURCE_GROUP"
  echo "    Azure 리전:     $AZURE_REGION"
  echo ""

  python3 -c "
import sys
f = sys.argv[1]
c = open(f).read()
pairs = [
    ('{{BRAND_NAME}}',        sys.argv[2]),
    ('{{BRAND_DESCRIPTION}}', sys.argv[3]),
    ('{{BOT_PURPOSE}}',       sys.argv[4]),
    ('{{CATALOG_STRUCTURE}}', sys.argv[5]),
    ('{{COMPETITORS}}',       sys.argv[6]),
    ('{{RESOURCE_GROUP}}',    sys.argv[7]),
    ('{{APP_NAME}}',          sys.argv[8]),
    ('{{AZURE_REGION}}',      sys.argv[9]),
]
for k, v in pairs:
    c = c.replace(k, v)
open(f, 'w').write(c)
" "$INSTRUCTIONS_FILE" "$BRAND_NAME" "$BRAND_DESC" "$BOT_PURPOSE" \
  "$CATALOG_STRUCTURE" "$COMPETITORS" "$RESOURCE_GROUP" "$APP_NAME" "$AZURE_REGION"

  echo "  ✅ copilot-instructions.md 설정 완료"
  echo ""
else
  echo "📌 Step 0.5: copilot-instructions.md 이미 설정됨 — 건너뜁니다"
  echo ""
fi

# ─────────────────────────────────────────────────────────
# Step 1: GitHub Project 생성 + 리포 연결
# ─────────────────────────────────────────────────────────
echo "📌 Step 1: GitHub Project 생성..."
REPO_NAME=$(echo "$REPO" | cut -d'/' -f2)
EXISTING_PROJECT=$(gh project list --owner @me --format json 2>/dev/null | grep -o "\"$REPO_NAME\"" || echo "")
if [ -n "$EXISTING_PROJECT" ]; then
  echo "  ✅ Project 이미 존재 — 건너뜁니다"
else
  gh project create --owner @me --title "$REPO_NAME" 2>/dev/null && \
    echo "  ✅ Project 생성 완료" || \
    echo "  ⚠️  생성 실패 — 건너뜁니다"
fi

# Project → 리포 연결
PROJECT_NUM=$(gh project list --owner @me --format json 2>/dev/null | python3 -c "
import json,sys
for p in json.load(sys.stdin).get('projects',[]):
  if p.get('title')=='$REPO_NAME':
    print(p['number']); break
" 2>/dev/null || echo "")
if [ -n "$PROJECT_NUM" ]; then
  gh project link "$PROJECT_NUM" --owner "$OWNER" --repo "$REPO" 2>/dev/null && \
    echo "  ✅ Project → 리포 연결 완료" || \
    echo "  ✅ 이미 연결됨"
fi
echo ""

# ─────────────────────────────────────────────────────────
# Step 2: Copilot Agent 방화벽 허용 목록
# ─────────────────────────────────────────────────────────
echo "📌 Step 2: Copilot Agent 방화벽 허용 목록..."
gh variable set COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS \
  --repo "$REPO" \
  --body "aka.ms,azcliprod.blob.core.windows.net" 2>/dev/null && \
  echo "  ✅ 방화벽 허용 목록 설정 완료" || \
  echo "  ⚠️  설정 실패 — 수동 설정 필요"
echo ""

# ─────────────────────────────────────────────────────────
# Step 3: Slack 알림 (선택)
# ─────────────────────────────────────────────────────────
echo "📌 Step 3: Slack 알림 설정 (선택)..."
EXISTING_SLACK=$(gh secret list --repo "$REPO" --json name --jq '.[].name' 2>/dev/null | grep "SLACK_WEBHOOK_URL" || echo "")
if [ -n "$EXISTING_SLACK" ]; then
  echo "  ✅ SLACK_WEBHOOK_URL 이미 존재 — 건너뜁니다"
else
  echo "  Self-heal 알림을 Slack으로 받으시겠습니까?"
  echo "  Webhook URL을 입력하세요 (건너뛰려면 Enter):"
  read -r SLACK_URL
  if [ -n "$SLACK_URL" ]; then
    echo "$SLACK_URL" | gh secret set SLACK_WEBHOOK_URL --repo "$REPO"
    echo "  ✅ SLACK_WEBHOOK_URL 등록 완료"
  else
    echo "  ⏭️  건너뜁니다 (나중에 수동 등록 가능)"
  fi
fi
echo ""

# ─────────────────────────────────────────────────────────
# Step 4: Issue 템플릿 + 라벨
# ─────────────────────────────────────────────────────────
echo "📌 Step 4: Issue 템플릿 + 라벨 등록..."

TEMPLATE_CONTENT='name: "📋 BDD 스토리"
description: "BDD 시나리오 기반 기능 요청 — Copilot이 구현합니다"
title: "[Story] "
labels: ["story"]
body:
  - type: markdown
    attributes:
      value: |
        ## BDD 스토리 작성 가이드
        Given/When/Then 형식으로 시나리오를 작성하세요.
        Copilot에게 할당하면 자동으로 구현됩니다.

  - type: textarea
    id: overview
    attributes:
      label: "개요"
      description: "이 스토리가 해결하는 문제를 설명하세요"
    validations:
      required: true

  - type: textarea
    id: scenarios
    attributes:
      label: "BDD 시나리오"
      description: "Given/When/Then 형식으로 작성하세요"
      value: |
        Feature: [기능 이름]

          Scenario: [시나리오 1]
            Given [사전 조건]
            When [사용자 행동]
            Then [기대 결과]
    validations:
      required: true

  - type: textarea
    id: requirements
    attributes:
      label: "요구사항"
      description: "기술적 요구사항, 제약 조건 등"
    validations:
      required: true

  - type: textarea
    id: acceptance
    attributes:
      label: "인수 조건"
      description: "완료 판단 기준"'

ENCODED=$(echo "$TEMPLATE_CONTENT" | base64)
EXISTING_TMPL=$(gh api "repos/$REPO/contents/.github/ISSUE_TEMPLATE/bdd-story.yml" --jq '.sha' 2>/dev/null)
TMPL_EXISTS=$?

if [ $TMPL_EXISTS -eq 0 ] && [ -n "$EXISTING_TMPL" ]; then
  echo "  ✅ Issue 템플릿 이미 존재 — 건너뜁니다"
else
  gh api --method PUT "repos/$REPO/contents/.github/ISSUE_TEMPLATE/bdd-story.yml" \
    -f message="add BDD story issue template" \
    -f content="$ENCODED" \
    --silent 2>/dev/null && \
    echo "  ✅ Issue 템플릿 등록 완료" || \
    echo "  ⚠️  등록 실패 — 건너뜁니다"
fi

# 라벨
gh label create "story" --description "BDD 스토리" --color "0E8A16" --repo "$REPO" 2>/dev/null || true
gh label create "self-heal" --description "자동 수정" --color "E11D48" --repo "$REPO" 2>/dev/null || true
echo "  ✅ Labels 등록 완료"
echo ""

# ─────────────────────────────────────────────────────────
# Step 5: GHAS 활성화
# ─────────────────────────────────────────────────────────
echo "📌 Step 5: GHAS (보안 기능) 안내..."
echo "  ⚠️  Private 리포는 수동 활성화가 필요합니다:"
echo "  → Settings → Code security and analysis"
echo "  → Secret scanning: Enable"
echo "  → Push protection: Enable"
echo "  → Dependabot alerts: Enable"
echo ""

# ─────────────────────────────────────────────────────────
# Step 6: Azure 인증 + GitHub Secret
# ─────────────────────────────────────────────────────────
echo "📌 Step 6: Azure 인증..."
if ! az account show &>/dev/null; then
  echo "  Azure 로그인이 필요합니다."
  az login
fi

ACCOUNT_NAME=$(az account show --query name -o tsv)
SUB_ID=$(az account show --query id -o tsv)
echo "  ✅ 구독: $ACCOUNT_NAME ($SUB_ID)"

SP_NAME="${REPO_NAME}-gh-actions"
echo "  Service Principal 생성 중..."
CREDS=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role contributor \
  --scopes "/subscriptions/$SUB_ID" \
  --sdk-auth 2>/dev/null)
echo "$CREDS" | gh secret set AZURE_CREDENTIALS --repo "$REPO"
echo "  ✅ AZURE_CREDENTIALS 등록 완료"

# Managed Identity 역할 할당을 위해 User Access Administrator 추가
SP_OBJECT_ID=$(echo "$CREDS" | python3 -c "import json,sys; print(json.load(sys.stdin)['clientId'])" 2>/dev/null)
if [ -n "$SP_OBJECT_ID" ]; then
  az role assignment create \
    --assignee "$SP_OBJECT_ID" \
    --role "User Access Administrator" \
    --scope "/subscriptions/$SUB_ID" \
    --only-show-errors 2>/dev/null && \
    echo "  ✅ User Access Administrator 역할 추가 완료" || \
    echo "  ⚠️  역할 추가 실패 — 수동 추가 필요"
fi
echo ""

# ─────────────────────────────────────────────────────────
# 완료
# ─────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅ Setup 완료!                                      ║"
echo "║                                                      ║"
echo "║  ✅ AZURE_CREDENTIALS (Service Principal)            ║"
echo "║  ✅ GitHub Project + 리포 연결                        ║"
echo "║  ✅ Issue 템플릿 + 라벨                               ║"
echo "║  ⚠️  GHAS: Settings → Code security에서 수동 활성화   ║"
echo "║                                                      ║"
echo "║  다음 단계:                                           ║"
echo "║  1. Issues → New Issue → 📋 BDD 스토리               ║"
echo "║  2. 스토리 작성 → Copilot 할당                        ║"
echo "║  3. Infra PR 머지 → 구현 PR 머지 → Azure 배포         ║"
echo "╚══════════════════════════════════════════════════════╝"
