#!/bin/bash
# pre-push hook — 推送前检查
# 调用 guard-commit-msg + 其他推送级检查

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=> Harness pre-push hook"
echo "========================"

# ---------- 1. 提交格式检查 ----------
HOOKS_DIR=".harness/hooks/guards"
if [ -f "$HOOKS_DIR/guard-commit-msg.sh" ] && [ -x "$HOOKS_DIR/guard-commit-msg.sh" ]; then
    bash "$HOOKS_DIR/guard-commit-msg.sh"
fi

# ---------- 2. 受保护分支拦截 ----------
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
PROTECTED="main master"
if echo "$PROTECTED" | grep -qw "$CURRENT_BRANCH"; then
    echo -e "${RED}❌ 禁止直推到受保护分支: $CURRENT_BRANCH${NC}"
    echo -e "  请通过 PR 合并。如确需直推，使用 git push --no-verify"
    exit 1
fi

# ---------- 3. 测试提醒 ----------
if [ -f "package.json" ]; then
    echo -e "${YELLOW}💡 推送前请确保测试已通过: pnpm test${NC}"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}💡 推送前请确保测试已通过: pytest${NC}"
elif [ -f "go.mod" ]; then
    echo -e "${YELLOW}💡 推送前请确保测试已通过: go test ./...${NC}"
fi

echo -e "${GREEN}=> pre-push 完成${NC}"
exit 0
