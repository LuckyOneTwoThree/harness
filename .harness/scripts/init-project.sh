#!/bin/bash
# init-project.sh — 项目初始化脚本
#
# 用法：在项目根目录执行
#   bash .harness/scripts/init-project.sh
#
# 功能：
#   1. 从模板生成项目级配置文件
#   2. 安装 Git hooks
#   3. 创建 .harness/archives/ 目录
#   4. 检查 .gitignore 完整性
#   5. 初始化 features.json 和 progress.md

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HARNESS_DIR=".harness"
TEMPLATES_DIR="$HARNESS_DIR/templates"

echo -e "${BLUE}🏗️  Harness 项目初始化${NC}"
echo "========================"

# ---------- 1. 创建必要的目录 ----------
echo -n "[1/7] 创建目录结构... "
mkdir -p "$HARNESS_DIR/archives"
mkdir -p "$HARNESS_DIR/scripts"
mkdir -p "docs"
echo -e "${GREEN}✅${NC}"

# ---------- 2. 生成 project-level AGENTS.md ----------
echo -n "[2/7] 生成项目级 AGENTS.md... "
if [ ! -f "AGENTS.md" ]; then
    if [ -f "$TEMPLATES_DIR/AGENTS.md.template" ]; then
        cp "$TEMPLATES_DIR/AGENTS.md.template" "AGENTS.md"
        echo -e "${GREEN}✅ (从模板生成，请编辑补充项目信息)${NC}"
    else
        echo -e "${YELLOW}⚠️  模板文件不存在，跳过${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  AGENTS.md 已存在，跳过${NC}"
fi

# ---------- 3. 生成 CLAUDE.md（可选）----------
echo -n "[3/7] 生成 CLAUDE.md... "
if [ ! -f "CLAUDE.md" ]; then
    if [ -f "$TEMPLATES_DIR/CLAUDE.md.template" ]; then
        cp "$TEMPLATES_DIR/CLAUDE.md.template" "CLAUDE.md"
        echo -e "${GREEN}✅ (可选，供 Claude Code 使用)${NC}"
    else
        echo -e "${YELLOW}⚠️  模板文件不存在，跳过${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  CLAUDE.md 已存在，跳过${NC}"
fi

# ---------- 4. 生成 .cursorrules（可选）----------
echo -n "[4/7] 生成 .cursorrules... "
if [ ! -f ".cursorrules" ]; then
    if [ -f "$TEMPLATES_DIR/.cursorrules.template" ]; then
        cp "$TEMPLATES_DIR/.cursorrules.template" ".cursorrules"
        echo -e "${GREEN}✅ (可选，供 Cursor 使用)${NC}"
    else
        echo -e "${YELLOW}⚠️  模板文件不存在，跳过${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  .cursorrules 已存在，跳过${NC}"
fi

# ---------- 5. 生成 .env.example ----------
echo -n "[5/7] 生成 .env.example... "
if [ ! -f ".env.example" ]; then
    if [ -f "$TEMPLATES_DIR/.env.example.template" ]; then
        cp "$TEMPLATES_DIR/.env.example.template" ".env.example"
        echo -e "${GREEN}✅ (请根据项目实际情况修改)${NC}"
    else
        echo -e "${YELLOW}⚠️  模板文件不存在，跳过${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  .env.example 已存在，跳过${NC}"
fi

# ---------- 6. 初始化状态文件 ----------
echo -n "[6/7] 初始化状态文件... "
if [ ! -f "$HARNESS_DIR/features.json" ]; then
    if [ -f "$TEMPLATES_DIR/features.json.template" ]; then
        cp "$TEMPLATES_DIR/features.json.template" "$HARNESS_DIR/features.json"
    fi
fi
if [ ! -f "$HARNESS_DIR/progress.md" ]; then
    if [ -f "$TEMPLATES_DIR/progress.md.template" ]; then
        cp "$TEMPLATES_DIR/progress.md.template" "$HARNESS_DIR/progress.md"
    fi
fi
echo -e "${GREEN}✅${NC}"

# ---------- 7. 安装 Git hooks ----------
echo -n "[7/7] 安装 Git hooks... "
if [ -d ".git" ]; then
    HOOKS_DIR=".git/hooks"
    
    # pre-commit
    if [ -f "$HARNESS_DIR/hooks/pre-commit.sh" ]; then
        cp "$HARNESS_DIR/hooks/pre-commit.sh" "$HOOKS_DIR/pre-commit"
        chmod +x "$HOOKS_DIR/pre-commit"
    fi
    
    # pre-push
    if [ -f "$HARNESS_DIR/hooks/pre-push.sh" ]; then
        cp "$HARNESS_DIR/hooks/pre-push.sh" "$HOOKS_DIR/pre-push"
        chmod +x "$HOOKS_DIR/pre-push"
    fi
    
    # 设置 guards 可执行权限
    if [ -d "$HARNESS_DIR/hooks/guards" ]; then
        chmod +x "$HARNESS_DIR/hooks/guards/"*.sh 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${YELLOW}⚠️  非 Git 仓库，跳过 hook 安装${NC}"
fi

# ---------- 汇总 ----------
echo ""
echo "========================"
echo -e "${GREEN}🎉 初始化完成！${NC}"
echo ""
echo "接下来你需要："
echo "  1. 运行 bash .harness/scripts/verify-harness.sh 验证安装"
echo "  2. 编辑 AGENTS.md — 补充项目描述和关键约束"
echo "  3. 编辑 .env.example — 根据项目实际环境修改"
echo "  4. 编辑 CLAUDE.md — 如果使用 Claude Code"
echo "  5. 复制 .harness/gates/github-actions.yml 到 .github/workflows/ — 启用 CI 门控"
echo "  6. 配置飞书 Webhook — 见 .harness/skills/feishu-notify/SKILL.md"
echo ""
echo "结构总览："
echo "  AGENTS.md               ← 组织级通用规范（Agent 入口）"
echo "  CLAUDE.md               ← Claude Code 特定配置（可选）"
echo "  .env.example             ← 环境上下文（Agent 感知基础设施）"
echo "  .harness/"
echo "  ├── rules/               ← 编码规范（通用 + 按语言）"
echo "  ├── hooks/               ← Git hooks（工程层拦截）"
echo "  ├── gates/               ← CI/CD 门控模板"
echo "  ├── scripts/             ← 自动化脚本（归档、安全检查）"
echo "  ├── skills/              ← 可复用技能（飞书通知等）"
echo "  ├── templates/           ← 项目级配置模板"
echo "  ├── archives/            ← 历史记忆归档（自动维护）"
echo "  ├── verification.md      ← 自验证协议"
echo "  ├── features.json        ← 功能状态看板"
echo "  └── progress.md          ← 跨会话进度日志"
