---
name: changelog
description: 版本发布前或合并 PR 时使用。从 git 历史自动生成或更新 CHANGELOG.md，遵循 Keep a Changelog 规范。
---

# 变更日志生成 (Changelog)

> 来源：Keep a Changelog 规范 (https://keepachangelog.com) + 社区最佳实践
> 参考：conventional-commits、semantic-versioning

从 git 历史生成结构化的 CHANGELOG.md。

## 核心原则

- 变更日志是**给人看的**，不是给机器看的
- 每个版本都有明确的日期和类型分类
- 同类变更按影响程度排序

## 格式规范

遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 格式：

```markdown
# 变更日志

本项目所有重要变更都将记录在此文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增
- 新功能描述

### 变更
- 现有功能变更

### 修复
- Bug 修复

### 移除
- 移除的功能

## [1.2.0] - 2026-06-15

### 新增
- 用户认证模块

### 修复
- 分页参数越界问题
```

## 变更分类

| 类别 | 前缀 | 对应 Commit Type | 说明 |
|------|------|-----------------|------|
| 新增 | `### 新增` | `feat` | 新功能 |
| 变更 | `### 变更` | `refactor`、`perf` | 现有行为的变更 |
| 修复 | `### 修复` | `fix` | Bug 修复 |
| 移除 | `### 移除` | `fix`（删除） | 移除的功能 |
| 安全 | `### 安全` | `fix`（安全） | 安全相关的修复 |
| 废弃 | `### 废弃` | `feat`（废弃） | 即将移除的功能 |
| 文档 | `### 文档` | `docs` | 仅文档变更（可选） |

## 生成流程

### 1. 确定版本范围

```bash
# 找到上一个版本标签
git describe --tags --abbrev=0

# 列出从上个版本到现在的提交
git log <上个版本>..HEAD --oneline
```

### 2. 按类型分类提交

从提交信息中提取 type 前缀，归入对应分类：

```bash
# 提取并分类
git log <上个版本>..HEAD --pretty=format:"%s" | grep "^feat"    # → 新增
git log <上个版本>..HEAD --pretty=format:"%s" | grep "^fix"     # → 修复
git log <上个版本>..HEAD --pretty=format:"%s" | grep "^refactor" # → 变更
git log <上个版本>..HEAD --pretty=format:"%s" | grep "^perf"    # → 变更
git log <上个版本>..HEAD --pretty=format:"%s" | grep "^docs"    # → 文档
```

### 3. 清理提交信息

- 移除 type 前缀（`feat(auth): 添加微信登录` → `添加微信登录`）
- 添加 PR 链接（如有）
- 合并相关的小提交

### 4. 写入 CHANGELOG.md

在 `## [未发布]` 下方插入新版本块：

```markdown
## [X.Y.Z] - YYYY-MM-DD

### 新增
- 功能描述 ([#PR号](链接))

### 修复
- Bug 描述 ([#PR号](链接))
```

### 5. 更新版本链接

在文件底部更新版本比较链接：

```markdown
[未发布]: https://github.com/组织/仓库/compare/vX.Y.Z...HEAD
[X.Y.Z]: https://github.com/组织/仓库/compare/vX.Y.Z-1...vX.Y.Z
```

## 何时更新

| 场景 | 操作 |
|------|------|
| 新功能开发完成 | 在 `[未发布]` 下添加条目 |
| Bug 修复完成 | 在 `[未发布]` 下添加条目 |
| 版本发布时 | 将 `[未发布]` 内容移到新版本号下 |
| PR 合并时 | 检查是否需要更新 CHANGELOG |

## 注意事项

- **不要**自动从 git log 生成而不人工审阅——提交信息质量参差不齐
- **不要**包含内部重构（用户不关心的变更）
- **不要**遗漏破坏性变更（Breaking Changes）——必须在版本说明中醒目标注
- **要**用中文写（跟随团队惯例）
- **要**链接到对应的 PR 或 Issue
