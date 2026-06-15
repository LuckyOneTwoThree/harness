#!/bin/bash
# check-prd-changes.sh — 检测 PRD 变更，提示 Agent 重新读取
#
# 机制：session-start 调用，检测最近的 PRD 修改
# 输出变更的 PRD 列表，Agent 据此决定是否重新读取

set -e

CONTEXT_DIR=".harness/context/product"
FEATURES_FILE=".harness/features.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[PRD 变更检测]${NC}"

# 检查 context 目录是否存在
if [ ! -d "$CONTEXT_DIR" ]; then
    echo "  context/product/ 目录不存在，跳过"
    exit 0
fi

# 查找最近 24 小时内修改的 PRD 文件
CHANGED_PRDS=$(find "$CONTEXT_DIR" -name "PRD-*.md" -mtime -1 2>/dev/null || echo "")

if [ -z "$CHANGED_PRDS" ]; then
    echo -e "  ${GREEN}✅ 最近 24 小时内无 PRD 变更${NC}"
    exit 0
fi

echo -e "  ${YELLOW}⚠️  以下 PRD 最近 24 小时有变更：${NC}"
for prd in $CHANGED_PRDS; do
    # 提取 PRD 状态
    STATUS=$(grep -A5 "prd_status:" "$prd" 2>/dev/null | head -6 || echo "unknown")
    MODIFIED=$(stat -c '%y' "$prd" 2>/dev/null | cut -d'.' -f1 || stat -f '%Sm' "$prd" 2>/dev/null || echo "unknown")
    echo "    📄 $prd (修改时间: $MODIFIED)"
done

# 如果 features.json 存在，检查是否有任务引用了这些 PRD
if [ -f "$FEATURES_FILE" ]; then
    echo ""
    echo "  建议检查 features.json 中引用这些 PRD 的任务状态"
    echo "  如果 PRD 的验收标准有变更，可能需要重置相关任务状态"
fi

exit 0
