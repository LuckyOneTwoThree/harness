# JavaScript/TypeScript 编码规范

## 工具链
- 格式化：**Prettier**
- Lint：**ESLint**（flat config）
- 类型检查：**TypeScript**（strict 模式）
- 测试：**Vitest** 或 **Jest**
- 包管理：**pnpm**（优先）或 npm

## 代码风格
- 单引号 `''`，无分号
- 使用 `const` 优先，需要重赋值时用 `let`，禁止 `var`
- 函数式优先，避免 class（除非有明确理由）
- 异步统一用 `async/await`，不用 `.then()` 链

## React 组件规范
- 优先使用函数组件 + Hooks，class 组件仅在 Error Boundary 时使用
- 组件文件结构：props 类型定义 → 组件 → 导出
- 状态管理：组件内用 `useState`，跨组件用 Context 或状态库（Zustand/Jotai）
- 禁止在渲染过程中产生副作用（必须放在 `useEffect` 中）
- `useEffect` 依赖数组必须完整，不要省略

## Node.js 后端规范
- 错误处理：全局错误中间件捕获，不在每个路由里 try-catch
- 环境变量：启动时校验必填变量，缺失则立即退出（fail-fast）
- 优雅关闭：监听 `SIGTERM` / `SIGINT`，关闭 HTTP 服务器和数据库连接
- 请求校验：使用 Zod / Joi / class-validator 校验请求体

## 包体积控制（前端项目）
- import 使用具名导入：`import { map } from 'lodash-es'` 而非 `import _ from 'lodash'`
- 定期运行 `pnpm build --analyze` 检查 bundle 体积
- 大依赖考虑动态导入：`const Heavy = React.lazy(() => import('./Heavy'))`

## 禁止事项
- ❌ `any` 类型（除非有注释说明理由）
- ❌ `console.log` 在生产代码中（用 logger）
- ❌ `==`（必须用 `===`）
- ❌ `// @ts-ignore`（必须修复类型问题）
- ❌ 在 React 组件中直接操作 DOM

## 项目结构（推荐）
```
project/
├── src/
│   ├── index.ts
│   ├── components/
│   ├── hooks/
│   ├── utils/
│   └── types/
├── tests/
│   ├── setup.ts
│   └── *.test.ts
├── tsconfig.json
├── eslint.config.js
├── .prettierrc
├── package.json
└── AGENTS.md
```
