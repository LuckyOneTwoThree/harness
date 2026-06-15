# Java 编码规范

## 工具链
- 格式化：**google-java-format** 或 **Spotless**
- Lint：**SpotBugs** + **Checkstyle**
- 构建：**Maven** 或 **Gradle**
- 测试：**JUnit 5** + **Mockito**
- 代码质量：**SonarQube**

## 代码风格
- 遵循 Google Java Style Guide
- 类名：PascalCase
- 方法名/变量名：camelCase
- 常量：UPPER_SNAKE_CASE
- 包名：全小写，用 `.` 分隔

## 分层架构规范
```
Controller  → 接收请求，参数校验，调用 Service，返回响应
Service     → 业务逻辑，事务管理，调用 Repository
Repository  → 数据访问，只做 CRUD，不包含业务逻辑
```
- **DTO**（Data Transfer Object）：API 请求/响应的数据载体，不含业务逻辑
- **Entity**：数据库表映射，只用于 Repository 层
- **VO**（View Object）：返回给前端的展示对象（可选，DTO 可兼用）
- 各层之间必须通过 DTO/VO 转换，禁止直接传递 Entity 到 Controller

## 异常体系
```java
// 业务异常（可恢复，返回 4xx）
public class BusinessException extends RuntimeException {
    private final ErrorCode code;
}

// 系统异常（不可恢复，返回 5xx，触发告警）
public class SystemException extends RuntimeException {}

// 全局异常处理器
@RestControllerAdvice
public class GlobalExceptionHandler {
    // 捕获 BusinessException → 返回对应错误码
    // 捕获 SystemException → 返回 500 + 记录 ERROR 日志
    // 捕获 MethodArgumentNotValidException → 返回 400 + 校验错误详情
}
```

## Spring Boot 约定（如适用）
- 配置注入用 `@ConfigurationProperties`，不用 `@Value` 逐个注入
- Bean 优先使用构造器注入，不用 `@Autowired` 字段注入
- 事务注解 `@Transactional` 只加在 Service 层
- 异步任务用 `@Async` + 自定义线程池，不用默认线程池

## 禁止事项
- ❌ `System.out.println`（用 SLF4J Logger）
- ❌ 裸 `catch (Exception e)` 空处理
- ❌ `@SuppressWarnings` 无注释说明
- ❌ 可变的 static 字段
- ❌ 过长的类（超过 500 行考虑拆分）

## 项目结构（推荐）
```
project/
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/company/project/
│   │           ├── Application.java
│   │           ├── controller/
│   │           ├── service/
│   │           ├── repository/
│   │           ├── model/
│   │           │   ├── dto/
│   │           │   ├── entity/
│   │           │   └── vo/
│   │           └── config/
│   └── test/
│       └── java/
│           └── com/company/project/
├── pom.xml / build.gradle
└── AGENTS.md
```
