# 5 分钟快速开始

## 第一步：克隆模板

```bash
# 方式 1：直接克隆到新项目
git clone https://github.com/LuckyOneTwoThree/harness.git my-project
cd my-project

# 方式 2：复制到已有项目
git clone https://github.com/LuckyOneTwoThree/harness.git /tmp/harness
cp -r /tmp/harness/.harness /你的项目/
cp /tmp/harness/AGENTS.md /你的项目/
cp /tmp/harness/CODEOWNERS /你的项目/
cp /tmp/harness/.gitignore /你的项目/
cp -r /tmp/harness/docs /你的项目/
rm -rf /tmp/harness
```

## 第二步：初始化

```bash
cd /你的项目/
bash .harness/scripts/init-project.sh
```

脚本会自动：
- 创建 `archives/` 目录
- 从模板生成项目级 `AGENTS.md`、`CLAUDE.md`、`.cursorrules`、`.env.example`
- 初始化 `features.json` 和 `progress.md`
- 安装 Git hooks
- 设置 guards 可执行权限

## 第三步：验证安装

```bash
bash .harness/scripts/verify-harness.sh
```

看到 `✅ Harness 健康状态良好` 即可开始使用。

## 第四步：开始使用

### 日常开发
```
1. Agent 进入项目 → session-start 自动加载状态
2. 提需求 → brainstorming 确认理解
3. 写代码 → tdd 红绿重构
4. 验证 → verify 跑测试
5. 提交 → pre-commit hook 自动检查
```

### PM 提需求
```
1. PM 写 PRD → 放入 .harness/context/product/
2. bash .harness/scripts/register-prd.sh <PRD路径>
3. Dev/QA 补充 → prd_status 全部 done
4. Agent 自动识别并开始开发
```

## 目录结构速查

```
.harness/
├── context/       ← PM/UI 交付物（PRD、设计 Token）
├── hooks/         ← Git hooks（工程层拦截）
├── rules/         ← 编码规范
├── scripts/       ← 自动化脚本
├── skills/        ← 15 个 Agent 技能
├── templates/     ← 项目级配置模板
├── verification.md
├── features.json
└── progress.md
docs/
├── QUICKSTART.md       ← 本文件
├── ARCHITECTURE.md     ← 架构说明
├── CONTRIBUTING.md     ← 贡献指南
└── TROUBLESHOOTING.md  ← 常见问题
```
