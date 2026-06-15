# 常见问题排查

## 初始化问题

### init-project.sh 报错 "permission denied"
```bash
chmod +x .harness/scripts/*.sh
chmod +x .harness/hooks/*.sh
chmod +x .harness/hooks/guards/*.sh
```

### Git hooks 不生效
```bash
# 确认 hooks 已安装
ls -la .git/hooks/pre-commit
# 如果不存在，重新运行
bash .harness/scripts/init-project.sh
```

### Windows 上脚本执行失败
Git Bash / MSYS 环境下运行。如果遇到 CRLF 问题：
```bash
git config core.autocrlf input
```

## PRD 相关

### Agent 拒绝编码，提示 DoR 未满足
检查 PRD 的 YAML frontmatter：
```yaml
prd_status:
  product: done        # PM 填完了？
  development: done    # Dev 补完了？
  testing: done        # QA 补完了？
  approved_by: "张三"  # 审批人签字了？
```
全部满足后 Agent 才允许编码。

### register-prd.sh 报错 "features.json 不存在"
先运行初始化：
```bash
bash .harness/scripts/init-project.sh
```

### PRD 变更后 Agent 不知道
session-start 会自动检测。如果没检测到：
```bash
bash .harness/scripts/check-prd-changes.sh
```

## 设计相关

### Agent 使用了魔法数值
确保 `.harness/context/design/DESIGN-TOKENS.json` 存在且内容完整。
```bash
bash .harness/scripts/validate-context.sh
```

### validate-context.sh 报错 "缺失必填 Token"
DESIGN-TOKENS.json 必须包含以下关键路径：
- `color.error`
- `typography.fontSize`
- `zIndex`
- `animation`
- `opacity`
- `form`
- `icon`

## 脚本问题

### archive-progress.sh 归档阈值调整
```bash
# 环境变量覆盖默认值
export HARNESS_ARCHIVE_THRESHOLD=200  # 默认 150
export HARNESS_KEEP_LINES=80          # 默认 60
```

### security-check.sh 误报
如果某行代码被误判为安全问题，添加豁免注释：
```python
password = get_password()  # harness:allow 密码从 Secret Manager 获取
```

## 工作流问题

### 不知道该用哪个 Skill
参考 `.harness/skills/workflow/SKILL.md` 的"触发规则"表。
简要判断：
- 新功能 → brainstorming → plan → tdd → verify → code-review → finish-branch
- Bug 修复 → debug → tdd → verify → finish-branch
- 只做审查 → code-review

### Skill 之间冲突
Skill 的优先级：verify > tdd > code-review > 其他。
如果两个 Skill 给出矛盾的指令，以 verify 为准。
