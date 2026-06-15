#!/bin/bash
# guard-commit-msg.sh — 提交信息格式守卫
# 校验最近一次提交是否符合 Conventional Commits
# 由 pre-push.sh 调用，也可独立运行

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -n "[guard-commit-msg] 检查提交格式... "

LAST_MSG=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "")
VALID_TYPES="feat|fix|docs|style|refactor|perf|test|build|ci|chore"

if [ -z "$LAST_MSG" ]; then
    echo -e "${GREEN}✅ (无提交历史)${NC}"
    exit 0
fi

# 检查是否符合 <type>(<scope>): <description> 格式
if echo "$LAST_MSG" | grep -qE "^($VALID_TYPES)(\(.+\))?: .+"; then
    echo -e "${GREEN}✅${NC}"
    exit 0
else
    echo -e "${RED}❌${NC}"
    echo -e "  ${RED}提交格式不符合 Conventional Commits:${NC}"
    echo -e "  ${YELLOW}实际: $LAST_MSG${NC}"
    echo -e "  ${YELLOW}期望: <type>(<scope>): <description>${NC}"
    echo -e "  ${YELLOW}type: feat/fix/docs/style/refactor/perf/test/build/ci/chore${NC}"
    exit 1
fi
