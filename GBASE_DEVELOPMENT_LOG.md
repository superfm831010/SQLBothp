# GBase 数据库集成开发日志

## 项目概述
为 SQLBot 系统添加 GBase 数据库支持，实现完整的数据库连接、查询和 SQL 生成功能。

## 开发环境设置

### 1. Git 版本管理
- 配置用户信息：superfm831010@gmail.com
- 创建功能分支：`feature/gbase-support`
- 更新 `.gitignore` 排除开发环境文件

### 2. Python 虚拟环境
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
```

### 3. 安装依赖
- 核心依赖：fastapi, uvicorn, sqlalchemy, sqlmodel, alembic, psycopg2-binary, pymysql, pydantic
- GBase 驱动：GBasePython3-9.5.0.1_build4

## 代码修改详情

### 后端修改

#### 1. backend/apps/db/constant.py
添加 GBase 数据库类型定义：
```python
gbase = ('gbase', 'GBase', '`', '`', ConnectType.py_driver)
```
- 类型标识：gbase
- 显示名称：GBase
- SQL 引号：反引号（兼容 MySQL 语法）
- 连接方式：py_driver（原生驱动）

#### 2. backend/apps/db/db_sql.py
添加三个 SQL 查询模板函数：

**get_version_sql()**
```python
elif ds.type == 'gbase':
    return "SELECT VERSION()"
```

**get_table_sql()**
- 查询 information_schema.TABLES
- 获取表名和表注释
- 使用 %s 参数占位符

**get_field_sql()**
- 查询 INFORMATION_SCHEMA.COLUMNS
- 获取字段名、类型和注释
- 支持按表名过滤

#### 3. backend/apps/db/db.py
实现五个核心函数：

**check_connection()** - 连接测试
- 使用 GBaseConnector.connect()
- 测试 SELECT 1 查询
- 超时时间 10 秒

**get_version()** - 获取版本
- 执行 VERSION() 查询
- 处理字节编码转换

**get_schema()** - 获取 Schema 列表
- 查询 information_schema.TABLES
- 返回去重的 Schema 列表

**get_tables()** - 获取表列表
- 执行参数化查询
- 返回 TableSchema 对象列表

**get_fields()** - 获取字段信息
- 支持单表或全库查询
- 返回 ColumnSchema 对象列表

**exec_sql()** - 执行 SQL
- 执行任意 SQL 查询
- 返回字段定义和数据
- 处理 Decimal 类型转换

#### 4. backend/template.yaml
在 SQL 生成规则中添加 GBase 支持：
- 引号规则：使用反引号（与 MySQL、Doris 相同）
- 示例：`SELECT \`id\` FROM \`TEST\`.\`TABLE\` LIMIT 1000`

### 前端修改

#### frontend/src/views/ds/js/ds-type.ts
1. 导入 GBase 图标
2. 在 dsType 数组中添加：`{ label: 'GBase', value: 'gbase' }`
3. 在 dsTypeWithImg 数组中添加：`{ name: 'GBase', type: 'gbase', img: gbase }`

#### frontend/src/assets/datasource/icon_gbase.png
- 临时使用 MySQL 图标作为占位符
- 创建了 GBASE_ICON_README.md 说明文档

## GBase 驱动特性

### 连接参数
```python
GBaseConnector.connect(
    host='localhost',      # 服务器地址
    port=5258,            # 默认端口（实际可能是 5258）
    user='username',      # 用户名
    password='password',  # 密码
    database='dbname',    # 数据库名
    charset='utf8mb4',    # 字符集
    connect_timeout=10    # 超时时间
)
```

### API 兼容性
- DB API 2.0 兼容
- 参数风格：pyformat（如 `%(param)s` 或 `%s`）
- 基于 MySQL Connector 修改

## 技术细节

### 连接类型选择
使用 `py_driver` 而非 `sqlalchemy`：
- GBase 驱动是原生 Python 驱动
- 提供类似 MySQL Connector 的接口
- 不依赖 SQLAlchemy 方言

### SQL 语法
GBase 8a 兼容 MySQL 语法：
- 使用反引号标识符：\`table\`.\`column\`
- LIMIT 分页：`LIMIT 1000`
- information_schema 系统库

### 异常处理
- 连接超时：10秒
- 错误传播：ParseSQLResultError
- 日志记录：SQLBotLogUtil

## 开发环境脚本

创建了5个便捷脚本：
1. `./dev-start.sh` - 启动所有服务
2. `./dev-stop.sh` - 停止所有服务
3. `./dev-status.sh` - 查看服务状态
4. `./dev-restart.sh` - 重启服务
5. `./dev-logs.sh` - 实时日志查看

## Git 提交记录

### Commit 1: 开发环境设置
```
feat: 添加开发环境管理脚本和 GBase 集成文档
- 创建 dev-*.sh 脚本
- 添加 CLAUDE.md
- 添加 GBASE_INTEGRATION.md
```

### Commit 2: 更新 .gitignore
```
chore: 更新 .gitignore 添加开发环境忽略项
- 排除 backend/.venv/
- 排除 logs/
- 排除 GBase 测试文件
```

### Commit 3: GBase 功能实现
```
feat: 添加 GBase 数据库支持
- 后端：constant.py, db_sql.py, db.py, template.yaml
- 前端：ds-type.ts, icon_gbase.png
- 完整的连接、查询、SQL 生成功能
```

## 测试计划

### 连接测试
- [ ] 测试 GBase 连接成功
- [ ] 测试连接失败处理
- [ ] 测试超时处理

### 功能测试
- [ ] 获取数据库版本
- [ ] 获取 Schema 列表
- [ ] 获取表列表
- [ ] 获取字段信息
- [ ] 执行 SELECT 查询
- [ ] SQL 生成正确性

### 集成测试
- [ ] 前端创建 GBase 数据源
- [ ] LLM SQL 生成测试
- [ ] 图表渲染测试

## 后续优化

1. **图标优化**
   - 替换为 GBase 官方图标
   - 统一图标尺寸和风格

2. **连接池**
   - 实现连接池支持
   - 提高并发性能

3. **错误处理**
   - 添加 GBase 特定错误码映射
   - 改进错误提示信息

4. **Schema 支持**
   - 考虑是否将 GBase 添加到 haveSchema 列表
   - 根据实际 GBase 版本确定

5. **性能优化**
   - 添加查询缓存
   - 优化大表查询

## 相关文档

- CLAUDE.md - 项目开发指南
- GBASE_INTEGRATION.md - 详细集成方案
- GBASE_ICON_README.md - 图标说明

## 开发者备注

- GBase 8a 版本兼容 MySQL 语法
- GBase 8s 版本兼容 Informix 语法（未实现）
- 默认端口可能是 5258，而非 MySQL 的 3306
- 建议在生产环境使用前进行充分测试

## 开发时间线

- 2025-10-06 10:00 - 开始开发
- 2025-10-06 10:20 - 完成环境设置
- 2025-10-06 10:30 - 完成后端实现
- 2025-10-06 10:40 - 完成前端实现
- 2025-10-06 10:45 - 提交代码

总计用时：约 45 分钟