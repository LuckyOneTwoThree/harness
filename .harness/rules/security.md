# 组织级代码安全红线 (Security Red Lines)

> 以下规则由 `.harness/scripts/security-check.sh` 在每次提交时自动检查，Agent 无法绕过。
> 安全规则优先级最高，与任何其他规范冲突时以本文件为准。

## 🔴 绝对禁止

### 凭据安全
- 禁止硬编码 API Key、Token、密码、Secret。
- 所有凭据从环境变量或 Secret Manager（Vault / AWS Secrets Manager / 飞书密钥管理）读取。
- `.env` 文件必须在 `.gitignore` 中。
- 日志中不得输出完整密钥（最多显示前 4 位 + `****`）。
- 密钥轮换：长期凭据至少每 90 天轮换一次。

### 防注入攻击
- **SQL**：必须使用参数化查询或 ORM，禁止拼接 SQL 字符串。
- **XSS**：渲染用户输入前必须转义或使用框架安全引擎。
- **Command**：禁止将用户输入未经过滤直接带入 `exec` / `system`。
- **SSRF**：禁止将用户可控的 URL 直接用于服务端请求，必须校验目标地址。

### 输入校验
- 所有外部输入（用户输入、API 请求参数、文件上传内容）必须校验：
  - **类型**：字符串/数字/布尔，不信任前端传来的类型
  - **长度**：字符串最大长度、数组最大元素数
  - **范围**：数值的上下界、枚举值的合法集合
  - **格式**：邮箱、手机号、URL 等用正则校验
- 校验失败返回 400，不返回具体的校验规则（防探测）。

### 敏感数据屏蔽 (PII)
- 打印日志时，必须对手机号、身份证号、银行卡号等脱敏（如 `138****1234`）。
- 邮箱地址脱敏：`u***@example.com`。
- 密码在任何场景下都不可逆存储，必须使用 bcrypt/scrypt/argon2 哈希。

### 破坏性操作
- 禁止 `rm -rf /`、`DROP TABLE`（无 WHERE）、`TRUNCATE`。
- 禁止 `chmod 777`。
- 禁止 `curl | sh` 或 `wget | sh`。

### 认证与鉴权
- 新增 API 端点必须声明鉴权方式（公开接口需在代码中注释说明理由）。
- Token 存储：前端用 HttpOnly Cookie 或安全存储，禁止 localStorage。
- Token 过期：Access Token ≤ 30 分钟，Refresh Token 可更长但必须可撤销。
- 权限校验在服务端执行，不信任客户端传来的角色/权限信息。

## 🟡 需要审查

- 新增外部依赖（检查 CVE、维护状态、License、typosquatting 风险）。
- CORS 配置（不允许 `*` 在生产环境，必须指定明确的 origin）。
- 新增 API 端点（需要鉴权 + 速率限制 + 输入校验）。
- 数据库 schema 变更（需要迁移脚本 + 回滚方案）。
- 文件上传（限制类型、大小、存储路径，禁止直接执行上传文件）。

## 供应链安全

- 依赖安装使用 lockfile，并定期审计（`npm audit` / `pip-audit` / `go vuln`）。
- 禁止从非官方源安装依赖（除非配置了公司内部私有源并说明理由）。
- 新增依赖前检查：最近一次发布时间、维护者数量、已知漏洞。
- CI 中集成依赖漏洞扫描（已在 `github-actions.yml` 中配置）。

## 安全配置保护

禁止绕过以下安全机制（除非加 `# harness:allow` 并注释理由）：
- Linter 规则（`eslint-disable`、`# noqa`）
- 类型检查（`@ts-ignore`）
- HTTPS 证书验证（`verify=False`）
- Git hooks（`--no-verify`）
