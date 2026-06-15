#!/bin/bash
# guard-sensitive-file.sh — 敏感文件守卫
# 阻止 .env、密钥文件、敏感配置被提交
# 由 pre-commit.sh 调用，也可独立运行

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -n "$1" ]; then
    FILES="$1"
else
    FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo "")
fi

if [ -z "$FILES" ]; then
    exit 0
fi

echo -n "[guard-sensitive-file] 检查敏感文件... "

SENSITIVE_PATTERNS="\.env$|\.env\.|credentials|secret\.json|private\.key|id_rsa|\.pem$|\.p12$|\.jks$|\.keystore$"
FOUND=0

for file in $FILES; do
    BASENAME=$(basename "$file" 2>/dev/null || echo "")
    if echo "$BASENAME" | grep -qiE "$SENSITIVE_PATTERNS"; then
        echo ""
        echo -e "  ${RED}❌ $file (敏感文件不应提交)${NC}"
        FOUND=1
    fi
done

if [ $FOUND -eq 1 ]; then
    echo -e "  ${RED}→ 添加到 .gitignore 并从暂存区移除: git rm --cached <file>${NC}"
    exit 1
else
    echo -e "${GREEN}✅${NC}"
    exit 0
fi
