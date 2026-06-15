---
name: api-docs
description: 新增/修改 API 端点后使用。生成和维护 API 文档（OpenAPI/Swagger）。
---

# API 文档 (API Documentation)

> 来源：社区最佳实践（OpenAPI 3.x 规范 + Keep a Changelog 格式）
> 适用场景：新增 API、修改 API、版本发布前文档同步

## 核心原则

```
代码即文档的真相来源。文档必须与代码同步更新。
```

## 文档格式

使用 **OpenAPI 3.x** 规范（YAML 格式）：

```yaml
openapi: 3.0.3
info:
  title: 项目名称 API
  version: 1.0.0
  description: 项目描述

paths:
  /api/v1/users/{id}:
    get:
      summary: 获取用户详情
      operationId: getUserById
      tags:
        - 用户
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
          description: 用户 ID
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
              example:
                id: 1
                name: "张三"
                phone: "138****1234"
        '404':
          description: 用户不存在
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
              example:
                code: 404
                message: "User not found"

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        phone:
          type: string
    Error:
      type: object
      properties:
        code:
          type: integer
        message:
          type: string
```

## 文档生成流程

### 方案 A：代码注解自动生成（推荐）

在代码中用注解标记 API，工具自动生成 OpenAPI spec：

**Python (FastAPI):**
```python
@app.get("/api/v1/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """获取用户详情"""
    ...
```

**Java (Spring Boot):**
```java
@Operation(summary = "获取用户详情")
@GetMapping("/api/v1/users/{id}")
public ResponseEntity<User> getUser(@PathVariable Long id) { ... }
```

**Node.js (Express + zod-to-openapi):**
```typescript
router.get('/api/v1/users/:id', {
  summary: '获取用户详情',
  parameters: [{ name: 'id', in: 'path', schema: { type: 'integer' } }],
  responses: { 200: { description: '成功' } }
}, handler);
```

### 方案 B：手动维护 OpenAPI 文件

如果没有注解框架，在 `docs/api/openapi.yaml` 手动维护。

## 文档检查清单

新增或修改 API 后，必须确认：

- [ ] **路径和方法** — 正确（GET/POST/PUT/DELETE）
- [ ] **参数** — 所有路径参数、查询参数、请求体都已声明
- [ ] **请求体** — schema 完整，包含必填字段标记
- [ ] **响应** — 成功和失败响应都有定义
- [ ] **鉴权** — 需要鉴权的端点已标注
- [ ] **示例** — 每个端点有请求和响应示例
- [ ] **错误码** — 所有可能的错误码都有说明
- [ ] **版本** — 文档版本与 API 版本一致

## 文档结构

```
docs/
└── api/
    ├── openapi.yaml         ← OpenAPI spec 主文件
    ├── README.md            ← 快速开始指南
    └── examples/            ← 请求/响应示例
        ├── user-create.json
        └── user-list.json
```

## 与 changelog 的关系

- API 变更必须记录到 CHANGELOG.md
- Breaking Changes 必须在版本说明中醒目标注
- 废弃的端点标注 `deprecated: true`，保留至少一个大版本

## 注意事项

- **不要**输出完整密钥、密码、Token 的真实值（用 `****` 占位）
- **不要**遗漏错误响应（只写 200 不写 4xx/5xx）
- **要**包含鉴权说明（Bearer Token / API Key / Cookie）
- **要**在 CI 中集成文档校验（`swagger-cli validate`）
