#!/bin/bash
# close-chat.sh — 会话收尾 + 学习捕获
#
# 在 Agent 会话结束前执行：
#   1. 总结本次改动
#   2. 提取教训（如有）
#   3. 更新 progress.md
#   4. 更新 features.json 状态
#   5. 生成归档提示（如果需要）
#
# 用法：Agent 会话结束前调用 bash .harness/skills/close-chat/run.sh
# 或由 Agent 手动执行总结流程

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🏁 Harness 会话收尾${NC}"
echo "========================"

PROGRESS_FILE=".harness/progress.md"
FEATURES_FILE=".harness/features.json"

# ---------- 1. 本次改动摘要 ----------
echo -e "${BLUE}[1/4] 本次改动${NC}"
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Git 仓库：获取最近提交
    COMMITS=$(git log --since="1 hour ago" --oneline 2>/dev/null || echo "")
    if [ -n "$COMMITS" ]; then
        COMMIT_COUNT=$(echo "$COMMITS" | wc -l | tr -d ' ')
        echo "  最近 1 小时内 $COMMIT_COUNT 个提交:"
        echo "$COMMITS" | head -5 | while read line; do
            echo "    - $line"
        done
        if [ "$COMMIT_COUNT" -gt 5 ]; then
            echo "    ... 还有 $((COMMIT_COUNT - 5)) 个"
        fi
    else
        echo "  最近 1 小时内无提交"
    fi
    
    # 文件变更统计
    if [ "$COMMIT_COUNT" -gt 0 ] 2>/dev/null; then
        CHANGED=$(git diff --stat HEAD~${COMMIT_COUNT} 2>/dev/null | tail -1 || echo "")
    else
        CHANGED=$(git diff --stat HEAD 2>/dev/null | tail -1 || echo "")
    fi
    if [ -n "$CHANGED" ]; then
        echo "  变更统计: $CHANGED"
    fi
else
    # 非 Git 环境降级：检查最近修改的文件
    echo "  非 Git 仓库，检查最近修改的文件..."
    RECENT_FILES=$(find . -maxdepth 3 -type f -mmin -60 \
        -not -path './.harness/archives/*' \
        -not -path './node_modules/*' \
        -not -path './.git/*' \
        -not -name '*.log' 2>/dev/null | head -10 || echo "")
    if [ -n "$RECENT_FILES" ]; then
        echo "  最近 1 小时内修改的文件:"
        echo "$RECENT_FILES" | while read line; do
            echo "    - $line"
        done
    else
        echo "  最近 1 小时内无文件变更"
    fi
fi

# ---------- 2. 守卫拦截统计 ----------
echo -e "\n${BLUE}[2/4] 安全守卫${NC}"
echo "  提示: 如本次会话有守卫拦截，应在 progress.md 中记录原因"

# ---------- 3. 进度文件检查 ----------
echo -e "\n${BLUE}[3/4] 进度文件${NC}"
if [ -f "$PROGRESS_FILE" ]; then
    LINES=$(wc -l < "$PROGRESS_FILE" | tr -d ' ')
    echo "  progress.md: $LINES 行"
    if [ "$LINES" -gt 150 ]; then
        echo -e "  ${YELLOW}⚠️  超过 150 行，建议运行归档: bash .harness/scripts/archive-progress.sh${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️  progress.md 不存在${NC}"
fi

# ---------- 4. 功能状态检查 ----------
echo -e "\n${BLUE}[4/4] 功能状态${NC}"
if [ -f "$FEATURES_FILE" ]; then
    IN_PROGRESS=$(grep -c '"status": "in_progress"' "$FEATURES_FILE" 2>/dev/null || echo 0)
    BLOCKED=$(grep -c '"status": "blocked"' "$FEATURES_FILE" 2>/dev/null || echo 0)
    if [ "$IN_PROGRESS" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️  有 $IN_PROGRESS 个功能仍在进行中，确保已记录到 progress.md${NC}"
    fi
    if [ "$BLOCKED" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️  有 $BLOCKED 个功能被阻塞，确保已通知相关方${NC}"
    fi
    if [ "$IN_PROGRESS" -eq 0 ] && [ "$BLOCKED" -eq 0 ]; then
        echo "  ✅ 所有功能状态正常"
    fi
fi

# ---------- 收尾提示 ----------
echo -e "\n========================"
echo -e "${GREEN}📋 收尾清单:${NC}"
echo "  □ progress.md 是否已更新？"
echo "  □ features.json 状态是否准确？"
echo "  □ 是否有教训需要记录到 .harness/rules/？"
echo "  □ 是否需要通知其他协作者？"
echo -e "${GREEN}✅ 会话收尾检查完成${NC}"
