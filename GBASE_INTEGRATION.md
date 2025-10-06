# SQLBot 集成 GBase 数据库支持实施方案

## GBase 驱动分析总结

经过对 `GBasePython3-9.5.0.1_build4` 驱动的研究，关键发现：

1. **驱动特性**
   - 基于 MySQL Connector 修改，API 兼容 DB API 2.0
   - 模块名：`GBaseConnector`
   - 默认端口：3306（实际 GBase 通常使用 5258）
   - 支持标准的 connect/cursor/execute 接口
   - 参数风格：pyformat（如 `%(param)s`）

2. **连接方式**
```python
import GBaseConnector

conn = GBaseConnector.connect(
    host='gbase_host',
    port=5258,  # GBase 实际端口
    user='username',
    password='password',
    database='dbname',
    charset='utf8mb4'
)
```

## 详细集成步骤

### 1. 安装 GBase 驱动

```bash
# 在 backend 目录下安装驱动
cd backend
python GBasePython3-9.5.0.1_build4/setup.py install

# 或添加到 pyproject.toml 的本地依赖
```

### 2. 后端代码修改

#### 2.1 添加数据库类型定义
文件：`backend/apps/db/constant.py`

```python
# 在 DB 枚举类中添加
gbase = ('gbase', 'GBase', '"', '"', ConnectType.py_driver)
# 注：GBase 8a 使用双引号，GBase 8s 可能使用反引号，需根据版本确定
```

#### 2.2 实现连接逻辑
文件：`backend/apps/db/db.py`

在 `check_connection()` 函数中添加（约 194 行后）：
```python
elif ds.type == 'gbase':
    import GBaseConnector
    with GBaseConnector.connect(
        host=conf.host,
        port=conf.port,
        user=conf.username,
        password=conf.password,
        database=conf.database,
        charset='utf8mb4',
        connect_timeout=10,
        **extra_config_dict
    ) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute('SELECT 1')
                SQLBotLogUtil.info("success")
                return True
            except Exception as e:
                SQLBotLogUtil.error(f"Datasource {ds.id} connection failed: {e}")
                if is_raise:
                    raise HTTPException(status_code=500, detail=trans('i18n_ds_invalid') + f': {e.args}')
                return False
```

在 `get_version()` 函数中添加（约 270 行）：
```python
elif ds.type == 'gbase':
    import GBaseConnector
    with GBaseConnector.connect(
        host=conf.host, port=conf.port,
        user=conf.username, password=conf.password,
        database=conf.database, charset='utf8mb4',
        connect_timeout=10, **extra_config_dict
    ) as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql)
            res = cursor.fetchall()
            version = res[0][0] if res else ''
```

在 `get_schema()` 函数中添加（约 310 行）：
```python
elif ds.type == 'gbase':
    import GBaseConnector
    with GBaseConnector.connect(
        host=conf.host, port=conf.port,
        user=conf.username, password=conf.password,
        database=conf.database, charset='utf8mb4',
        connect_timeout=conf.timeout, **extra_config_dict
    ) as conn:
        with conn.cursor() as cursor:
            # GBase 8a 使用 information_schema
            cursor.execute("SELECT DISTINCT TABLE_SCHEMA FROM information_schema.TABLES")
            res = cursor.fetchall()
            res_list = [item[0] for item in res]
            return res_list
```

在 `get_tables()` 函数中添加（约 360 行）：
```python
elif ds.type == 'gbase':
    import GBaseConnector
    with GBaseConnector.connect(
        host=conf.host, port=conf.port,
        user=conf.username, password=conf.password,
        database=conf.database, charset='utf8mb4',
        connect_timeout=conf.timeout, **extra_config_dict
    ) as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql, {'param': sql_param})
            res = cursor.fetchall()
            res_list = [TableSchema(*item) for item in res]
            return res_list
```

在 `get_fields()` 函数中添加类似的处理。

在 `exec_sql()` 函数中添加（约 420 行）：
```python
elif ds.type == 'gbase':
    import GBaseConnector
    with GBaseConnector.connect(
        host=conf.host, port=conf.port,
        user=conf.username, password=conf.password,
        database=conf.database, charset='utf8mb4',
        connect_timeout=conf.timeout, **extra_config_dict
    ) as conn:
        with conn.cursor() as cursor:
            cursor.execute(sql)
            if cursor.description:
                columns = [{'name': i[0], 'type': str(i[1])} for i in cursor.description]
                res = cursor.fetchall()
            else:
                columns = []
                res = []
```

#### 2.3 添加 SQL 模板
文件：`backend/apps/db/db_sql.py`

```python
# 在 get_version_sql() 函数中添加
elif ds.type == 'gbase':
    return "SELECT VERSION()"

# 在 get_table_sql() 函数中添加
elif ds.type == 'gbase':
    # GBase 8a 兼容 MySQL 语法
    return """
        SELECT
            TABLE_NAME,
            TABLE_COMMENT
        FROM
            information_schema.TABLES
        WHERE
            TABLE_SCHEMA = %(param)s
            AND TABLE_TYPE IN ('BASE TABLE', 'VIEW')
    """, conf.database

# 在 get_field_sql() 函数中添加
elif ds.type == 'gbase':
    sql1 = """
        SELECT
            COLUMN_NAME,
            DATA_TYPE,
            COLUMN_COMMENT
        FROM
            INFORMATION_SCHEMA.COLUMNS
        WHERE
            TABLE_SCHEMA = %(param1)s
    """
    sql2 = " AND TABLE_NAME = %(param2)s" if table_name else ""
    return sql1 + sql2, conf.database, table_name
```

#### 2.4 更新 SQL 生成模板
文件：`backend/template.yaml`

在第 77-79 行的规则中添加：
```yaml
如数据库引擎是 GBase，则根据版本使用相应引号：
- GBase 8a：使用双引号（兼容 Oracle 模式）或反引号（兼容 MySQL 模式）
- GBase 8s：使用双引号
```

在第 109 行的限制条数规则中添加 GBase 的处理：
```yaml
以 GBase 为例，查询前1000条记录：
  - GBase 8a（MySQL 兼容）：SELECT `id` FROM `TEST`.`TABLE` LIMIT 1000
  - GBase 8s（Informix 兼容）：SELECT FIRST 1000 "id" FROM "TEST"."TABLE"
```

### 3. 前端代码修改

#### 3.1 添加数据源类型
文件：`frontend/src/views/ds/js/ds-type.ts`

```typescript
// 导入图标
import gbase from '@/assets/datasource/icon_gbase.png'

// 在 dsType 数组中添加
{ label: 'GBase', value: 'gbase' }

// 在 dsTypeWithImg 数组中添加
{ name: 'GBase', type: 'gbase', img: gbase }

// 如果 GBase 支持 Schema，在 haveSchema 数组中添加
export const haveSchema = ['sqlServer', 'pg', 'oracle', 'dm', 'redshift', 'kingbase', 'gbase']
```

#### 3.2 添加图标文件
将 GBase 图标放置到：`frontend/src/assets/datasource/icon_gbase.png`

### 4. 依赖管理

#### 4.1 更新 Python 依赖
文件：`backend/pyproject.toml`

```toml
[project]
dependencies = [
    # ... 其他依赖
    # 添加 GBase 驱动路径
]

# 或者使用本地包
[tool.uv.sources]
gbase-connector = { path = "./GBasePython3-9.5.0.1_build4" }
```

### 5. Docker 镜像更新

如果使用 Docker 部署，需要在 `Dockerfile` 中添加：

```dockerfile
# 复制 GBase 驱动
COPY GBasePython3-9.5.0.1_build4 /tmp/gbase-driver
RUN cd /tmp/gbase-driver && python setup.py install && rm -rf /tmp/gbase-driver
```

## 测试验证

### 1. 功能测试清单
- [ ] 数据源连接测试
- [ ] 获取 Schema 列表
- [ ] 获取表列表
- [ ] 获取字段信息
- [ ] SQL 执行测试
- [ ] SQL 生成正确性（引号使用）
- [ ] 分页查询支持
- [ ] 数据类型映射

### 2. 测试 SQL 示例

```sql
-- GBase 8a (MySQL 兼容模式)
SELECT `column1`, `column2`
FROM `schema`.`table`
WHERE `id` > 100
LIMIT 1000;

-- GBase 8s (Informix 兼容模式)
SELECT FIRST 1000 "column1", "column2"
FROM "schema"."table"
WHERE "id" > 100;
```

## 注意事项

1. **版本差异**：GBase 有多个版本（8a、8s、8t），语法可能不同
2. **端口配置**：默认端口 5258，但可能因部署而异
3. **字符集**：建议使用 utf8mb4
4. **连接池**：考虑添加连接池支持以提高性能
5. **错误处理**：需要处理 GBase 特有的错误码

## 后续优化

1. 添加 SQLAlchemy 支持（如果 GBase 提供 SQLAlchemy 方言）
2. 优化查询性能，添加 GBase 特定的查询优化
3. 支持 GBase 分布式特性
4. 添加更详细的错误信息映射