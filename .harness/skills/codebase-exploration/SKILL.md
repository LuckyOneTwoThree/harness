---
name: codebase-exploration
description: 新人加入项目或 Agent 接手陌生代码库时使用。系统性理解项目架构、代码结构和关键模块。
---

# 代码库探索 (Codebase Exploration)

> 来源：综合 Superpowers brainstorming 的"探索项目上下文"步骤 + 社区实践
> 适用场景：新人上手、Agent 首次接触项目、跨团队协作

## 目标

在最短时间内回答三个问题：
1. **这个项目做什么？**（业务目标）
2. **怎么做的？**（技术架构）
3. **关键代码在哪？**（入口和核心模块）

## 探索流程

### 阶段 1：项目概况（5 分钟）

```bash
# 1. 读 README
cat README.md

# 2. 看项目结构（前两层）
find . -maxdepth 2 -type f -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name "Makefile" -o -name "Dockerfile" | head -30

# 3. 看配置文件了解技术栈
cat package.json 2>/dev/null | head -20      # Node.js
cat pyproject.toml 2>/dev/null | head -20    # Python
cat go.mod 2>/dev/null | head -10            # Go
cat pom.xml 2>/dev/null | head -20           # Java
```

**输出：** 一句话描述项目 + 技术栈列表

### 阶段 2：架构理解（10 分钟）

```bash
# 1. 看目录结构
tree -L 2 -d --charset ascii 2>/dev/null || find . -maxdepth 2 -type d | sort

# 2. 找入口文件
# Python: main.py, app.py, manage.py, __main__.py
# Node: index.ts, server.ts, app.ts
# Go: cmd/*/main.go
# Java: *Application.java

# 3. 看路由/API 定义（如有）
grep -rn "router\.\|@app\.\|@RestController\|func.*Handle" --include="*.py" --include="*.ts" --include="*.go" --include="*.java" src/ 2>/dev/null | head -20

# 4. 看数据库模型（如有）
grep -rn "class.*Model\|@Entity\|type.*struct" --include="*.py" --include="*.ts" --include="*.go" --include="*.java" src/ 2>/dev/null | head -20
```

**输出：** 架构分层图（前端/后端/数据库/外部服务）

### 阶段 3：关键模块识别（10 分钟）

```bash
# 1. 找最近活跃的文件（开发者关注的重点）
git log --diff-filter=M --name-only --pretty=format: --since="1 month ago" | sort | uniq -c | sort -rn | head -20

# 2. 找最大的文件（可能是核心逻辑）
find . -name "*.py" -o -name "*.ts" -o -name "*.go" -o -name "*.java" | xargs wc -l 2>/dev/null | sort -rn | head -20

# 3. 看测试覆盖（了解哪些模块有测试）
find . -path "*/test*" -name "*.py" -o -path "*/test*" -name "*.ts" -o -path "*/test*" -name "*.go" | head -20
```

**输出：** 核心模块列表 + 各自职责

### 阶段 4：约束和规范（5 分钟）

```bash
# 1. 看 Agent/项目规范
cat AGENTS.md 2>/dev/null
cat CLAUDE.md 2>/dev/null

# 2. 看 CI/CD 配置
cat .github/workflows/*.yml 2>/dev/null | head -40

# 3. 看代码规范
cat .eslintrc* 2>/dev/null | head -20
cat .prettierrc 2>/dev/null
cat ruff.toml 2>/dev/null
```

**输出：** 项目约束列表（编码规范、CI 要求、禁止事项）

## 输出模板

探索完成后，生成一份简要报告：

```markdown
## 代码库探索报告

### 项目概述
- **名称**: [项目名]
- **做什么**: [一句话描述]
- **技术栈**: [语言 + 框架 + 数据库 + 关键依赖]

### 架构
```
[前端] → [API 层] → [业务层] → [数据层]
```

### 关键模块
| 模块 | 路径 | 职责 |
|------|------|------|
| [模块1] | `src/xxx/` | [职责] |
| [模块2] | `src/yyy/` | [职责] |

### 入口文件
- 启动入口: `src/main.py`
- API 入口: `src/api/routes.py`
- 配置入口: `config/`

### 约束
- [编码规范要点]
- [CI 要求]
- [禁止事项]

### 建议新手从哪里开始
- [最简单的模块入口]
- [有完善测试的模块]
```

## 注意事项

- **先读后写**。探索阶段不要修改任何代码。
- **按层次深入**。先看目录结构，再看入口文件，最后看核心逻辑。
- **记录发现**。把探索结果写到 progress.md，方便后续会话复用。
