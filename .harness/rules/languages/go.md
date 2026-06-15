# Go 编码规范

## 工具链
- 格式化：**gofmt**（内置，不可协商）
- Lint：**golangci-lint**
- 测试：**go test** + **testify**
- 依赖：**Go Modules**
- 文档：**go doc**

## 代码风格
- 遵循 Effective Go 和 Go Code Review Comments
- 函数/变量首字母大写 = 导出，小写 = 包内私有
- 接口名以 `-er` 结尾（Reader、Writer、Closer）
- 错误处理：`if err != nil` 模式，不忽略错误

## context.Context 使用
- 函数第一个参数必须是 `ctx context.Context`（涉及 IO / 网络 / 超时控制的函数）
- 禁止把 context 存到 struct 里，必须通过参数传递
- 禁止用 context 存大量数据（它只是传递取消信号和少量元数据）
- 使用 `context.WithTimeout` 控制外部调用超时，不要依赖默认超时

```go
// ✅ 推荐
func (s *UserService) GetByID(ctx context.Context, id int64) (*User, error) {
    ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
    defer cancel()
    return s.repo.FindByID(ctx, id)
}
```

## Goroutine 管理
- 禁止 fire-and-forget：每个 goroutine 必须有生命周期管理
- 使用 `errgroup` 管理一组 goroutine，统一错误处理和取消
- 使用 `context.WithCancel` 确保 goroutine 可以被优雅终止
- 监控 goroutine 泄漏：`runtime.NumGoroutine()` 异常增长需排查

```go
// ✅ 推荐：errgroup 模式
g, ctx := errgroup.WithContext(ctx)

g.Go(func() error {
    return fetchUserData(ctx, userID)
})

g.Go(func() error {
    return fetchOrderData(ctx, userID)
})

if err := g.Wait(); err != nil {
    return err
}
```

## 错误包装
- 底层错误必须用 `%w` 包装，保留错误链
- 判断错误类型用 `errors.Is` / `errors.As`，不用字符串比较
- 错误信息格式：`<操作>: <原因>`（如 `query user: connection timeout`）

```go
// ✅ 推荐
user, err := repo.FindByID(ctx, id)
if err != nil {
    return nil, fmt.Errorf("get user by id %d: %w", id, err)
}

// ✅ 判断错误类型
if errors.Is(err, sql.ErrNoRows) {
    return nil, ErrUserNotFound
}
```

## 禁止事项
- ❌ `panic()` 在库代码中（只在 main 包或初始化时使用）
- ❌ 忽略错误返回值 `_ = doSomething()`
- ❌ 使用 `init()` 函数（除非有充分理由）
- ❌ 循环导入
- ❌ 过度使用 `interface{}` / `any`
- ❌ goroutine 泄漏（无生命周期管理的 goroutine）

## 项目结构（推荐）
```
project/
├── cmd/
│   └── app/
│       └── main.go
├── internal/
│   ├── handler/
│   ├── service/
│   ├── repository/
│   └── model/
├── pkg/           ← 可复用的公共库
├── api/           ← API 定义（proto/openapi）
├── go.mod
├── go.sum
└── AGENTS.md
```
