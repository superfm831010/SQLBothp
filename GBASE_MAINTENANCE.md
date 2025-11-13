# GBase 8a 集成维护指南

## 文档目的

本文档记录 GBase 8a 数据库适配在 SQLBot 项目中的所有修改点，用于：
1. 从上游同步更新时的冲突解决参考
2. 新团队成员了解 GBase 集成的技术细节
3. 向上游贡献代码时的变更总结

---

## 上游仓库信息

- **上游仓库**: https://github.com/dataease/SQLBot
- **Fork 仓库**: https://github.com/superfm831010/SQLBothp
- **同步分支**: `main` (保持与上游同步)
- **功能分支**: `feature/gbase-support` (GBase 适配)

---

## GBase 修改文件清单

### 1. 核心数据库操作文件

#### 📄 `backend/apps/db/db.py`

**修改内容**: 添加 GBase 8a 数据库的连接、查询、元数据获取逻辑

**关键修改点**:

##### a) 连接测试 (`check_connection` 函数, 约 208-237 行)

```python
elif ds.type == 'gbase':
    import GBaseConnector
    conn = None
    cursor = None
    try:
        conn = GBaseConnector.connect(
            host=conf.host,
            port=conf.port,
            user=conf.username,
            password=conf.password,
            database=conf.database,
            charset='utf8',  # 注意：必须使用 utf8，不能用 utf8mb4
            connect_timeout=10,
            **extra_config_dict
        )
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.fetchall()  # 必须读取结果才能正确关闭
        SQLBotLogUtil.info("success")
        return True
    except Exception as e:
        SQLBotLogUtil.error(f"Datasource {ds.id} connection failed: {e}")
        if is_raise:
            raise HTTPException(status_code=500, detail=trans('i18n_ds_invalid') + f': {e.args}')
        return False
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
```

**要点**:
- 使用 `GBaseConnector` 而非 PyMySQL
- 字符集必须是 `utf8`（GBase 8a 不支持 `utf8mb4_0900_ai_ci`）
- 资源管理使用 try-finally 确保连接和游标正确关闭
- 必须 `fetchall()` 读取结果才能安全关闭 cursor

##### b) 获取版本 (`get_version` 函数, 约 269-288 行)

```python
elif ds.type == 'gbase':
    import GBaseConnector
    conn = None
    cursor = None
    try:
        conn = GBaseConnector.connect(
            host=conf.host, port=conf.port,
            user=conf.username, password=conf.password,
            database=conf.database, charset='utf8',
            connect_timeout=10, **extra_config_dict
        )
        cursor = conn.cursor()
        cursor.execute(sql)
        res = cursor.fetchall()
        version = res[0][0] if res else ''
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
```

##### c) 获取 Schema 列表 (`get_schema` 函数, 约 319-339 行)

```python
elif ds.type == 'gbase':
    import GBaseConnector
    conn = None
    cursor = None
    try:
        conn = GBaseConnector.connect(
            host=conf.host, port=conf.port,
            user=conf.username, password=conf.password,
            database=conf.database, charset='utf8',
            connect_timeout=conf.timeout, **extra_config_dict
        )
        cursor = conn.cursor()
        cursor.execute("""SELECT DISTINCT TABLE_SCHEMA FROM information_schema.TABLES""")
        res = cursor.fetchall()
        res_list = [item[0] for item in res]
        return res_list
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
```

##### d) 获取表列表 (`get_tables` 函数, 约 365-385 行)

```python
elif ds.type == 'gbase':
    import GBaseConnector
    conn = None
    cursor = None
    try:
        conn = GBaseConnector.connect(
            host=conf.host, port=conf.port,
            user=conf.username, password=conf.password,
            database=conf.database, charset='utf8',
            connect_timeout=conf.timeout, **extra_config_dict
        )
        cursor = conn.cursor()
        cursor.execute(sql, (sql_param,))
        res = cursor.fetchall()
        res_list = [TableSchema(*item) for item in res]
        return res_list
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
```

##### e) 获取字段列表 (`get_fields` 函数, 约 415-438 行)

```python
elif ds.type == 'gbase':
    import GBaseConnector
    conn = None
    cursor = None
    try:
        conn = GBaseConnector.connect(
            host=conf.host, port=conf.port,
            user=conf.username, password=conf.password,
            database=conf.database, charset='utf8',
            connect_timeout=conf.timeout, **extra_config_dict
        )
        cursor = conn.cursor()
        if p2:
            cursor.execute(sql, (p1, p2))
        else:
            cursor.execute(sql, (p1,))
        res = cursor.fetchall()
        res_list = [ColumnSchema(*item) for item in res]
        return res_list
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
```

##### f) 执行 SQL (`exec_sql` 函数, 约 520-552 行)

```python
elif ds.type == 'gbase':
    import GBaseConnector
    conn = None
    cursor = None
    try:
        conn = GBaseConnector.connect(
            host=conf.host, port=conf.port,
            user=conf.username, password=conf.password,
            database=conf.database, charset='utf8',
            connect_timeout=conf.timeout, **extra_config_dict
        )
        cursor = conn.cursor()
        try:
            cursor.execute(sql)
            res = cursor.fetchall()
            if cursor.description:
                columns = [field[0] for field in cursor.description] if origin_column else [field[0].lower() for field in cursor.description]
                result_list = [
                    {str(columns[i]): float(value) if isinstance(value, Decimal) else value for i, value in enumerate(tuple_item)}
                    for tuple_item in res
                ]
                return {"fields": columns, "data": result_list,
                        "sql": bytes.decode(base64.b64encode(bytes(sql, 'utf-8')))}
            else:
                return {"fields": [], "data": [],
                        "sql": bytes.decode(base64.b64encode(bytes(sql, 'utf-8')))}
        except Exception as ex:
            raise ParseSQLResultError(str(ex))
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
```

**冲突解决策略**:
- 如果上游修改了其他数据库类型的逻辑，保留 GBase 的代码块
- 如果上游添加了新的错误处理，同步到 GBase 代码块
- 如果上游修改了返回格式，确保 GBase 也使用相同格式

---

### 2. 数据源 CRUD 操作文件

#### 📄 `backend/apps/datasource/crud/datasource.py`

**修改内容**: 添加 GBase 的数据预览 SQL 生成逻辑

**关键修改点** (约 303-306 行):

```python
elif ds.type == "gbase":
    sql = f"""SELECT `{"`, `".join(fields)}` FROM `{data.table.table_name}`
        {where}
        LIMIT 100"""
```

**要点**:
- GBase 使用反引号 `` ` `` 包裹字段名和表名（类似 MySQL）
- 与 PostgreSQL/Elasticsearch 的双引号 `"` 不同

**冲突解决策略**:
- 如果上游修改了 SQL 生成逻辑（如 LIMIT、WHERE），同步修改
- 保持反引号的使用风格

---

### 3. 数据库配置文件

#### 📄 `backend/apps/db/base.py`

**修改内容**: 注册 GBase 数据库类型

**关键修改点** (约添加在数据库类型列表中):

```python
gbase = Database(
    name='gbase',
    icon='gbase',
    connect_type=ConnectType.driver,
    version_sql="SELECT VERSION()",
    table_sql="""
        SELECT TABLE_NAME as name, TABLE_COMMENT as comment
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = %s
    """,
    field_sql="""
        SELECT COLUMN_NAME as name, COLUMN_TYPE as type, COLUMN_COMMENT as comment
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
        ORDER BY ORDINAL_POSITION
    """
)
```

**注意**: 这个文件可能需要根据实际代码结构调整。

---

### 4. 前端数据源类型配置

#### 📄 `frontend/src/views/system/datasource/config.ts` (如果存在)

**修改内容**: 添加 GBase 数据源选项

```typescript
{
  type: 'gbase',
  name: 'GBase 8a',
  icon: 'gbase',
  defaultPort: 5258
}
```

---

### 5. 依赖配置文件

#### 📄 `backend/pyproject.toml`

**修改内容**: 添加 GBase 驱动依赖

**关键修改点** (dependencies 数组中):

```toml
"gbase-connector-python @ file:///projects/SqlBothp/GBasePython3-9.5.0.1_build4",
```

**要点**:
- 使用本地 wheel 包安装（因为 GBase 驱动不在 PyPI）
- 路径需要根据实际部署环境调整

**冲突解决策略**:
- 如果上游添加新依赖，保留 GBase 驱动
- 如果上游修改 Python 版本要求，确认 GBase 驱动兼容性

---

### 6. 启动脚本

#### 📄 `dev-start.sh`

**修改内容**:
1. 使用 `pgvector/pgvector:pg13` 镜像（支持向量扩展）
2. 使用 `uv` 包管理器
3. 使用 Python 3.11

**关键修改**:
- PostgreSQL 镜像改为 `pgvector/pgvector:pg13`
- 添加 Python 3.11 检查
- 添加 uv 工具检查和自动安装
- 使用 `uv sync --extra cpu` 安装依赖

---

### 7. 前端配置

#### 📄 `frontend/vite.config.ts`

**修改内容**: 添加 server 配置监听所有网络接口

```typescript
server: {
  host: '0.0.0.0',
  port: 5173,
},
```

---

### 8. 白名单配置

#### 📄 `backend/common/utils/whitelist.py`

**修改内容**: 添加 `/auth/*` 路径到白名单

```python
wlist = [
    "/",
    "/docs",
    "/login/*",
    "/auth/*",  # 新增
    "/system/init",
    # ...
]
```

---

## GBase 特性和限制

### 字符集问题

**问题**: GBase 8a 不支持 MySQL 8.0 的 `utf8mb4_0900_ai_ci` collation

**解决方案**: 所有连接使用 `charset='utf8'`

### SQL 方言差异

1. **标识符引用**: 使用反引号 `` `table_name` ``
2. **分页**: 支持 `LIMIT` 语法
3. **元数据查询**: 支持 `information_schema`

### 已知语法限制

GBase 8a 虽然兼容 MySQL 大部分语法，但**不支持**以下 MySQL 扩展功能：

#### ❌ 不支持的聚合扩展语法

1. **WITH ROLLUP** - 分组汇总语法
   ```sql
   -- ❌ 错误：GBase 8a 不支持
   SELECT category, SUM(amount)
   FROM sales
   GROUP BY category WITH ROLLUP;
   ```

2. **WITH CUBE** - 多维汇总语法
   ```sql
   -- ❌ 错误：GBase 8a 不支持
   SELECT region, product, SUM(sales)
   FROM orders
   GROUP BY region, product WITH CUBE;
   ```

#### ✅ 替代方案：使用 UNION ALL

当需要实现小计或总计功能时，应使用 `UNION ALL` 合并多个独立的 `GROUP BY` 查询：

**示例 1：单列分组 + 总计**
```sql
-- ✅ 正确：使用 UNION ALL 实现总计
SELECT `category` AS `category_name`, SUM(`amount`) AS `total_amount`
FROM `sales` `t1`
GROUP BY `category`

UNION ALL

SELECT '总计' AS `category_name`, SUM(`amount`) AS `total_amount`
FROM `sales` `t2`;
```

**示例 2：多列分组 + 多级汇总**
```sql
-- ✅ 正确：使用 UNION ALL 实现分类小计和总计
-- 明细行
SELECT `region` AS `region_name`, `category` AS `category_name`, SUM(`amount`) AS `total`
FROM `sales` `t1`
GROUP BY `region`, `category`

UNION ALL

-- 地区小计
SELECT `region` AS `region_name`, '小计' AS `category_name`, SUM(`amount`) AS `total`
FROM `sales` `t2`
GROUP BY `region`

UNION ALL

-- 总计
SELECT '总计' AS `region_name`, '总计' AS `category_name`, SUM(`amount`) AS `total`
FROM `sales` `t3`;
```

#### 🛡️ 系统保护机制

SQLBot 已实现**双重保护**防止不支持的语法执行：

1. **模板层限制** (`backend/templates/sql_examples/GBase.yaml`)
   - LLM 生成 SQL 时会遵循 GBase 模板中的明确规则
   - 规则禁止使用 `WITH ROLLUP`、`WITH CUBE` 等语法
   - 提示使用 `UNION ALL` 替代方案

2. **执行层检查** (`backend/apps/db/db.py:758-770`)
   - SQL 执行前进行语法检查
   - 检测到不支持的语法会立即拒绝执行
   - 返回友好的错误提示和替代建议

**错误提示示例**:
```
GBase 8a 不支持 WITH ROLLUP（汇总语法）。
建议：使用 UNION ALL 合并多个独立的 GROUP BY 查询来实现小计/总计功能。
示例：SELECT ... GROUP BY col1, col2 UNION ALL SELECT '总计', ... GROUP BY col1
```

#### 📋 其他语法注意事项

- ✅ 支持标准 `GROUP BY`、`ORDER BY`、`HAVING`
- ✅ 支持 `UNION`、`UNION ALL`
- ✅ 支持子查询和 JOIN
- ✅ 支持窗口函数（需确认版本）
- ⚠️ 对于复杂的统计需求，建议拆分为多个简单查询后用 UNION 合并

### 驱动特点

- **驱动包**: `gbase-connector-python`
- **API**: 类似 MySQL Connector/Python
- **资源管理**: 必须显式关闭 cursor 和 connection
- **结果集**: 必须 `fetchall()` 才能安全关闭

---

## 合并冲突解决清单

当从上游同步更新出现冲突时，按以下清单检查：

### ✅ 检查清单

- [ ] `backend/apps/db/db.py` - 保留所有 `elif ds.type == 'gbase':` 代码块
- [ ] `backend/apps/datasource/crud/datasource.py` - 保留 GBase SQL 生成逻辑
- [ ] `backend/pyproject.toml` - 保留 `gbase-connector-python` 依赖
- [ ] `backend/apps/db/base.py` - 保留 GBase 数据库注册
- [ ] 新增文件 - 评估是否需要添加 GBase 支持
- [ ] 测试运行 - 确保 GBase 连接和查询正常

### 🔍 冲突解决步骤

1. **分析冲突文件**
   ```bash
   git diff --name-only --diff-filter=U
   ```

2. **对于 `db.py` 文件**
   - 优先采用上游的代码结构改进
   - 确保 GBase 代码块位置正确
   - 检查所有 6 处 GBase 代码块都已保留

3. **对于依赖文件**
   - 合并上游新增的依赖
   - 保留 GBase 驱动依赖

4. **解决后测试**
   ```bash
   cd backend
   uv sync --extra cpu
   python test_gbase_connection.py
   ```

---

## 测试检查清单

每次同步更新后，执行以下测试：

### 基础连接测试

```bash
cd /projects/SqlBothp
python test_gbase_connection.py
```

### 完整功能测试

```bash
cd /projects/SqlBothp
python test_gbase_live.py
```

### Web 界面测试

1. 启动服务
   ```bash
   ./dev-start.sh
   ```

2. 在浏览器打开 http://localhost:5173

3. 测试以下功能：
   - [ ] 添加 GBase 数据源
   - [ ] 连接测试
   - [ ] 查看数据库列表
   - [ ] 查看表列表
   - [ ] 查看字段列表
   - [ ] 数据预览
   - [ ] 执行自定义 SQL
   - [ ] LLM 生成 SQL
   - [ ] 数据可视化

---

## 向上游贡献

如果 GBase 支持已经成熟，可以考虑贡献回上游：

### 准备工作

1. **创建贡献分支**
   ```bash
   git checkout -b contrib/add-gbase-support upstream/main
   ```

2. **Cherry-pick GBase 相关提交**
   ```bash
   git cherry-pick 35a0226  # feat: 添加 GBase 数据库支持
   git cherry-pick 58c3789  # fix: 修复 GBase 连接器资源管理问题
   ```

3. **准备 PR 说明**
   - 说明 GBase 8a 的市场定位和用户需求
   - 列出已测试的功能点
   - 提供测试数据和环境搭建指南
   - 附上 GBase 驱动的获取方式

### PR 模板

```markdown
## 功能描述

添加南大通用 GBase 8a 数据库支持

## 变更内容

- 添加 GBase 连接器集成
- 实现 GBase 元数据查询（schema/table/field）
- 实现 GBase SQL 执行
- 添加 GBase 测试脚本和文档

## 测试情况

- [x] 连接测试
- [x] 元数据查询
- [x] SQL 执行
- [x] 数据预览
- [x] LLM SQL 生成

## 部署说明

GBase 驱动需要手动安装：
\`\`\`bash
pip install /path/to/GBasePython3-9.5.0.1_build4.whl
\`\`\`

驱动下载地址：[GBase 官网](https://www.gbase8.cn)
```

---

## 维护计划

### 定期任务（每月）

1. 检查上游更新
   ```bash
   ./sync-upstream.sh
   ```

2. 运行完整测试套件

3. 更新本文档（如有新的修改点）

### 长期规划

- [ ] 将 GBase 支持模块化（降低耦合）
- [ ] 添加 GBase 性能优化
- [ ] 支持 GBase 特有功能（如集群、分布式）
- [ ] 完善 GBase 错误处理和日志

---

## 联系方式

- **维护者**: superfm831010
- **项目**: https://github.com/superfm831010/SQLBothp
- **问题反馈**: GitHub Issues

---

## 变更历史

| 日期       | 版本 | 说明                           |
|------------|------|--------------------------------|
| 2025-10-06 | 1.0  | 初始版本，记录 GBase 集成要点 |

---

**注意**: 本文档随代码演进持续更新。如发现遗漏或错误，请及时补充。
