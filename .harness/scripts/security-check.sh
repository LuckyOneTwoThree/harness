#!/bin/bash
# security-check.sh — 安全扫描（CI 用）
#
# 架构：调用 guards/ 中的模块化检查 + 补充 guards 没覆盖的检查
# 避免与 guards 重复维护逻辑
#
# 检查项：
#   1. 调用 guard-secret.sh（硬编码密钥）
#   2. 调用 guard-bash.sh（危险命令）
#   3. 调用 guard-sensitive-file.sh（敏感文件）
#   4. 安全配置篡改（guards 没覆盖）
#   5. .gitignore 完整性（guards 没覆盖）

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "🔒 Harness 安全扫描"
echo "========================"

GUARDS_DIR=".harness/hooks/guards"

# ---------- 检查 1-3: 调用 guards ----------
for guard in guard-secret.sh guard-bash.sh guard-sensitive-file.sh; do
    GUARD_PATH="$GUARDS_DIR/$guard"
    if [ -f "$GUARD_PATH" ] && [ -x "$GUARD_PATH" ]; then
        bash "$GUARD_PATH" || ERRORS=$((ERRORS + 1))
    else
        echo -e "${YELLOW}⚠️  $guard 不存在或无执行权限，跳过${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# ---------- 检查 4: 安全配置篡改（guards 没覆盖）----------
echo -n "[security-check] 安全配置篡改... "

if git rev-parse --git-dir > /dev/null 2>&1; then
    FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || echo "")
    if [ -z "$FILES" ]; then
        FILES=$(git ls-files 2>/dev/null || echo "")
    fi
else
    FILES=$(find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \
        -o -name "*.java" -o -name "*.go" -o -name "*.yaml" -o -name "*.yml" \) \
        2>/dev/null | grep -v node_modules | grep -v .git || echo "")
fi

SECURITY_BYPASS="eslint-disable|noqa|@ts-ignore|nosec|verify\s*=\s*False|--no-verify"
BYPASS_FOUND=0
for file in $FILES; do
    if [ -f "$file" ]; then
        MATCHES=$(grep -nE "$SECURITY_BYPASS" "$file" 2>/dev/null | grep -v "# harness:allow" || true)
        if [ -n "$MATCHES" ]; then
            echo ""
            echo -e "  ${YELLOW}⚠️  $file${NC}"
            echo "$MATCHES" | head -3
            BYPASS_FOUND=1
        fi
    fi
done
if [ $BYPASS_FOUND -eq 1 ]; then
    WARNINGS=$((WARNINGS + 1))
    echo -e "  ${YELLOW}→ 需要注释说明理由 (加 # harness:allow 豁免)${NC}"
else
    echo -e "${GREEN}✅${NC}"
fi

# ---------- 检查 5: .gitignore 完整性（guards 没覆盖）----------
echo -n "[security-check] .gitignore 完整性... "
if [ -f ".gitignore" ]; then
    MISSING=""
    for pattern in ".env" "*.key" "*.pem" "node_modules" "__pycache__" ".DS_Store"; do
        if ! grep -q "$pattern" .gitignore 2>/dev/null; then
            MISSING="$MISSING $pattern"
        fi
    done
    if [ -n "$MISSING" ]; then
        echo -e "${YELLOW}⚠️  缺少:$MISSING${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✅${NC}"
    fi
else
    echo -e "${RED}❌ 缺少 .gitignore 文件${NC}"
    ERRORS=$((ERRORS + 1))
fi

# ---------- 汇总 ----------
echo "========================"
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ 安全检查失败: $ERRORS 个错误, $WARNINGS 个警告${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  通过 (有 $WARNINGS 个警告需关注)${NC}"
    exit 0
else
    echo -e "${GREEN}✅ 安全扫描全部通过${NC}"
    exit 0
fi
