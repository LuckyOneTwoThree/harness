#!/bin/bash
# pre-commit hook — 工程层硬兜底
# 每次 git commit 自动触发，Agent 无法绕过
#
# 调用链：pre-commit → guards/* + archive-progress
# 每个 guard 独立运行，单个失败不影响其他 guard

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=> Harness pre-commit hook"
echo "=========================="

ERRORS=0
HOOKS_DIR=".harness/hooks/guards"

# 获取暂存区文件列表（所有 guard 共用）
export STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo "")

# ---------- 运行各 guard ----------
for guard in "$HOOKS_DIR"/guard-*.sh; do
    if [ -f "$guard" ] && [ -x "$guard" ]; then
        bash "$guard" || ERRORS=$((ERRORS + 1))
    fi
done

# ---------- 自动归档记忆 ----------
# 系统管记忆，不靠 Agent 自觉
if [ -f .harness/scripts/archive-progress.sh ]; then
    bash .harness/scripts/archive-progress.sh
fi

# ---------- 汇总 ----------
echo "=========================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ pre-commit 失败: $ERRORS 个 guard 报错${NC}"
    exit 1
else
    echo -e "${GREEN}✅ pre-commit 通过${NC}"
    exit 0
fi
