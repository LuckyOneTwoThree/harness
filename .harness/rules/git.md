# Git 协同与提交规范 (Git Commit Convention)

> 本组织强制使用 Conventional Commits 规范。所有提交将被 `pre-commit` hook 拦截校验。

## 提交格式

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

## Type 可选项

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新增功能 | `feat(auth): 添加微信登录` |
| `fix` | 修复 bug | `fix(api): 修复分页参数越界` |
| `docs` | 仅修改文档 | `docs(readme): 补充部署说明` |
| `style` | 格式调整（不影响逻辑） | `style(python): 统一 black 格式化` |
| `refactor` | 重构（不加功能不修 bug） | `refactor(db): 提取连接池管理` |
| `perf` | 性能优化 | `perf(query): 添加数据库索引` |
| `test` | 增加测试 | `test(user): 添加注册流程测试` |
| `build` | 构建系统 / 外部依赖 | `build(deps): 升级 axios 到 1.7` |
| `ci` | CI 配置变更 | `ci(actions): 添加飞书通知` |
| `chore` | 辅助工具变动 | `chore(eslint): 更新规则配置` |

## Subject 规则

- 不超过 72 个字符
- 用中文或英文，跟随项目惯例，保持一致
- 使用祈使语气（"添加"而非"添加了"）
- 不以句号结尾

## 分支规范

| 分支 | 用途 | 保护规则 |
|------|------|----------|
| `main` / `master` | 生产代码 | 🔴 禁止直推，必须通过 PR + CI + Review |
| `develop` | 开发集成 | 🔴 禁止直推，必须通过 PR + CI |
| `feat/<描述>` | 功能开发 | 从 develop 拉出，完成后 PR 合回 |
| `fix/<描述>` | Bug 修复 | 从 main 拉出，完成后 PR 合回 + cherry-pick 到 develop |

## PR 规范

- **标题**：与提交格式一致，`<type>(<scope>): <description>`
- **描述**：说明做了什么、为什么做、怎么验证
- **关联 Issue**：如有，用 `Closes #123` 或 `Refs #123`
- **大小**：单个 PR 不超过 500 行变更（大功能拆分为多个可独立理解的 PR）
- **合并策略**：功能分支用 squash merge，保持 main 历史线性
- **CI 门控**：必须通过所有自动化检查（lint + test + security）才能合并
- **Review**：至少 1 人 Code Review（AI 生成的代码也需要）

## Agent 提交标注

AI Agent 生成的提交，在 footer 中标注来源：
```
feat(user): 添加注册流程

Generated-by: claude-code
```

Agent 生成的 PR，在描述中附带：
- 执行了哪些验证（lint / test / security-check 结果）
- 遇到的问题和处理方式（如有）
