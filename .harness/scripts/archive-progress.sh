#!/bin/bash
# archive-progress.sh — 自动归档 progress.md，防止 Context 爆炸
#
# 机制：系统级脚本，不依赖 Agent 自觉执行。
# 由 pre-commit hook 自动触发，也可手动运行。
#
# 规则：
#   - progress.md 超过 MAX_LINES 行时，自动将旧条目归档
#   - 归档文件按日期命名，存入 .harness/archives/
#   - progress.md 只保留最近 KEEP_LINES 行
#   - 归档后生成索引，方便后续检索

set -e

HARNESS_DIR=".harness"
PROGRESS_FILE="$HARNESS_DIR/progress.md"
ARCHIVE_DIR="$HARNESS_DIR/archives"
INDEX_FILE="$ARCHIVE_DIR/INDEX.md"

# 配置（可按项目调整）
MAX_LINES=${HARNESS_ARCHIVE_THRESHOLD:-150}
KEEP_LINES=${HARNESS_KEEP_LINES:-60}

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "$PROGRESS_FILE" ]; then
    exit 0
fi

CURRENT_LINES=$(wc -l < "$PROGRESS_FILE" | tr -d ' ')

if [ "$CURRENT_LINES" -le "$MAX_LINES" ]; then
    echo -e "${GREEN}✅ progress.md ($CURRENT_LINES 行) 未超过阈值 ($MAX_LINES 行)，跳过归档${NC}"
    exit 0
fi

echo -e "${YELLOW}📦 progress.md 已有 $CURRENT_LINES 行，开始归档...${NC}"

mkdir -p "$ARCHIVE_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_FILE="$ARCHIVE_DIR/progress_${TIMESTAMP}.md"
ARCHIVE_LINES=$((CURRENT_LINES - KEEP_LINES))

# 提取旧内容归档
head -n "$ARCHIVE_LINES" "$PROGRESS_FILE" > "$ARCHIVE_FILE"

# 保留最近内容 + 归档标记
{
    echo "> ⚠️ 此文件已自动归档。更早的记录请查阅 \`.harness/archives/\`"
    echo "> 归档时间: $(date '+%Y-%m-%d %H:%M:%S') | 归档: $ARCHIVE_LINES 行 | 保留: $KEEP_LINES 行"
    echo ""
    tail -n "$KEEP_LINES" "$PROGRESS_FILE"
} > "${PROGRESS_FILE}.tmp"

mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"

# 更新索引
if [ ! -f "$INDEX_FILE" ]; then
    {
        echo "# Progress 归档索引"
        echo ""
        echo "> 自动维护，勿手动编辑。检索历史时先读此文件定位，再按需读取具体归档。"
        echo ""
        echo "| 归档时间 | 文件 | 归档行数 |"
        echo "|----------|------|----------|"
    } > "$INDEX_FILE"
fi
echo "| $(date '+%Y-%m-%d %H:%M') | progress_${TIMESTAMP}.md | $ARCHIVE_LINES |" >> "$INDEX_FILE"

echo -e "${GREEN}✅ 归档完成: $ARCHIVE_FILE ($ARCHIVE_LINES 行)${NC}"
