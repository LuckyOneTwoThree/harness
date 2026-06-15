# Python 编码规范

## 工具链
- 格式化：**black**（默认配置）
- 排序：**isort**（profile=black）
- Lint：**ruff**（替代 flake8 + pylint）
- 类型检查：**mypy**（strict 模式）
- 测试：**pytest**
- 依赖管理：**poetry** 或 **pip-tools**

## 代码风格
- 遵循 PEP 8
- 字符串统一用双引号 `""`
- 类型注解：所有函数签名必须有类型注解
- Docstring：所有公开函数/类必须有 Google 风格 docstring

## 复杂类型注解
```python
# ✅ 推荐写法
from typing import Optional, Union
from dataclasses import dataclass

def get_user(user_id: int) -> Optional[User]:
    ...

def process(value: Union[str, int]) -> str:
    ...

# ✅ Python 3.10+ 可用 | 语法
def process(value: str | int) -> str:
    ...
```
- `Optional[X]` 优于 `Union[X, None]`（3.10 以下）
- 复杂泛型用 `TypeVar` / `Generic`，不要用 `Any` 偷懒

## 异步编程
- `async` 函数内禁止调用同步阻塞操作（`time.sleep`、同步 IO、同步 HTTP）
- 阻塞操作用 `asyncio.to_thread()` 或对应的异步库（`aiohttp`、`asyncpg`）
- 数据库连接使用异步驱动（`asyncpg`、`aiomysql`）或 ORM 的异步模式

## 数据模型
- 简单数据容器用 `@dataclass`
- 需要校验/序列化的场景用 **Pydantic**（API 请求/响应、配置文件）
- ORM Model 只用于数据库映射，不用于业务逻辑传输
- 三种模型之间必须有明确的转换层，不要混用

## 禁止事项
- ❌ `from module import *`
- ❌ 可变默认参数 `def foo(items=[])`
- ❌ 裸 `except:`（必须指定异常类型）
- ❌ `print()` 用于生产代码（用 logging）

## 项目结构（推荐）
```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── main.py
│       └── ...
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   └── test_*.py
├── pyproject.toml
├── .pre-commit-config.yaml
└── AGENTS.md
```
