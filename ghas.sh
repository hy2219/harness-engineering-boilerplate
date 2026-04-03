#!/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════
#  GHAS Toggle — Public/Private 전환 + Secret Scanning
#
#  사용법:
#    ./ghas.sh on    → Public 전환 + GHAS 활성화
#    ./ghas.sh off   → Private 전환 + GHAS 비활성화
#    ./ghas.sh       → 현재 상태 확인
# ═══════════════════════════════════════════════════════════

REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
  echo "❌ GitHub 리포 루트에서 실행해주세요"
  exit 1
fi

ACTION=${1:-status}

case "$ACTION" in
  on)
    echo "🔓 Public 전환 + GHAS 활성화..."
    gh repo edit "$REPO" --visibility public --accept-visibility-change-consequences
    sleep 2
    gh repo edit "$REPO" --enable-secret-scanning --enable-secret-scanning-push-protection
    echo ""
    echo "✅ 완료!"
    echo "  - Visibility: public"
    echo "  - Secret Scanning: enabled"
    echo "  - Push Protection: enabled"
    ;;
  off)
    echo "🔒 Private 전환..."
    gh repo edit "$REPO" --visibility private --accept-visibility-change-consequences
    echo ""
    echo "✅ 완료!"
    echo "  - Visibility: private"
    echo "  - Secret Scanning: disabled (private에서는 GHAS 필요)"
    ;;
  status|*)
    STATUS=$(gh api "repos/$REPO" --jq '{
      visibility: .visibility,
      secret_scanning: .security_and_analysis.secret_scanning.status,
      push_protection: .security_and_analysis.secret_scanning_push_protection.status
    }' 2>/dev/null)
    echo "📊 현재 상태:"
    echo "$STATUS" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print(f\"  Visibility:      {d['visibility']}\")
print(f\"  Secret Scanning: {d.get('secret_scanning', 'n/a')}\")
print(f\"  Push Protection: {d.get('push_protection', 'n/a')}\")
" 2>/dev/null
    ;;
esac
