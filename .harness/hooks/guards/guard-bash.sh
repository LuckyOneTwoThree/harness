#!/bin/bash
# guard-bash.sh — 危险命令守卫
# 检查代码文件中是否包含破坏性 shell 命令
# 由 pre-commit.sh 调用，也可独立运行

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ -n "$1" ]; then
    FILES="$1"
else
    FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo "")
fi

if [ -z "$FILES" ]; then
    exit 0
fi

echo -n "[guard-bash] 检查危险命令... "

DANGEROUS_CMDS="rm\s+-rf\s+/|rm\s+-fr\s+/|DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE|chmod\s+777|curl.*\|\s*sh|wget.*\|\s*sh"
FOUND=0

for file in $FILES; do
    if [ -f "$file" ]; then
        if grep -qiE "$DANGEROUS_CMDS" "$file" 2>/dev/null; then
            echo ""
            echo -e "  ${RED}❌ $file${NC}"
            grep -niE "$DANGEROUS_CMDS" "$file" 2>/dev/null | head -3
            FOUND=1
        fi
    fi
done

if [ $FOUND -eq 1 ]; then
    echo -e "  ${RED}→ 高危命令需要显式人工审批${NC}"
    exit 1
else
    echo -e "${GREEN}✅${NC}"
    exit 0
fi
