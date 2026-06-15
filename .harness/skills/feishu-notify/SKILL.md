---
name: feishu-notify
description: 配置飞书 Webhook 集成，让 CI/CD 流水线自动推送构建结果到飞书群。
---

# 飞书 Webhook 集成配置

## 设置步骤

### 1. 创建飞书自定义机器人

1. 打开目标飞书群 → 设置 → 群机器人 → 添加机器人
2. 选择「自定义机器人」
3. 设置名称（如「Harness CI」）和头像
4. 复制 Webhook URL（格式：`https://open.feishu.cn/open-apis/bot/v2/hook/xxx`）

### 2. 配置 CI 密钥

在 GitHub/GitLab 仓库设置中添加 Secret：
- **GitHub**: Settings → Secrets → Actions → New repository secret
  - Name: `FEISHU_WEBHOOK_URL`
  - Value: 你的 Webhook URL
- **GitLab**: Settings → CI/CD → Variables
  - Key: `FEISHU_WEBHOOK_URL`
  - Value: 你的 Webhook URL

### 3. 通知场景

| 触发事件 | 通知内容 | 卡片颜色 |
|----------|----------|----------|
| PR 创建 | 标题、分支、作者 | 🔵 蓝色 |
| CI 通过 | 各门控状态 | 🟢 绿色 |
| CI 失败 | 失败的门控 + 日志链接 | 🔴 红色 |
| PR 合并 | 合并到哪个分支 | 🟢 绿色 |

### 4. 消息格式

使用飞书交互卡片（Interactive Card），支持：
- Markdown 格式
- 按钮跳转到 PR/CI 页面
- @人 提醒（可选）

### 5. 高级配置

如果需要 @特定人，可以在卡片中添加：
```json
{
  "tag": "at",
  "user_id": "ou_xxxxx"
}
```

如果需要按钮跳转：
```json
{
  "tag": "action",
  "actions": [
    {
      "tag": "button",
      "text": { "tag": "plain_text", "content": "查看 PR" },
      "type": "primary",
      "url": "https://github.com/org/repo/pull/123"
    }
  ]
}
```
