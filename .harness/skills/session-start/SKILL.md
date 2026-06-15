---
name: session-start
description: Agent 会话开始前的标准流程。确保 Agent 快速了解项目状态，不重复已做的工作。
---

# 会话启动技能 (Session Start)

> Agent 会话开始前的标准流程。确保 Agent 快速了解项目状态，不重复已做的工作。

## 何时触发

- Agent 进入一个已有项目时
- 用户开始一个新任务时
- 跨会话继续未完成的工作时

## 执行步骤

### 1. 运行启动脚本

```bash
bash .harness/hooks/session-start.sh
```

该脚本会自动输出：
- 项目基本信息（名称、分支、时间）
- 进度状态（progress.md 行数、最新记录）
- 功能清单（总数、完成、进行中、阻塞）
- 环境感知（.env.example、docker-compose、Makefile）
- 安全守卫状态

### 2. 读取关键文件

根据脚本输出，按需读取：
- `.harness/progress.md` — 了解最近的工作进展
- `.harness/features.json` — 了解待办事项和阻塞项
- `.env.example` — 了解环境配置
- `.harness/rules/` — 了解编码规范

### 3. 确认当前目标

与用户确认：
- 本次会话要完成什么？
- 有没有需要优先处理的阻塞项？
- 需要关注哪些其他人的工作？

### 4. PRD 变更检测

```bash
bash .harness/scripts/check-prd-changes.sh
```

如果检测到 PRD 变更：
- 检查变更是否影响当前正在进行的任务
- 如果影响，建议重新读取 PRD 并评估是否需要重置任务状态
