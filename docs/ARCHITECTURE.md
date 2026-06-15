# 架构说明

## 核心公式

```
Agent = Model + Harness
```

Harness 是模型之外的整套运行环境。这个模板的架构分 4 层：

```
┌─────────────────────────────────────────────────┐
│  Layer 1: 工程硬约束（Agent 无法绕过）            │
│  ├── hooks/guards/*    → 提交时自动拦截          │
│  ├── hooks/pre-*       → 提交/推送检查           │
│  ├── gates/*           → CI 门控阻断 PR          │
│  └── scripts/security  → 安全扫描强制执行         │
├─────────────────────────────────────────────────┤
│  Layer 2: 系统自动化（不依赖 Agent 自觉）         │
│  ├── scripts/archive   → 记忆自动归档            │
│  ├── scripts/init      → 项目自动初始化          │
│  ├── scripts/register  → PRD 自动注册            │
│  └── .gitignore        → 敏感文件自动忽略        │
├─────────────────────────────────────────────────┤
│  Layer 3: Prompt 层引导（靠 Agent 遵守）          │
│  ├── AGENTS.md         → 组织级规范              │
│  ├── rules/*           → 编码规范 + 思维准则     │
│  ├── verification.md   → 自验证协议              │
│  ├── templates/*       → 项目级配置              │
│  └── context/*         → 产品/设计交付物         │
├─────────────────────────────────────────────────┤
│  Layer 4: Skill 层（按需加载的工作流）            │
│  ├── workflow          → 总调度（8 条工作流）    │
│  ├── brainstorming     → 需求→设计               │
│  ├── plan              → 任务拆解                │
│  ├── tdd               → 红绿重构                │
│  ├── verify            → 交付验证                │
│  ├── code-review       → 代码审查                │
│  ├── finish-branch     → 分支收尾                │
│  └── ...               → 15 个 Skill             │
└─────────────────────────────────────────────────┘
```

## 模块依赖关系

```
AGENTS.md（入口）
  ├── → rules/thinking.md（思维准则）
  ├── → rules/general.md（编码规范）
  │     └── → rules/languages/*.md（按语言）
  ├── → rules/security.md（安全红线）
  ├── → rules/git.md（Git 规范）
  ├── → verification.md（自验证协议）
  ├── → context/product/（PRD）
  │     └── → features.json（任务状态）
  └── → context/design/（设计 Token）
```

## Skill 工作流生命周期

```
需求 → 设计 → 实现 → 验证 → 审查 → 收尾
 │       │       │       │       │       │
 ▼       ▼       ▼       ▼       ▼       ▼
brainstorm → plan → tdd → verify → code-review → finish-branch
                                        │
                                        ▼
                                    changelog（版本发布时）
```

详见 `.harness/skills/workflow/SKILL.md`

## 数据流

```
PRD 文件 ──register-prd.sh──→ features.json
                                    ↓
                            brainstorming 读取 context_ref
                                    ↓
                            DoR 检查 → 读 PRD → plan
                                    ↓
                            tdd 实现（AC-xxx 命名测试）
                                    ↓
                            verify 提取 AC → 验收报告
                                    ↓
                            features.json status → done
```
