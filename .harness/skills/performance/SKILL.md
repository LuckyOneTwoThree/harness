---
name: performance
description: 接口变慢、内存泄漏、CPU 飙高等性能问题时使用。系统性排查性能瓶颈。
---

# 性能排查 (Performance Investigation)

> 来源：综合 Superpowers systematic-debugging 的四阶段流程 + 性能工程最佳实践
> 与 debug skill 的区别：debug 处理功能 Bug，performance 处理性能问题

## 核心原则

```
先量化，再优化。没有数据支撑的优化是盲猜。
```

## 排查流程

### 阶段 1：量化问题

**在尝试任何优化之前，先回答：**

1. **慢在哪？** — 整个请求慢，还是某个阶段慢？
2. **慢多少？** — P50/P95/P99 延迟分别是多少？
3. **什么时候开始慢的？** — 最近有什么变更？
4. **是持续慢还是偶发慢？** — 能稳定复现吗？

**常用命令：**

```bash
# 接口延迟（如有监控系统，先看监控）
curl -o /dev/null -s -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" http://localhost:8000/api/endpoint

# 数据库慢查询（MySQL）
SHOW PROCESSLIST;
SHOW VARIABLES LIKE 'slow_query_log%';
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

# 数据库慢查询（PostgreSQL）
SELECT query, calls, mean_exec_time, total_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;

# 进程资源
top -bn1 | head -20
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
```

### 阶段 2：定位瓶颈层

**系统通常分这几层，逐层排查：**

```
客户端 → 网络 → Web 服务器 → 应用代码 → 数据库 → 外部服务
```

| 层 | 排查方法 | 常见问题 |
|----|----------|----------|
| **网络** | `ping`、`traceroute`、`curl -w` | DNS 慢、连接超时、带宽不足 |
| **Web 服务器** | 访问日志、连接数 | 连接池耗尽、队列积压 |
| **应用代码** | Profiling、日志埋点 | N+1 查询、循环内 IO、内存泄漏 |
| **数据库** | EXPLAIN、慢查询日志 | 缺索引、全表扫描、锁等待 |
| **外部服务** | 调用日志、超时配置 | 第三方接口慢、无超时设置 |

### 阶段 3：深入分析

#### 应用代码 Profiling

```bash
# Python - cProfile
python -m cProfile -s cumulative your_script.py | head -30

# Python - py-spy（生产环境采样）
py-spy top --pid <PID>

# Node.js --inspect
node --inspect your_script.js
# 然后打开 chrome://inspect

# Go - pprof
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Java - async-profiler
java -agentpath:libasyncProfiler.so=start,file=profile.html -jar app.jar
```

#### 数据库 EXPLAIN

```sql
-- MySQL
EXPLAIN ANALYZE SELECT ...;

-- PostgreSQL
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
```

**看什么：**
- `type: ALL` → 全表扫描，需要加索引
- `rows` 值很大 → 扫描行数多，优化查询条件
- `Using filesort` → 需要优化 ORDER BY
- `Using temporary` → 需要优化 GROUP BY

#### 内存分析

```bash
# Python - tracemalloc
python -c "
import tracemalloc
tracemalloc.start()
# ... 你的代码 ...
snapshot = tracemalloc.take_snapshot()
for stat in snapshot.statistics('lineno')[:10]:
    print(stat)
"

# Node.js --heap-prof
node --heap-prof your_script.js

# Go - pprof heap
go tool pprof http://localhost:6060/debug/pprof/heap
```

### 阶段 4：优化验证

**优化后必须验证：**

1. **量化对比** — 优化前后的延迟/吞吐量/资源占用
2. **功能回归** — 确保优化没有破坏功能（运行全量测试）
3. **压力测试** — 用工具模拟并发验证效果

```bash
# 简单压力测试
# Apache Bench
ab -n 1000 -c 50 http://localhost:8000/api/endpoint

# wrk
wrk -t4 -c100 -d30s http://localhost:8000/api/endpoint
```

## 常见性能问题速查

| 症状 | 可能原因 | 排查方向 |
|------|----------|----------|
| 接口延迟高 | N+1 查询、缺索引、循环内 IO | EXPLAIN + 代码审查 |
| CPU 飙高 | 死循环、正则回退、密集计算 | Profiling |
| 内存持续增长 | 内存泄漏、缓存无上限、大对象未释放 | 内存快照对比 |
| 响应时间不稳定 | GC 停顿、锁竞争、资源争抢 | GC 日志、线程 dump |
| 数据库连接耗尽 | 连接池配置不当、连接未释放 | 连接池监控 |
| 偶发超时 | 第三方服务不稳定、网络抖动 | 调用链追踪 |

## 红旗

- **不要在没有数据的情况下优化。** 先 profile，再优化。
- **不要一次改多个变量。** 每次只改一个，量化效果。
- **不要忽略回归测试。** 优化可能引入新 Bug。
- **不要只看平均值。** P99 延迟才是用户体验的真实反映。
