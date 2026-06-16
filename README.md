# 企业级 AI Agent 治理脚手架 (Harness Template)

> **设计原则：工程手段做兜底，Prompt 层做引导。**

本仓库不是一段代码框架，而是一套**"系统控制 > 提示词引导"**的企业级 AI 协同治理体系。

## 核心公式

```
Agent = Model + Harness
```

Harness 是模型之外的整套运行环境。这个模板提供了一套开箱即用的骨架，适用于多工具、多语言、多人协作的团队。

## 快速开始

```bash
# 在你的项目根目录执行
bash .harness/scripts/init-project.sh
```

该脚本会自动生成项目级配置、挂载 Git Hooks、初始化状态文件。

## 结构总览

```
项目根目录/
├── AGENTS.md                    ← 组织级宪章（最高优先级，Agent 入口）
├── CLAUDE.md                    ← Claude Code 特定配置（可选）
├── .cursorrules                 ← Cursor 特定配置（可选）
├── .env.example                 ← 环境上下文（Agent 感知基础设施）
├── CODEOWNERS                   ← PR 自动分配 reviewer
│
├── docs/                        ← 文档
│   ├── QUICKSTART.md            ← 5 分钟快速开始
│   ├── ARCHITECTURE.md          ← 架构说明
│   ├── CONTRIBUTING.md          ← 贡献指南
│   └── TROUBLESHOOTING.md       ← 常见问题排查
│
└── .harness/
    ├── rules/                   ← 编码规范
    │   ├── general.md           ← 通用规范
    │   ├── security.md          ← 安全红线
    │   ├── git.md               ← Git 提交规范
    │   ├── thinking.md          ← 思维准则（Karpathy 四原则）
    │   └── languages/           ← 按语言规范（python/js/java/go）
    │
    ├── hooks/                   ← Git hooks（工程层硬兜底）
    │   ├── guards/              ← 独立守卫模块
    │   │   ├── guard-secret.sh  ← 密钥泄露检测
    │   │   ├── guard-bash.sh    ← 危险命令拦截
    │   │   ├── guard-sensitive-file.sh ← 敏感文件阻止
    │   │   └── guard-commit-msg.sh    ← 提交格式校验
    │   ├── pre-commit.sh        ← 提交前调度器
    │   ├── pre-push.sh          ← 推送前检查
    │   └── session-start.sh     ← 会话启动钩子
    │
    ├── gates/                   ← CI/CD 门控模板
    │   └── github-actions.yml   ← 质量 + 安全 + 测试 + 飞书通知
    │
    ├── scripts/                 ← 自动化脚本
    │   ├── init-project.sh      ← 项目初始化
    │   ├── archive-progress.sh  ← 记忆自动归档
    │   ├── security-check.sh    ← 安全扫描（调用 guards）
    │   ├── verify-harness.sh    ← 健康检查
    │   ├── register-prd.sh      ← PRD → features.json
    │   ├── check-prd-changes.sh ← PRD 变更检测
    │   ├── check-dor.sh         ← DoR 门控（区分 L/M 级）
    │   └── validate-context.sh  ← context 目录校验
    │
    ├── skills/                  ← 15 个可复用技能
    │   ├── workflow/SKILL.md    ← 总调度（8 条工作流）
    │   ├── session-start/       ← 会话启动
    │   ├── brainstorming/       ← 需求→设计
    │   ├── plan/                ← 任务拆解
    │   ├── tdd/                 ← 测试驱动开发
    │   ├── verify/              ← 交付验证 + AC 映射
    │   ├── code-review/         ← 代码审查
    │   ├── finish-branch/       ← 分支收尾
    │   ├── debug/               ← 系统化调试
    │   ├── performance/         ← 性能排查
    │   ├── codebase-exploration/← 代码库探索
    │   ├── api-docs/            ← API 文档
    │   ├── changelog/           ← 变更日志
    │   ├── close-chat/          ← 会话收尾
    │   └── feishu-notify/       ← 飞书通知
    │
    ├── context/                 ← 产品与设计交付物
    │   ├── product/             ← PRD 模板 + 指南
    │   ├── design/              ← DESIGN-TOKENS + 指南
    │   └── acceptance/          ← 验收报告模板
    │
    ├── templates/               ← 项目级配置模板
    │
    ├── verification.md          ← 自验证协议
    ├── features.json            ← 功能状态看板
    └── progress.md              ← 跨会话进度日志
```

## 四大核心机制

| 机制 | 文件 | 执行层 |
|------|------|--------|
| 🔒 安全边界 | security-check.sh + hooks + CI | 工程层强制 |
| 📦 记忆管理 | archive-progress.sh + archives/ | 系统级自动 |
| ✅ 自验证 | verification.md + CI 门控 | 工程+Prompt |
| 🌐 环境感知 | .env.example + docker-compose | 桥接基础设施 |
| 📋 产品协同 | context/product/ + DoR 拦截 | 跨角色协作 |
| 🎨 设计协同 | context/design/ + DESIGN-TOKENS | 消除魔法数值 |

## 产品与设计团队接入指南

### PM 接入

1. 根据需求复杂度选择模板：
   - **S 级（< 0.5 天）**：不需要 PRD，直接在 features.json 中描述
   - **M 级（1-3 天）**：使用 `.harness/context/product/PRD-TEMPLATE-M.md`
   - **L 级（> 3 天）**：使用 `.harness/context/product/PRD-TEMPLATE-L.md`
2. 填写业务部分，将 `prd_status.product` 改为 `done`
3. 通知 Dev 和 QA 补充技术部分和测试策略
4. 审批人确认后，Agent 自动识别并开始开发

详见：`.harness/context/product/PRD-GUIDE.md`

### UI 设计师接入

1. 在 Figma 中定义设计变量（颜色、字号、间距）
2. 使用 Tokens Studio 插件导出为 JSON
3. 保存为 `.harness/context/design/DESIGN-TOKENS.json`
4. Agent 开发前端时自动引用，不再使用魔法数值

详见：`.harness/context/design/DESIGN-GUIDE.md`

### DoR（Definition of Ready）机制

PRD 必须通过 DoR 检查，Agent 才允许开始编码：
- **L 级**：PM + Dev + QA 全部填写完成 + 审批人签字
- **M 级**：PM 填写完成 + 审批人签字
- 未通过 → Agent 拒绝编码，帮助补充缺失部分

## 支持的 AI 工具

本框架基于 [AGENTS.md](https://www.agents.md/) 跨工具标准（60,000+ 仓库在用，Linux Foundation 托管），兼容 30+ 个 AI 编码工具。

### 核心兼容矩阵

| 工具 | AGENTS.md | Skills | Hooks/Guards | 适配度 | 说明 |
|------|-----------|--------|-------------|--------|------|
| **Hermes Agent** | ✅ 原生 | ✅ 原生 | ✅ 完整 | ⭐⭐⭐ | 天然兼容，全部机制生效 |
| **Claude Code** | ✅ 原生 | ✅ SKILL.md | ✅ 完整 | ⭐⭐⭐ | 全部机制生效 |
| **OpenAI Codex** | ✅ 原生 | ✅ SKILL.md | ✅ 完整 | ⭐⭐⭐ | 全部机制生效 |
| **Cursor** | ✅ 原生 | ✅ | ✅ 完整 | ⭐⭐⭐ | 全部机制生效 |
| **Trae SOLO** | ✅ 原生 | ⚠️ 自定义 Agent | ⚠️ 沙箱+命令白名单 | ⭐⭐ | AGENTS.md 生效，hooks 为软约束 |
| **Google Jules** | ✅ 原生 | ❌ | ❌（云端运行） | ⭐⭐ | AGENTS.md 自动读取，安全靠 CI 门控兜底 |
| **WorkBuddy** | ✅ OpenClaw 兼容 | ✅ OpenClaw 兼容 | ❌ | ⭐⭐ | 通过 OpenClaw 兼容层支持 SKILL.md |
| **OpenClaw** | ✅ 原生 | ✅ 原生 | ❌ | ⭐⭐ | 完全兼容 AGENTS.md + SKILL.md |
| **GitHub Copilot** | ✅ 原生 | ❌ | ❌ | ⭐ | AGENTS.md 生效，无 skill 系统 |
| **Gemini CLI** | ✅ 配置 | ❌ | ❌ | ⭐ | 需 `.gemini/settings.json` 配置 |
| **Windsurf** | ✅ 原生 | ❌ | ❌ | ⭐ | AGENTS.md 生效 |
| **Zed** | ✅ 原生 | ❌ | ❌ | ⭐ | AGENTS.md 生效 |
| **Aider** | ✅ 配置 | ❌ | ❌ | ⭐ | 需 `.aider.conf.yml` 配置 |

### 三层适配说明

| 层 | 机制 | 跨工具兼容性 |
|----|------|-------------|
| **AGENTS.md** | 组织级规范、权限矩阵、DoR 拦截 | ✅ 30+ 工具原生读取 |
| **SKILL.md** | 可复用工作流（15 个 Skill） | ✅ Hermes/Claude Code/Codex/Cursor/OpenClaw/WorkBuddy |
| **Hooks/Guards** | Git hooks + 安全守卫 | ✅ 所有本地运行的工具（CI 门控兜底云端工具） |

**核心结论：** 即使团队混合使用多种 AI 工具，AGENTS.md 层面的规范对所有工具都生效。差异仅在 Hooks（云端工具不执行本地 hooks）和 Skills（部分工具不支持 SKILL.md）。CI 门控是最终兜底——无论 Agent 用什么工具，PR 必须通过 CI 才能合并。

## 参考资源

- [OpenAI — Harness Engineering](https://openai.com/index/harness-engineering/)
- [LangChain — The Anatomy of an Agent Harness](https://blog.langchain.com/the-anatomy-of-an-agent-harness/)
- [Martin Fowler — Harness Engineering for Coding Agent Users](https://martinfowler.com/articles/harness-engineering.html)
- [AGENTS.md 标准](https://www.agents.md/)
