# 设计交付指南

> 给 UI 设计师的参考文档。
> 定义如何将设计规范导出为 Agent 可消费的格式。

## 核心原则

Agent 不能使用"魔法数值"（hardcoded colors、font sizes、spacing、z-index）。
所有视觉属性必须来自 DESIGN-TOKENS.json。

## 交付流程

### 步骤 1：在 Figma 中定义设计变量

在 Figma 中使用 Variables / Styles 定义：
- 颜色（主色、中性色、语义色）
- 字体（字号、字重、行高）
- 间距（spacing scale）
- 圆角、阴影、断点
- 层级规范（Z-Index）

### 步骤 2：导出为 JSON

使用以下 Figma 插件导出：

| 插件 | 说明 |
|------|------|
| **Tokens Studio** (推荐) | 最成熟的 Figma → JSON 导出工具 |
| **Style Dictionary** | Amazon 出品，支持多格式输出 |
| **Figma Tokens** | 轻量级，适合小团队 |

导出后保存为 `.harness/context/design/DESIGN-TOKENS.json`

### 步骤 3：验证格式

运行校验脚本：
```bash
bash .harness/scripts/validate-context.sh
```

确保 JSON 格式正确、必填字段完整。

## DESIGN-TOKENS.json 结构

```json
{
  "_meta": { ... },       // 元信息
  "color": { ... },       // 基础颜色系统
  "semanticColor": { ... },// 语义颜色（极其重要）
  "typography": { ... },  // 字体系统
  "spacing": { ... },     // 间距系统
  "borderRadius": { ... },// 圆角
  "shadow": { ... },      // 阴影
  "zIndex": { ... },      // Z-Index 层级（防止 AI 幻觉乱写 9999）
  "opacity": { ... },     // 透明度
  "breakpoint": { ... }   // 响应式断点
}
```

## Agent 消费方式

当 Agent 生成前端代码时：
1. **颜色取值**：优先从 `semanticColor` 中获取具备业务语义的色值（如背景色、文字色、边框色）。不要直接引用 `color.neutral.50`，而是引用 `semanticColor.bg.muted`。
2. **绝对禁止魔法 Z-Index**：任何悬浮层、Modal、Tooltip 必须引用 `zIndex` 里的定义。
3. **字号与间距**：所有字号从 `typography.fontSize` 取，所有间距从 `spacing` 取。

## 图标与资源约束 (Iconography & Assets)

大模型在前端开发时，极其容易幻觉出各种不存在的图标库（比如自行 `npm install react-icons` 或 `lucide-react`）。为了遏制这种行为，**必须向大模型明确图标方案**。

**请与前端开发确认并在 Agent 提示词中明确约定：**
1. **图标库**：本项目使用什么组件库？（如："所有图标统一使用 `lucide-react`"，或者 "使用存放于 `src/assets/icons/` 下的自定义 SVG"）。
2. **图片切图**：设计师提供的 PNG/WebP 必须存放在项目约定的统一目录（如 `/public/images/`），大模型必须基于该目录相对引用。

## 常见问题

**Q: 设计师不会用 Figma 插件怎么办？**
A: 手动填写 DESIGN-TOKENS.json.example，去掉 `.example` 后缀即可。不需要完美，先覆盖常用值。

**Q: 已有项目的样式是散落的怎么办？**
A: 先从现有代码中提取当前使用的颜色和字号，整理到 DESIGN-TOKENS.json 中。Agent 后续开发统一引用。

**Q: 暗色模式怎么处理？**
A: 在 DESIGN-TOKENS.json 中增加 `"theme": { "light": { ... }, "dark": { ... } }` 结构。

## 代码消费示例 (Code Consumption Examples)

为了让 Agent 明确如何将 JSON Token 转换为前端代码，请在项目中约定以下方案之一：

**方案 A：Tailwind CSS 集成（推荐）**
要求 Agent 编写脚本将 `DESIGN-TOKENS.json` 自动解析并注入到 `tailwind.config.js` 的 `theme.extend` 中。
```javascript
// tailwind.config.js 示例
const tokens = require('./.harness/context/design/DESIGN-TOKENS.json');
module.exports = {
  theme: {
    extend: {
      colors: tokens.color,
      zIndex: tokens.zIndex,
      transitionDuration: tokens.animation.duration,
      opacity: tokens.opacity
    }
  }
}
```

**方案 B：CSS Variables 注入**
要求 Agent 写一个预处理脚本，将 JSON 转换为 `:root` 下的 CSS 变量，放到 `global.css` 中。
```css
:root {
  --color-primary-500: #3B82F6;
  --z-modal: 500;
  --icon-size-sm: 16px;
}
```

## Token 新增流程 (Addition Workflow)

当 Agent 在开发中发现设计稿出现了一个未在 `DESIGN-TOKENS.json` 中定义的新值（例如一个特殊的 600px 宽度或新的动画时长）时，**禁止** Agent 直接硬编码。必须遵循以下流程：

1. **就近降级**：Agent 尝试从现有的 Token 列表中寻找最接近的值（如要求 18px，尝试使用已有的 20px）。
2. **发起提案**：如果必须新增，Agent 需要在 `features.json` 的对应任务评论中，或直接在控制台向人类提问：“发现缺失的设计变量 [变量名]，建议值为 [值]，是否允许添加到 DESIGN-TOKENS 中？”
3. **人类审批**：由人类（或 UI 设计师）确认后，手动或授权 Agent 补充到 `DESIGN-TOKENS.json` 中。
4. **禁止私自越权**：未经允许，Agent 绝不能单方面修改 `.harness/context/design/` 下的源文件。

## 校验规则 (Validation Rules)

工程层的 `validate-context.sh` 不仅仅检查 JSON 是否符合格式，还会执行**结构完整性断言 (Schema Validation)**。

目前脚本会强制断言以下关键路径是否存在，缺失任何一项都会导致 Commit 失败：
- `color.error` (错误色，极易遗漏)
- `typography.fontSize`
- `zIndex`
- `animation`
- `opacity`
