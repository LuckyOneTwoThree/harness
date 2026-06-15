# PRD 使用指南

> 给产品经理和技术负责人的参考文档。
> 定义什么时候用哪个模板、谁填写什么、DoR 流程怎么走。

## 需求分级

| 级别 | 工作量 | 模板 | DoR 要求 |
|------|--------|------|----------|
| **S（口头需求）** | < 0.5 天 | 不需要 PRD，直接在 features.json 中描述 | 无 |
| **M（轻量需求）** | 1-3 天 | `PRD-TEMPLATE-M.md` | product done + approved_by |
| **L（完整需求）** | > 3 天 | `PRD-TEMPLATE-L.md` | product + development + testing 全部 done + approved_by |

### 如何选择

```
改动 < 0.5 天？
  ├── 是 → S 级：口头需求，直接写入 features.json
  └── 否 → 涉及多个模块？
                ├── 否 → M 级：轻量模板
                └── 是 → L 级：完整模板
```

## 填写流程

### L 级 PRD 填写流程

```
PM 填写业务部分（第 1-3、7.1、8 章）
  ↓ prd_status.product = done
  ↓ 通知 Dev
Dev 补充技术部分（第 4-5 章）
  ↓ prd_status.development = done
  ↓ 通知 QA
QA 补充测试部分（第 7.2、9 章）
  ↓ prd_status.testing = done
  ↓ 通知审批人
审批人确认
  ↓ prd_status.approved_by = "姓名"
  ↓ Agent 可以开始开发
```

### M 级 PRD 填写流程

```
PM / Tech Lead 填写（第 1-4 章）
  ↓ prd_status.product = done
  ↓ Dev 可选补充第 5 章
审批人确认
  ↓ prd_status.approved_by = "姓名"
  ↓ Agent 可以开始开发
```

## 文件命名规范

```
PRD-YYYY-NNN-<功能名简称>.md      # L 级（完整需求）
PRD-YYYY-NNN-M-<功能名简称>.md    # M 级（轻量需求）
```

示例：
```
PRD-2026-001-user-login.md
PRD-2026-002-M-add-phone-field.md
```

## 大功能拆分

当一个功能需要拆分成多个子 PRD 时：

1. 创建 Epic PRD（使用 L 级模板）
2. 在 `related_prds` 字段中列出所有子 PRD
3. 每个子 PRD 独立创建，使用 L 或 M 级模板
4. features.json 中的子任务通过 `parent_ref` 指向 Epic PRD

```
PRD-2026-001-ecommerce.md          ← Epic PRD（只定义全局约束 + 子 PRD 索引）
├── PRD-2026-001a-product-catalog.md  ← 子 PRD
├── PRD-2026-001b-shopping-cart.md    ← 子 PRD
├── PRD-2026-001c-order.md            ← 子 PRD
└── PRD-2026-001d-payment.md          ← 子 PRD
```

## PRD 变更规则

1. 修改 PRD 时必须更新 `last_updated` 和 `version`
2. 在"变更记录"章节追加变更说明
3. 如果变更影响已开发的功能，必须将相关 features.json 条目状态重置为 `pending`
4. Agent 在 session-start 时会检测 PRD 变更（通过 `check-prd-changes.sh`）

## 常见问题

**Q: PM 不会写技术部分怎么办？**
A: PM 只需填写 `prd_status.product` 对应的章节。技术部分由 Dev 补充。PM 可以在技术备注中写"请 Dev 补充"。

**Q: 小改动也需要写 PRD 吗？**
A: S 级（< 0.5 天）不需要。直接在 features.json 中描述即可。

**Q: PRD 被 Agent 拒绝了怎么办？**
A: 检查 prd_status 是否所有必填项都为 done，approved_by 是否有值。
