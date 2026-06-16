#!/bin/bash
# session-start.sh — Agent 会话启动钩子
#
# 在 Agent 开始工作前执行，自动加载上下文：
#   1. 读取进度文件，了解当前状态
#   2. 读取功能清单，了解待办事项
#   3. 读取环境配置，了解基础设施
#   4. 输出会话摘要，帮 Agent 快速进入状态
#
# 用法：Agent 启动时调用 bash .harness/hooks/session-start.sh

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Harness 会话启动${NC}"
echo "========================"

# ---------- 1. 项目基本信息 ----------
echo -e "${BLUE}[1/4] 项目信息${NC}"
if [ -f "AGENTS.md" ]; then
    # 提取 AGENTS.md 中的项目名称（第一个 # 标题）
    PROJECT_NAME=$(head -5 AGENTS.md 2>/dev/null | grep "^#" | head -1 | sed 's/^#* *//' || echo "未知项目")
    echo "  项目: $PROJECT_NAME"
fi
echo "  分支: $(git branch --show-current 2>/dev/null || echo '非 Git 仓库')"
echo "  时间: $(date '+%Y-%m-%d %H:%M:%S')"

# ---------- 2. 进度状态 ----------
echo -e "\n${BLUE}[2/4] 进度状态${NC}"
PROGRESS_FILE=".harness/progress.md"
if [ -f "$PROGRESS_FILE" ]; then
    LINES=$(wc -l < "$PROGRESS_FILE" | tr -d ' ')
    echo "  progress.md: $LINES 行"
    # 提取最新一条记录
    LAST_ENTRY=$(grep -n "^### " "$PROGRESS_FILE" 2>/dev/null | tail -1 || echo "")
    if [ -n "$LAST_ENTRY" ]; then
        echo "  最新记录: $LAST_ENTRY"
    fi
else
    echo -e "  ${YELLOW}⚠️  progress.md 不存在，这是新项目或首次会话${NC}"
fi

# ---------- 3. 功能清单 ----------
echo -e "\n${BLUE}[3/4] 功能清单${NC}"
FEATURES_FILE=".harness/features.json"
if [ -f "$FEATURES_FILE" ]; then
    # 用 python3 精确解析 JSON（避免 grep 误计）
    if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python3"
        command -v python3 >/dev/null 2>&1 || PYTHON_CMD="python"
        $PYTHON_CMD -c "
import json
with open('$FEATURES_FILE') as f:
    data = json.load(f)
features = data.get('features', [])
total = len(features)
done = sum(1 for f in features if f.get('status') == 'done')
blocked = sum(1 for f in features if f.get('status') == 'blocked')
in_progress = sum(1 for f in features if f.get('status') == 'in_progress')
print(f'  总计: {total} | 完成: {done} | 进行中: {in_progress} | 阻塞: {blocked}')
" 2>/dev/null || echo "  ⚠️  JSON 解析失败"
    else
        # fallback: grep（精度较低但不依赖 python）
        TOTAL=$(grep -c '"id"' "$FEATURES_FILE" 2>/dev/null || echo 0)
        DONE=$(grep -c '"status": "done"' "$FEATURES_FILE" 2>/dev/null || echo 0)
        BLOCKED=$(grep -c '"status": "blocked"' "$FEATURES_FILE" 2>/dev/null || echo 0)
        IN_PROGRESS=$(grep -c '"status": "in_progress"' "$FEATURES_FILE" 2>/dev/null || echo 0)
        echo "  总计: $TOTAL | 完成: $DONE | 进行中: $IN_PROGRESS | 阻塞: $BLOCKED"
    fi
else
    echo -e "  ${YELLOW}⚠️  features.json 不存在${NC}"
fi

# ---------- 4. 环境感知 ----------
echo -e "\n${BLUE}[4/4] 环境感知${NC}"
if [ -f ".env.example" ]; then
    echo "  ✅ .env.example 存在（Agent 应在启动前读取）"
else
    echo -e "  ${YELLOW}⚠️  .env.example 不存在${NC}"
fi
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "  ✅ docker-compose 存在"
fi
if [ -f "Makefile" ]; then
    # 提取 Makefile 中的所有 target
    TARGETS=$(grep -E "^[a-zA-Z_-]+:" Makefile 2>/dev/null | head -5 | sed 's/:.*//' | tr '\n' ', ' || echo "")
    if [ -n "$TARGETS" ]; then
        echo "  可用命令: $TARGETS"
    fi
fi

# ---------- 5. 安全守卫状态 ----------
echo -e "\n${BLUE}[安全] 守卫状态${NC}"
GUARDS_DIR=".harness/hooks/guards"
if [ -d "$GUARDS_DIR" ]; then
    GUARD_COUNT=$(find "$GUARDS_DIR" -name "guard-*.sh" 2>/dev/null | wc -l | tr -d ' ')
    echo "  已加载 $GUARD_COUNT 个安全守卫"
else
    echo -e "  ${YELLOW}⚠️  守卫目录不存在${NC}"
fi

# ---------- 6. PRD 变更检测 ----------
echo -e "\n${BLUE}[PRD] 变更检测${NC}"
if [ -f ".harness/scripts/check-prd-changes.sh" ]; then
    bash .harness/scripts/check-prd-changes.sh
else
    echo "  check-prd-changes.sh 不存在，跳过"
fi

echo -e "\n========================"
echo -e "${GREEN}✅ 会话启动完成，Agent 可以开始工作${NC}"
