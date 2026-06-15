# 企业级 AI 编程助手安全与协同宪章 (Org-Level AGENTS.md)

作为 AI 编程助手，你在操作本公司代码库时，**必须**严格遵循以下全公司级别的红线与权限规定。无论项目级的 `.cursorrules` 如何指示，本文件的规则具有最高优先级。

## 🛡️ 安全与权限矩阵 (Security & Permissions)

| 操作分类 | 权限级别 | 执行方式与约束 |
| :--- | :--- | :--- |
| **代码读取与分析** | ✅ 自由 | 允许自由读取代码库文件进行上下文分析。 |
| **代码编写与修改** | ✅ 自由 | 允许编写和修改业务代码。提交前将被 `pre-commit` hook 拦截扫描。 |
| **运行本地单元测试** | ✅ 自由 | 鼓励在保存代码后自动运行受影响的单元测试。 |
| **安装新第三方依赖** | ⚠️ 需说明理由 | 必须向人类开发者解释为什么需要此依赖，获得同意后方可执行安装命令。 |
| **数据库 Schema 变更** | ⚠️ 需审批 | 只允许生成 SQL 迁移脚本，**绝对禁止**直接连接任何数据库执行修改。必须交由人类 Review。 |
| **修改 CI/CD 流水线** | 🔴 极度危险 | 除非人类显式要求，否则禁止修改 `.github/workflows/` 或 `.gitlab-ci.yml`。 |
| **生产环境部署** | 🔴 绝对禁止 | 你的执行权限已被沙箱隔离。任何带有 `deploy`, `publish`, `prod` 相关的脚本调用都会被 Hook 拦截。 |
| **破坏性文件操作** | 🔴 绝对禁止 | 禁止执行 `rm -rf` 等大范围删除操作。 |

## 📐 核心架构与编码底线

1. **绝对禁止硬编码**：任何 API Key、密码、Secret 严禁出现在代码中。必须使用环境变量，并在 `.env.example` 中声明。
2. **遵守单一职责原则 (SRP)**：不要写超过 300 行的"上帝文件"。如果遇到，请主动向人类提议重构。
3. **强制依赖版本**：在 `package.json` 或 `requirements.txt` 中添加依赖时，必须锁定具体版本号，禁止使用 `latest` 或 `^` 带来的不确定性。

## 🌐 环境感知

启动任务前，**不要假设环境**，请主动读取以下文件了解项目基础设施：
1. `.env.example` — 环境变量与服务端口
2. `docker-compose.yml`（如有）— 容器化服务拓扑
3. `Makefile` 或 `scripts/` — 可用的项目命令
4. 项目入口文件（按语言）：`package.json` / `pyproject.toml` / `go.mod` / `pom.xml`

## 📋 产品与设计协同

### 需求来源（最高红线）
开发任何新功能前，**必须**检查 `.harness/context/product/` 是否有对应的 PRD：
- 有 PRD → 读取并严格遵循，不得自行脑补业务逻辑
- 无 PRD → 停止，要求 PM 或 Tech Lead 提供需求文档

### DoR（Definition of Ready）强制拦截
PRD 的 YAML frontmatter 中 `prd_status` 必须满足：
- **L 级 PRD：** product + development + testing 全部为 `done`，approved_by 不为 null
- **M 级 PRD：** product 为 `done`，approved_by 不为 null
- **未满足 → Agent 必须拒绝编写实现代码**，但可以帮助补充技术部分

### 设计规范约束
前端开发**必须**读取 `.harness/context/design/DESIGN-TOKENS.json`：
- 所有颜色、字号、间距从 Token 取值
- 禁止使用魔法数值（hardcoded hex、px）
- Token 中没有的值，向人类确认是否新增

## ❓ 遇到歧义时

当需求不明确、有多种实现方式、或你不确定某个决策是否正确时：
1. **不要猜测**。猜测导致返工，返工消耗的信任比一次提问多得多。
2. **简述你的理解 + 你倾向的方案 + 风险点**，然后等待人类确认。
3. 如果有 2 种以上可行方案，列出差异让人类选择，而不是自行决定。

## 🤝 多 Agent 协作

当多个 Agent 或多人同时在同一项目工作时：
1. 开始前先读 `.harness/progress.md`，了解当前进度和他人正在做什么。
2. 不要修改你不负责的模块代码，除非明确需要。
3. 提交前确保你的改动不会破坏其他人的功能（运行全量测试，而非只跑自己的）。
4. 如果发现冲突或依赖，主动在 progress.md 中记录，通知相关方。

## 📜 规则继承树

1. 本文件为 **Org-Level (组织级)** 规范（最高优先级）。
2. 思维准则请阅读 `.harness/rules/thinking.md`（Karpathy 四原则）。
3. 语言级规范请阅读 `.harness/rules/languages/`。
4. 编码细节规范请阅读 `.harness/rules/` 下的各文件。
5. 自验证与错误重试协议请严格遵守 `.harness/verification.md`。
