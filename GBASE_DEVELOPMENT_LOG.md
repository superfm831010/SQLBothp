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

---

## GBase 8a 个人版 Docker 安装记录

### 安装日期
2025-10-06

### 环境信息
- 操作系统: Ubuntu 22.04.5 LTS (x86_64)
- Docker 版本: 28.4.0
- 可用磁盘空间: 70GB

### 安装步骤

#### 1. 拉取 Docker 镜像
```bash
docker pull shihd/gbase8a:1.0
```

镜像信息:
- 镜像: shihd/gbase8a:1.0
- SHA256: sha256:3153223ce9039748d7d4400a39768c4a9ce6df39576cd34638ac58a0679a6b17
- 大小: 约 300MB (6层)

#### 2. 启动容器
```bash
docker run -d \
  --name gbase8a-dev \
  --hostname gbase8a \
  --privileged=true \
  -p 5258:5258 \
  shihd/gbase8a:1.0
```

容器信息:
- 容器名: gbase8a-dev
- 容器ID: 009c55fa5c39
- 端口映射: 5258:5258
- 状态: 运行中

#### 3. 验证服务状态
```bash
docker ps | grep gbase8a
docker logs gbase8a-dev
```

服务日志显示:
```
Starting GBase. SUCCESS!
Express is ready for connections.
socket: '/tmp/gbase_8a_5258.sock' port: 5258
```

### GBase 版本信息
- **版本**: 8.6.2.43-R7-free.110605
- **类型**: Free Edition (免费版)
- **限制**: 最多4节点集群, 每节点500GB存储

### 字符集兼容性问题

#### 问题
GBase 8a 不支持 `utf8mb4_0900_ai_ci` collation (MySQL 8.0 新特性)

#### 解决方案
将所有 GBase 连接的字符集从 `utf8mb4` 改为 `utf8`

修改文件: `backend/apps/db/db.py`
- 共修改 6 处 GBase 连接代码
- 函数: check_connection, get_version, get_schema, get_tables, get_fields, exec_sql

修改内容:
```python
# 修改前
charset='utf8mb4'

# 修改后
charset='utf8'
```

### 测试数据生成

#### 测试数据库配置
- **数据库名**: sqlbot_test_db
- **表名**: student_info
- **记录数**: 1000 条
- **数据类型**: 学生基本信息

#### 表结构
```sql
CREATE TABLE student_info (
    student_id INT PRIMARY KEY,           -- 学号(主键)
    student_name VARCHAR(50) NOT NULL,    -- 姓名
    gender VARCHAR(10) NOT NULL,          -- 性别
    age INT NOT NULL,                     -- 年龄
    grade INT NOT NULL,                   -- 年级(1-4)
    class_name VARCHAR(20) NOT NULL,      -- 班级
    major VARCHAR(50) NOT NULL,           -- 专业
    phone VARCHAR(20),                    -- 电话
    email VARCHAR(100),                   -- 邮箱
    address VARCHAR(200),                 -- 地址
    enrollment_date DATE,                 -- 入学日期
    gpa DECIMAL(3, 2),                    -- 绩点(0.00-4.00)
    status VARCHAR(20) DEFAULT '在读'      -- 状态(在读/休学/交流)
)
```

#### 数据统计
- 性别分布: 男生 486 人, 女生 514 人
- 年级分布: 1年级 270人, 2年级 251人, 3年级 247人, 4年级 232人
- 平均GPA: 2.97
- 平均年龄: 20.4 岁
- 专业种类: 20 个不同专业
- 状态: 在读 90%, 休学 5%, 交流 5%

#### 数据特点
- 真实的中文姓名(基于常见姓氏和名字)
- 合理的年龄和年级分布
- 多样化的专业分布(包括计算机、工程、商科、文科等)
- 随机生成的手机号、邮箱、地址
- 符合实际的GPA分布(2.0-4.0)

### 连接信息

#### GBase 数据库连接参数
```yaml
主机: localhost
端口: 5258
用户名: root
密码: root
字符集: utf8
数据库: sqlbot_test_db
表名: student_info
```

#### Python 连接示例
```python
import GBaseConnector

conn = GBaseConnector.connect(
    host='localhost',
    port=5258,
    user='root',
    password='root',
    database='sqlbot_test_db',
    charset='utf8'
)
```

### 测试查询示例

#### 1. 基本查询
```sql
-- 查询所有计算机相关专业的学生
SELECT * FROM student_info
WHERE major LIKE '%计算机%';

-- 查询GPA大于3.5的优秀学生
SELECT student_name, major, gpa
FROM student_info
WHERE gpa > 3.5
ORDER BY gpa DESC;
```

#### 2. 统计查询
```sql
-- 统计各年级人数
SELECT grade, COUNT(*) as count
FROM student_info
GROUP BY grade;

-- 统计各专业平均GPA
SELECT major, AVG(gpa) as avg_gpa
FROM student_info
GROUP BY major
ORDER BY avg_gpa DESC;

-- 统计性别分布
SELECT gender, COUNT(*)
FROM student_info
GROUP BY gender;
```

#### 3. 复杂查询
```sql
-- 查询每个专业GPA最高的学生
SELECT s1.major, s1.student_name, s1.gpa
FROM student_info s1
WHERE s1.gpa = (
    SELECT MAX(s2.gpa)
    FROM student_info s2
    WHERE s2.major = s1.major
);

-- 查询各年级平均年龄和平均GPA
SELECT
    grade,
    AVG(age) as avg_age,
    AVG(gpa) as avg_gpa,
    COUNT(*) as total
FROM student_info
GROUP BY grade
ORDER BY grade;
```

### 容器管理命令

```bash
# 启动容器
docker start gbase8a-dev

# 停止容器
docker stop gbase8a-dev

# 重启容器
docker restart gbase8a-dev

# 查看日志
docker logs -f gbase8a-dev

# 进入容器
docker exec -it gbase8a-dev /bin/bash

# 删除容器
docker stop gbase8a-dev
docker rm gbase8a-dev

# 删除镜像
docker rmi shihd/gbase8a:1.0
```

### 测试脚本

#### 1. 基础连接测试
文件: `test_gbase_live.py`
- 测试基本连接
- 创建测试数据库和表
- 插入和查询数据
- 验证数据完整性

#### 2. 完整测试数据生成
文件: `create_gbase_test_data.py`
- 生成 1000 条学生记录
- 包含 13 个字段
- 数据分布合理
- 支持各种查询场景

### 验证结果

✅ Docker 镜像拉取成功
✅ 容器启动成功
✅ GBase 服务运行正常
✅ Python 驱动连接成功
✅ 字符集问题已解决
✅ 测试数据创建成功(1000条)
✅ 数据查询正常
✅ 统计功能正常

### 下一步

- [ ] 在 SQLBot 前端界面配置 GBase 数据源
- [ ] 测试 SQLBot 后端 API 连接
- [ ] 测试 LLM SQL 生成功能
- [ ] 测试数据可视化功能
- [ ] 性能测试

### 注意事项

1. **字符集**: 必须使用 `utf8`, 不能使用 `utf8mb4`
2. **端口**: GBase 默认端口是 5258, 不是 MySQL 的 3306
3. **Docker 镜像**: 使用社区版镜像 shihd/gbase8a:1.0
4. **数据持久化**: 容器删除后数据会丢失, 生产环境需要配置 volume
5. **内存要求**: 建议至少 2GB 可用内存

### 相关文件

- `test_gbase_connection.py` - GBase 驱动测试脚本
- `test_gbase_live.py` - 基础连接和数据测试
- `create_gbase_test_data.py` - 1000条测试数据生成脚本
- `backend/apps/db/db.py` - GBase 集成代码(已修改字符集)

---

## 总结

GBase 8a 个人版已通过 Docker 成功部署, Python 驱动连接正常, 测试数据完备。
系统已准备好进行 SQLBot 集成测试。