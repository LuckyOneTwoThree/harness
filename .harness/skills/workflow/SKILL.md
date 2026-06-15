---
name: workflow
description: Skill 工作流总调度。定义 11 个 Skill 的触发条件、执行顺序和协作关系。所有 Skill 的入口。
---

# 工作流编排 (Workflow Orchestration)

> 这是所有 Skill 的"总调度"。它定义了什么时候用哪个 Skill、它们之间是什么关系。

## 核心生命周期

```
需求 → 设计 → 实现 → 验证 → 审查 → 收尾
 │       │       │       │       │       │
 ▼       ▼       ▼       ▼       ▼       ▼
brainstorm → plan → tdd → verify → code-review → finish-branch
                                        │
                                        ▼
                                    changelog（版本发布时）
```

## 触发规则

### 自动触发（Agent 应主动使用）

| 触发条件 | 调用的 Skill | 说明 |
|----------|-------------|------|
| Agent 进入项目 | **session-start** | 每次会话开始 |
| 用户提出新需求 | **brainstorming** | 硬门控：设计未批准不准写代码 |
| 设计获批后 | **plan** | 分解为可执行的任务 |
| 开始写代码 | **tdd** | 铁律：先写失败测试 |
| Agent 说"做完了" | **verify** | 必须有证据，不能只说"应该没问题" |
| 准备合并前 | **code-review** | 多维度审查 |
| 分支工作完成 | **finish-branch** | 4 选 1：合并/PR/保持/丢弃 |
| 准备结束会话 | **close-chat** | 更新进度 + 提取教训 |

### 条件触发（特定场景）

| 触发条件 | 调用的 Skill | 说明 |
|----------|-------------|------|
| 测试失败 / Bug 出现 | **debug** | 强制先查根因再修复 |
| 接口变慢 / CPU 飙高 / 内存泄漏 | **performance** | 先量化再优化 |
| 新增/修改 API 端点 | **api-docs** | 文档必须与代码同步 |
| 新人加入 / Agent 接手陌生项目 | **codebase-exploration** | 系统性理解代码库 |
| 版本发布前 | **changelog** | 从 git 历史生成变更日志 |
| 配置飞书通知 | **feishu-notify** | 一次性配置 |

## 典型工作流

### 工作流 A：新功能开发（完整流程）

```
1. session-start        ← 加载项目状态
2. brainstorming        ← 理解需求、确认方案
3. plan                 ← 拆解任务、生成实施计划
4. tdd（循环）           ← 红→绿→重构，每个任务重复
5. verify               ← 运行测试 + lint + 安全检查
6. code-review          ← 4 维度审查
7. finish-branch        ← 合并或创建 PR
8. close-chat           ← 更新进度
```

### 工作流 B：Bug 修复（精简流程）

```
1. session-start        ← 加载项目状态
2. debug                ← 根因调查 → 模式分析 → 假设验证
3. tdd                  ← 写复现测试 → 修复 → 验证
4. verify               ← 全量测试通过
5. finish-branch        ← 合并或创建 PR
6. close-chat           ← 更新进度
```

### 工作流 C：代码审查（只做审查）

```
1. session-start        ← 加载项目状态
2. code-review          ← 审查指定的 diff
3. close-chat           ← 记录审查结果
```

### 工作流 D：版本发布

```
1. session-start        ← 加载项目状态
2. changelog            ← 从 git 历史生成变更日志
3. verify               ← 全量测试 + 构建验证
4. finish-branch        ← 创建 release PR
5. close-chat           ← 更新进度
```

### 工作流 E：新人上手

```
1. session-start           ← 加载项目状态
2. codebase-exploration    ← 理解项目架构、代码结构、关键模块
```

### 工作流 F：性能排查

```
1. session-start           ← 加载项目状态
2. performance             ← 量化问题 → 定位瓶颈层 → 深入分析 → 优化验证
3. tdd                     ← 写性能回归测试（防止优化被覆盖）
4. verify                  ← 功能回归 + 性能对比
5. close-chat              ← 记录排查过程和结论
```

### 工作流 G：API 开发

```
1. brainstorming           ← 确认 API 需含 DoR 检查
2. plan                    ← 设计 API schema
3. tdd                     ← 写 API 测试 → 实现 → 验证
4. api-docs                ← 生成/更新 OpenAPI 文档
5. verify                  ← 测试 + 文档校验
6. code-review             ← 审查代码 + 文档一致性
7. finish-branch           ← 合并
```

### 工作流 H：PM 提需求 → 开发

```
PM 阶段:
1. PM 填写 PRD（L 级或 M 级）→ 放入 .harness/context/product/
2. 注册到 features.json:
   bash .harness/scripts/register-prd.sh .harness/context/product/PRD-xxx.md
3. Dev 补充技术部分（数据模型、API 契约）→ prd_status.development = done
4. QA 补充测试策略 → prd_status.testing = done
5. 审批人确认 → prd_status.approved_by = "姓名"

Agent 阶段:
1. session-start           ← 加载状态 + PRD 变更检测
2. brainstorming           ← DoR 检查（读 context_ref → 验证 prd_status → 按需加载）
3. plan                    ← 从 PRD 验收标准提取任务
4. tdd                     ← 实现（前端读 DESIGN-TOKENS，后端遵循数据模型，测试用 AC-xxx 命名）
5. verify                  ← 运行测试 + AC 编号提取 + 生成验收报告
6. code-review             ← 审查
7. finish-branch           ← 合并
8. 验收报告                 ← 保存到 .harness/context/acceptance/
```

### 数据流全景

```
PRD 文件                  features.json              Agent 行为
──────────               ──────────────             ─────────────
PM 创建 PRD    ──register-prd.sh──→  条目(status: blocked)
PM 填业务      ─────────────────→   (等待 DoR)
Dev 补技术     ─────────────────→   (等待 DoR)
QA 补测试      ─────────────────→   (等待 DoR)
审批人确认     ─────────────────→   条目(status: pending)
                                     ↓
                              brainstorming 读取 context_ref
                                     ↓
                              DoR 通过 → 读 PRD 内容
                                     ↓
                              plan 从验收标准提取任务
                                     ↓
                              tdd 实现（AC-xxx 命名测试）
                                     ↓
                              verify 提取 AC → 生成验收报告
                                     ↓
                              features.json 条目(status: done)
```

## Skill 依赖关系

```
brainstorming ──→ plan ──→ tdd ──→ verify ──→ code-review ──→ finish-branch
                                    ↑                              │
                                    │                              ▼
                    debug ──────────┘                          changelog
                                    ↑
                                    │
                        （测试失败时回到 tdd）

session-start（每次会话开始）    close-chat（每次会话结束）
```

## 跳过规则

| 场景 | 可以跳过 | 不可以跳过 |
|------|----------|-----------|
| 简单 Bug 修复（1-2 行改动） | brainstorming, plan | tdd, verify |
| 紧急线上修复 | brainstorming, code-review | debug, tdd, verify |
| 文档-only 改动 | tdd, code-review | verify |
| 配置变更 | brainstorming | verify |

**原则：** verify 永远不能跳过。其他 Skill 按风险判断。

## 新增 Skill 流程

团队需要新增 Skill 时：

1. 在 `.harness/skills/<名称>/` 下创建 `SKILL.md`
2. 添加 YAML frontmatter（name、description）
3. 在本文件的触发规则表中添加对应条目
4. 提 PR 经 team-lead review
