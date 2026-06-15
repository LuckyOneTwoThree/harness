# 贡献指南

> 如何给 harness 模板贡献新内容。

## 贡献范围

| 类型 | 示例 | 流程 |
|------|------|------|
| 新增 Skill | 添加一个 "database-migration" skill | 创建目录 + SKILL.md → 更新 workflow → PR |
| 修改规则 | 更新 security.md 增加新的安全检查 | 直接修改 → PR |
| 新增 Guard | 添加一个 guard-database.sh | 创建文件 → 更新 pre-commit 调用逻辑 → PR |
| 新增模板 | 添加一个新语言的 rules/languages/xxx.md | 创建文件 → PR |
| 修复 Bug | 修复脚本中的错误 | 直接修复 → PR |

## Skill 贡献规范

新增 Skill 必须：

1. **目录结构：** `.harness/skills/<名称>/SKILL.md`
2. **YAML frontmatter：** 必须包含 `name` 和 `description`
3. **内容要求：**
   - 何时触发（When to Use）
   - 具体步骤（Steps）
   - 禁止事项（Don'ts）
   - 与其他 Skill 的关系
4. **更新 workflow：** 在 `.harness/skills/workflow/SKILL.md` 的触发规则表中添加条目

## 规则贡献规范

修改 `.harness/rules/` 下的文件时：

1. 每条规则必须说明**为什么**（不只是"是什么"）
2. 如果规则来自外部来源，标注来源链接
3. 如果规则与已有规则冲突，在文件头说明优先级

## 脚本贡献规范

新增 `.harness/scripts/` 下的脚本时：

1. 必须有 shebang 行（`#!/bin/bash`）
2. 必须有 `set -e`
3. 必须有使用说明（注释中的 `用法:`）
4. 必须有彩色输出（GREEN/YELLOW/RED）
5. 必须在退出时返回正确的退出码

## PR 规范

- 标题：`feat(harness): <描述>` 或 `fix(harness): <描述>`
- 描述：说明改了什么、为什么改、影响哪些模块
- 必须在至少一个项目中验证过
