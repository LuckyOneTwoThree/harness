#!/bin/bash
# guard-secret.sh — 密钥泄露守卫
# 检查暂存区文件中是否包含硬编码密钥
# 由 pre-commit.sh 调用，也可独立运行

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 获取待检查文件
if [ -n "$1" ]; then
    FILES="$1"
else
    FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo "")
fi

if [ -z "$FILES" ]; then
    exit 0
fi

echo -n "[guard-secret] 检查硬编码密钥... "

FOUND=0

for file in $FILES; do
    if [ -f "$file" ]; then
        # AWS Access Key
        if grep -qE "AKIA[0-9A-Z]{16}" "$file" 2>/dev/null; then
            echo ""
            echo -e "  ${RED}❌ $file: 疑似 AWS Access Key${NC}"
            FOUND=1
        fi
        # OpenAI API Key
        if grep -qE "sk-[a-zA-Z0-9]{20,}" "$file" 2>/dev/null; then
            echo ""
            echo -e "  ${RED}❌ $file: 疑似 OpenAI API Key${NC}"
            FOUND=1
        fi
        # GitHub Token
        if grep -qE "ghp_[a-zA-Z0-9]{36}" "$file" 2>/dev/null; then
            echo ""
            echo -e "  ${RED}❌ $file: 疑似 GitHub Token${NC}"
            FOUND=1
        fi
        # Stripe Key
        if grep -qE "sk_live_[a-zA-Z0-9]{20,}" "$file" 2>/dev/null; then
            echo ""
            echo -e "  ${RED}❌ $file: 疑似 Stripe Secret Key${NC}"
            FOUND=1
        fi
        # Generic password assignment
        if grep -E "(password|passwd|secret)\s*=\s*['\"][^'\"]{8,}" "$file" 2>/dev/null | grep -qvE "example|placeholder|harness:allow"; then
            echo ""
            echo -e "  ${YELLOW}⚠️  $file: 疑似硬编码密码${NC}"
            FOUND=1
        fi
    fi
done

if [ $FOUND -eq 1 ]; then
    echo -e "  ${RED}→ 使用环境变量替代硬编码密钥${NC}"
    exit 1
else
    echo -e "${GREEN}✅${NC}"
    exit 0
fi
