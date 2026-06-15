#!/bin/bash
# check-dor.sh — 工程层 DoR (Definition of Ready) 强制门控
#
# 机制：
#   Agent 在进入 plan 或 coding 阶段前，必须运行此脚本。
#   如果 PRD 状态未达到 "Ready for Dev"，脚本报错拦截，打破 Agent 脑补的闭环。
#
# 按 PRD 级别区分检查：
#   L 级：product + development + testing 全部 done + approved_by
#   M 级：product done + approved_by（development 和 testing 可选）
#   S 级：跳过 DoR（不需要 PRD）
#   hotfix：跳过 DoR（紧急通道）

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}❌ 错误：请提供 PRD 文件路径。${NC}"
    echo "用法: bash .harness/scripts/check-dor.sh .harness/context/product/PRD-XXX.md"
    exit 1
fi

PRD_FILE="$1"

if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}❌ 错误：找不到文件 $PRD_FILE${NC}"
    exit 1
fi

echo -e "🔍 正在执行 DoR (Definition of Ready) 校验: $PRD_FILE"

# ---------- 检测 PRD 级别 ----------
# 优先从文件名判断，其次从 frontmatter 判断
if echo "$PRD_FILE" | grep -qE "\-M[\-\.]|TEMPLATE-M"; then
    LEVEL="M"
elif echo "$PRD_FILE" | grep -qE "TEMPLATE-L"; then
    LEVEL="L"
elif grep -q "^level:" "$PRD_FILE" 2>/dev/null; then
    LEVEL=$(grep "^level:" "$PRD_FILE" | awk -F':' '{print $2}' | tr -d ' "')
else
    # 默认按 L 级检查（最严格）
    LEVEL="L"
fi

echo "  PRD 级别: $LEVEL"

# ---------- 检测 hotfix 例外 ----------
TYPE=$(grep "^type:" "$PRD_FILE" 2>/dev/null | awk -F':' '{print $2}' | tr -d ' "')

if [ "$TYPE" == "hotfix" ]; then
    echo -e "${YELLOW}⚠️  检测到 type: hotfix，触发例外通道，跳过 DoR 校验。${NC}"
    exit 0
fi

# ---------- 提取状态字段 ----------
PRODUCT_STATUS=$(grep "^  product:" "$PRD_FILE" 2>/dev/null | awk -F':' '{print $2}' | awk '{print $1}')
DEV_STATUS=$(grep "^  development:" "$PRD_FILE" 2>/dev/null | awk -F':' '{print $2}' | awk '{print $1}')
QA_STATUS=$(grep "^  testing:" "$PRD_FILE" 2>/dev/null | awk -F':' '{print $2}' | awk '{print $1}')
APPROVER=$(grep "^  approved_by:" "$PRD_FILE" 2>/dev/null | awk -F':' '{print $2}' | tr -d ' "')

echo "-----------------------------------"
echo "产品定义 (PM)    : $PRODUCT_STATUS"
echo "开发契约 (Dev)   : $DEV_STATUS"
echo "测试策略 (QA)    : $QA_STATUS"
echo "最终审批 (Approve): $APPROVER"
echo "-----------------------------------"

# ---------- 按级别执行校验 ----------
FAILED=0
MISSING=""

# 所有级别都需要 product done
if [ "$PRODUCT_STATUS" != "done" ]; then
    FAILED=1
    MISSING="$MISSING product"
fi

# 所有级别都需要 approved_by
if [ "$APPROVER" == "null" ] || [ -z "$APPROVER" ]; then
    FAILED=1
    MISSING="$MISSING approved_by"
fi

# L 级额外检查 development 和 testing
if [ "$LEVEL" == "L" ]; then
    if [ "$DEV_STATUS" != "done" ]; then
        FAILED=1
        MISSING="$MISSING development"
    fi
    if [ "$QA_STATUS" != "done" ]; then
        FAILED=1
        MISSING="$MISSING testing"
    fi
fi

# ---------- 结果 ----------
if [ $FAILED -eq 1 ]; then
    echo -e "${RED}🚨 拦截！PRD ($LEVEL 级) 未达到 Ready for Dev 标准。${NC}"
    echo -e "  缺失项:$MISSING"
    if [ "$LEVEL" == "L" ]; then
        echo "  L 级要求: product + development + testing 全部 done + approved_by"
    else
        echo "  M 级要求: product done + approved_by"
    fi
    echo "  请联系团队成员补充缺失字段，然后再尝试进行代码实现。"
    exit 1
else
    echo -e "${GREEN}✅ DoR 校验通过！($LEVEL 级) 允许 Agent 进入开发阶段。${NC}"
    exit 0
fi
