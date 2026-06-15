#!/bin/bash
# validate-context.sh — 校验 context/ 目录的完整性和格式
#
# 检查项：
#   1. PRD 文件的 YAML frontmatter 是否完整
#   2. prd_status 各字段是否存在
#   3. DESIGN-TOKENS.json 是否为合法 JSON
#   4. 必填字段是否填写

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "🔍 校验 .harness/context/ 目录"
echo "========================"

# ---------- 1. PRD 文件检查 ----------
echo -n "[1/3] PRD 文件... "

PRD_DIR=".harness/context/product"
if [ ! -d "$PRD_DIR" ]; then
    echo -e "${YELLOW}⚠️  目录不存在${NC}"
else
    PRD_COUNT=$(find "$PRD_DIR" -name "PRD-*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PRD_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✅ (无 PRD 文件)${NC}"
    else
        echo ""
        for prd in "$PRD_DIR"/PRD-*.md; do
            [ -f "$prd" ] || continue
            BASENAME=$(basename "$prd")
            
            # 检查 YAML frontmatter
            if ! head -1 "$prd" | grep -q "^---"; then
                echo -e "  ${RED}❌ $BASENAME: 缺少 YAML frontmatter${NC}"
                ERRORS=$((ERRORS + 1))
                continue
            fi
            
            # 检查必填字段
            MISSING=""
            for field in "title" "prd_id" "version" "author"; do
                if ! grep -q "^$field:" "$prd"; then
                    MISSING="$MISSING $field"
                fi
            done
            
            if [ -n "$MISSING" ]; then
                echo -e "  ${RED}❌ $BASENAME: 缺少字段:$MISSING${NC}"
                ERRORS=$((ERRORS + 1))
            else
                echo -e "  ${GREEN}✅ $BASENAME${NC}"
            fi
        done
    fi
fi

# ---------- 2. DESIGN-TOKENS 检查 ----------
echo -n "[2/3] DESIGN-TOKENS... "

# 检查 python3 是否可用
if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  python3 不可用，跳过 JSON 校验${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    PYTHON_CMD="python3"
    command -v python3 >/dev/null 2>&1 || PYTHON_CMD="python"

TOKENS_FILE=".harness/context/design/DESIGN-TOKENS.json"
if [ ! -f "$TOKENS_FILE" ]; then
    EXAMPLE_FILE=".harness/context/design/DESIGN-TOKENS.json.example"
    if [ -f "$EXAMPLE_FILE" ]; then
        echo -e "${YELLOW}⚠️  只有 .example 文件，需要复制并填写${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${YELLOW}⚠️  文件不存在${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    # 校验 JSON 格式及内容完整性
    if $PYTHON_CMD -c "
import json, sys
try:
    data = json.load(open('$TOKENS_FILE'))
    required_paths = [
        ('color', 'error'),
        ('typography', 'fontSize'),
        ('zIndex',),
        ('opacity',),
        ('animation',),
        ('form',),
        ('icon',)
    ]
    for path in required_paths:
        curr = data
        for key in path:
            if key not in curr:
                print(f'Missing required token: {key}')
                sys.exit(1)
            curr = curr[key]
    sys.exit(0)
except Exception as e:
    print(str(e))
    sys.exit(1)
" 2>/dev/null; then
        echo -e "${GREEN}✅ 格式正确且字段完整${NC}"
    else
        echo -e "${RED}❌ JSON 格式错误或缺失必填 Token (如 zIndex, animation, form 等)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 关闭 python 可用性检查的 else 块
fi

# ---------- 3. 验收报告检查 ----------
echo -n "[3/3] 验收报告... "

ACCEPTANCE_DIR=".harness/context/acceptance"
if [ ! -d "$ACCEPTANCE_DIR" ]; then
    echo -e "${YELLOW}⚠️  目录不存在${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    REPORT_COUNT=$(find "$ACCEPTANCE_DIR" -name "AR-*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ ($REPORT_COUNT 份报告)${NC}"
fi

# ---------- 汇总 ----------
echo "========================"
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ 校验失败: $ERRORS 个错误, $WARNINGS 个警告${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  通过 (有 $WARNINGS 个警告)${NC}"
    exit 0
else
    echo -e "${GREEN}✅ 全部通过${NC}"
    exit 0
fi
