#!/bin/bash
# register-prd.sh — 将 PRD 注册到 features.json
#
# 用法：bash .harness/scripts/register-prd.sh <PRD文件路径>
# 示例：bash .harness/scripts/register-prd.sh .harness/context/product/PRD-2026-001-user-login.md
#
# 功能：
#   1. 解析 PRD 的 YAML frontmatter（prd_id、title、level）
#   2. 提取功能清单（F-xxx 编号）
#   3. 自动生成 features.json 条目
#   4. 设置 context_ref 指向该 PRD

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FEATURES_FILE=".harness/features.json"

# ---------- 参数检查 ----------
if [ -z "$1" ]; then
    echo -e "${RED}用法: bash .harness/scripts/register-prd.sh <PRD文件路径>${NC}"
    echo "示例: bash .harness/scripts/register-prd.sh .harness/context/product/PRD-2026-001-user-login.md"
    exit 1
fi

PRD_FILE="$1"

if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}❌ 文件不存在: $PRD_FILE${NC}"
    exit 1
fi

# ---------- 检查 features.json ----------
if [ ! -f "$FEATURES_FILE" ]; then
    echo -e "${RED}❌ features.json 不存在，请先运行 init-project.sh${NC}"
    exit 1
fi

# ---------- 解析 PRD frontmatter ----------
echo "📄 解析 PRD: $PRD_FILE"

# 提取 prd_id
PRD_ID=$(grep "^prd_id:" "$PRD_FILE" 2>/dev/null | head -1 | sed 's/prd_id: *//' | tr -d '"' || echo "")
if [ -z "$PRD_ID" ]; then
    echo -e "${RED}❌ PRD 缺少 prd_id 字段${NC}"
    exit 1
fi

# 提取 title
PRD_TITLE=$(grep "^title:" "$PRD_FILE" 2>/dev/null | head -1 | sed 's/title: *//' | tr -d '"' || echo "未知功能")

# 推断 level（从文件名，与 check-dor.sh 保持一致）
# -M- 或 TEMPLATE-M → M 级（轻量需求）
# 其他 → L 级（完整需求）
# S 级（口头需求）不需要 PRD，不会走到 register-prd.sh
if echo "$PRD_FILE" | grep -qE "\-M[\-\.]|TEMPLATE-M"; then
    LEVEL="M"
else
    LEVEL="L"
fi

# 提取功能编号列表（F-xxx）
FEATURES=$(grep -oE "F-[0-9]+" "$PRD_FILE" 2>/dev/null | sort -u || echo "")

echo "  PRD ID: $PRD_ID"
echo "  标题: $PRD_TITLE"
echo "  级别: $LEVEL"
if [ -n "$FEATURES" ]; then
    echo "  功能编号: $(echo $FEATURES | tr '\n' ' ')"
fi

# ---------- 检查是否已注册 ----------
if grep -q "\"context_ref\": \"$PRD_FILE\"" "$FEATURES_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  该 PRD 已注册到 features.json，跳过${NC}"
    exit 0
fi

# ---------- 生成 features.json 条目 ----------
# 获取当前最大 ID
MAX_ID=$(grep -oE '"id": "F[0-9]+"' "$FEATURES_FILE" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1 || echo "0")
NEW_ID_NUM=$((MAX_ID + 1))
NEW_ID="F$(printf '%03d' $NEW_ID_NUM)"

# 获取今天的日期
TODAY=$(date +%Y-%m-%d)

# 读取 prd_status
PRODUCT_STATUS=$(grep -A1 "product:" "$PRD_FILE" 2>/dev/null | tail -1 | grep -oE "pending|done" || echo "pending")
DEV_STATUS=$(grep -A1 "development:" "$PRD_FILE" 2>/dev/null | tail -1 | grep -oE "pending|done" || echo "pending")
TESTING_STATUS=$(grep -A1 "testing:" "$PRD_FILE" 2>/dev/null | tail -1 | grep -oE "pending|done" || echo "pending")
APPROVED=$(grep "approved_by:" "$PRD_FILE" 2>/dev/null | grep -v "null" | grep -v "approved_by: null" || echo "")

# 判断初始状态
if [ -n "$APPROVED" ] && [ "$PRODUCT_STATUS" = "done" ]; then
    INITIAL_STATUS="pending"
    echo -e "  ${GREEN}DoR: 已满足，任务可开发${NC}"
else
    INITIAL_STATUS="blocked"
    echo -e "  ${YELLOW}DoR: 未满足，任务标记为 blocked${NC}"
fi

# 构建 JSON 条目
NEW_ENTRY=$(cat <<EOF
    {
      "id": "$NEW_ID",
      "name": "$PRD_TITLE",
      "status": "$INITIAL_STATUS",
      "priority": "high",
      "description": "来源: $PRD_ID",
      "level": "$LEVEL",
      "context_ref": "$PRD_FILE",
      "parent_ref": null,
      "owner": "unassigned",
      "created": "$TODAY",
      "updated": "$TODAY",
      "tests": {
        "unit": false,
        "integration": false,
        "e2e": false
      }
    }
EOF
)

# ---------- 写入 features.json ----------
# 使用 python3 操作 JSON（跨平台兼容，替代 sed -i）
python3 -c "
import json, sys

features_file = '$FEATURES_FILE'
new_entry_json = '''$NEW_ENTRY'''

try:
    new_entry = json.loads(new_entry_json)
except:
    print('❌ JSON 解析失败')
    sys.exit(1)

with open(features_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

if 'features' not in data:
    data['features'] = []

data['features'].append(new_entry)

with open(features_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>/dev/null

if [ $? -ne 0 ]; then
    # python3 不可用时 fallback 到 sed
    if grep -q '"features": \[\]' "$FEATURES_FILE" 2>/dev/null; then
        sed -i "s|\"features\": \[\]|\"features\": [\n$NEW_ENTRY\n  ]|" "$FEATURES_FILE"
    else
        sed -i "/\"features\": \[/,/^\\s*]/ {
            /^\\s*]/i\\
$NEW_ENTRY,
        }" "$FEATURES_FILE"
    fi
fi

echo -e "${GREEN}✅ 已注册到 features.json: $NEW_ID${NC}"
echo "  文件: $FEATURES_FILE"
echo "  条目: $NEW_ID - $PRD_TITLE ($LEVEL 级, 状态: $INITIAL_STATUS)"
