#!/bin/bash
# verify-harness.sh — Harness 健康检查
#
# 验证 harness 是否正确安装和配置。
# 在 init-project.sh 后运行，或定期检查。
#
# 检查项：
#   1. 核心文件是否存在
#   2. 脚本是否有执行权限
#   3. YAML frontmatter 是否完整
#   4. 内部引用是否可达
#   5. 运行时文件是否初始化

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}🔍 Harness 健康检查${NC}"
echo "========================"

# ---------- 1. 核心文件检查 ----------
echo -e "\n${BLUE}[1/5] 核心文件${NC}"
CORE_FILES=(
    "AGENTS.md"
    ".harness/verification.md"
    ".harness/features.json"
    ".harness/progress.md"
    ".harness/rules/thinking.md"
    ".harness/rules/general.md"
    ".harness/rules/security.md"
    ".harness/rules/git.md"
    ".harness/hooks/pre-commit.sh"
    ".harness/hooks/pre-push.sh"
    ".harness/hooks/session-start.sh"
    ".harness/scripts/init-project.sh"
    ".harness/scripts/archive-progress.sh"
    ".harness/scripts/security-check.sh"
    ".harness/skills/workflow/SKILL.md"
    ".harness/skills/brainstorming/SKILL.md"
    ".harness/skills/tdd/SKILL.md"
    ".harness/skills/verify/SKILL.md"
    ".harness/skills/code-review/SKILL.md"
)

for f in "${CORE_FILES[@]}"; do
    if [ -f "$f" ]; then
        echo -e "  ${GREEN}✅${NC} $f"
    else
        echo -e "  ${RED}❌${NC} $f (缺失)"
        ERRORS=$((ERRORS + 1))
    fi
done

# ---------- 2. 脚本权限检查 ----------
echo -e "\n${BLUE}[2/5] 脚本权限${NC}"
SCRIPTS=(
    ".harness/scripts/init-project.sh"
    ".harness/scripts/archive-progress.sh"
    ".harness/scripts/security-check.sh"
    ".harness/scripts/check-prd-changes.sh"
    ".harness/scripts/register-prd.sh"
    ".harness/scripts/check-dor.sh"
    ".harness/scripts/validate-context.sh"
    ".harness/hooks/pre-commit.sh"
    ".harness/hooks/pre-push.sh"
    ".harness/hooks/session-start.sh"
    ".harness/hooks/guards/guard-bash.sh"
    ".harness/hooks/guards/guard-secret.sh"
    ".harness/hooks/guards/guard-sensitive-file.sh"
    ".harness/hooks/guards/guard-commit-msg.sh"
    ".harness/skills/close-chat/run.sh"
)

for f in "${SCRIPTS[@]}"; do
    if [ ! -f "$f" ]; then
        echo -e "  ${YELLOW}⚠️${NC}  $f (不存在，跳过)"
        WARNINGS=$((WARNINGS + 1))
    elif [ -x "$f" ]; then
        echo -e "  ${GREEN}✅${NC} $f"
    else
        echo -e "  ${RED}❌${NC} $f (缺少执行权限)"
        ERRORS=$((ERRORS + 1))
    fi
done

# ---------- 3. SKILL.md frontmatter 检查 ----------
echo -e "\n${BLUE}[3/5] Skill Frontmatter${NC}"
SKILL_COUNT=0
for skill_dir in .harness/skills/*/; do
    skill_file="${skill_dir}SKILL.md"
    if [ ! -f "$skill_file" ]; then
        continue
    fi
    SKILL_COUNT=$((SKILL_COUNT + 1))
    first_line=$(head -1 "$skill_file" 2>/dev/null || echo "")
    has_name=$(grep -c "^name:" "$skill_file" 2>/dev/null || echo 0)
    has_desc=$(grep -c "^description:" "$skill_file" 2>/dev/null || echo 0)
    
    if [ "$first_line" = "---" ] && [ "$has_name" -gt 0 ] && [ "$has_desc" -gt 0 ]; then
        echo -e "  ${GREEN}✅${NC} $(basename $skill_dir)"
    else
        echo -e "  ${RED}❌${NC} $(basename $skill_dir) (frontmatter 不完整)"
        ERRORS=$((ERRORS + 1))
    fi
done
echo "  共检查 $SKILL_COUNT 个 Skill"

# ---------- 4. 内部引用检查 ----------
echo -e "\n${BLUE}[4/5] 内部引用${NC}"
REFS=(
    ".harness/rules/languages/python.md"
    ".harness/rules/languages/javascript.md"
    ".harness/rules/languages/java.md"
    ".harness/rules/languages/go.md"
    ".harness/templates/AGENTS.md.template"
    ".harness/templates/features.json.template"
    ".harness/templates/progress.md.template"
    ".harness/context/product/PRD-TEMPLATE-L.md"
    ".harness/context/product/PRD-TEMPLATE-M.md"
    ".harness/context/product/PRD-GUIDE.md"
    ".harness/context/design/DESIGN-TOKENS.json.example"
    ".harness/context/design/DESIGN-GUIDE.md"
    ".harness/context/acceptance/ACCEPTANCE-REPORT-TEMPLATE.md"
)

for f in "${REFS[@]}"; do
    if [ -f "$f" ]; then
        echo -e "  ${GREEN}✅${NC} $f"
    else
        echo -e "  ${YELLOW}⚠️${NC}  $f (缺失)"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# ---------- 5. 运行时文件检查 ----------
echo -e "\n${BLUE}[5/5] 运行时文件${NC}"
if [ -f ".harness/features.json" ]; then
    if python3 -c "import json; json.load(open('.harness/features.json'))" 2>/dev/null; then
        echo -e "  ${GREEN}✅${NC} features.json (合法 JSON)"
    else
        echo -e "  ${RED}❌${NC} features.json (JSON 格式错误)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "  ${RED}❌${NC} features.json (缺失)"
    ERRORS=$((ERRORS + 1))
fi

if [ -f ".harness/progress.md" ]; then
    LINES=$(wc -l < ".harness/progress.md" | tr -d ' ')
    echo -e "  ${GREEN}✅${NC} progress.md ($LINES 行)"
else
    echo -e "  ${RED}❌${NC} progress.md (缺失)"
    ERRORS=$((ERRORS + 1))
fi

# ---------- 汇总 ----------
echo ""
echo "========================"
TOTAL=$((ERRORS + WARNINGS))
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ 健康检查失败: $ERRORS 个错误, $WARNINGS 个警告${NC}"
    echo "  运行 bash .harness/scripts/init-project.sh 修复部分问题"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  通过 (有 $WARNINGS 个警告)${NC}"
    exit 0
else
    echo -e "${GREEN}✅ Harness 健康状态良好${NC}"
    exit 0
fi
