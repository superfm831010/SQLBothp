# GBase 测试数据库连接信息

## 数据库连接配置

### 连接参数

```yaml
数据库类型: GBase
主机地址: localhost
端口: 5258
用户名: root
密码: root
数据库名: sqlbot_test_db
字符集: utf8
```

### 在 SQLBot 中配置

1. 登录 SQLBot 前端：http://localhost:5173
   - 用户名：`admin`
   - 密码：`SQLBot@123456`

2. 进入"系统设置" → "数据源管理"

3. 点击"添加数据源"，填写以下信息：
   - **数据源名称**：GBase 学生数据库
   - **数据源类型**：GBase
   - **主机**：localhost
   - **端口**：5258
   - **数据库**：sqlbot_test_db
   - **用户名**：root
   - **密码**：root

4. 点击"校验连接"

5. 连接成功后点击"保存"

---

## 测试数据表结构

### 表名：student_info

**总记录数**：1000 条学生数据

| 字段名 | 数据类型 | 说明 | 示例 |
|--------|---------|------|------|
| student_id | INT | 学号（主键） | 1, 2, 3... |
| student_name | VARCHAR(50) | 姓名 | 王伟, 李娜, 张强 |
| gender | VARCHAR(10) | 性别 | 男, 女 |
| age | INT | 年龄 | 18-24 |
| grade | INT | 年级 | 1, 2, 3, 4 |
| class_name | VARCHAR(20) | 班级 | 1年级1班, 2年级5班 |
| major | VARCHAR(50) | 专业 | 计算机科学与技术, 软件工程 |
| phone | VARCHAR(20) | 电话 | 13812345678 |
| email | VARCHAR(100) | 邮箱 | student0001@university.edu.cn |
| address | VARCHAR(200) | 地址 | 北京市海淀区中山路88号 |
| enrollment_date | DATE | 入学日期 | 2021-09-01 |
| gpa | DECIMAL(3,2) | 绩点 | 2.00 - 4.00 |
| status | VARCHAR(20) | 状态 | 在读, 休学, 交流 |

### 数据统计

- **总人数**：1000 人
- **性别分布**：男女随机分布
- **年级分布**：1-4 年级随机分布
- **专业种类**：20 个专业
  - 计算机类：计算机科学与技术、软件工程、人工智能、数据科学与大数据技术、信息安全、网络工程、物联网工程
  - 工程类：电子信息工程、自动化、机械工程、土木工程、建筑学
  - 商科类：会计学、金融学、市场营销、国际贸易
  - 文科类：英语、汉语言文学、新闻学、法学
- **平均 GPA**：约 3.0
- **平均年龄**：约 20 岁
- **状态分布**：在读 90%，休学 5%，交流 5%

---

## 测试查询示例

### 1. 基础查询

#### 查询所有计算机相关专业的学生
```sql
SELECT student_id, student_name, major, gpa
FROM student_info
WHERE major LIKE '%计算机%'
ORDER BY gpa DESC;
```

#### 查询 GPA 大于 3.5 的优秀学生
```sql
SELECT student_name, gender, major, gpa
FROM student_info
WHERE gpa > 3.5
ORDER BY gpa DESC
LIMIT 50;
```

#### 查询特定年级的学生
```sql
SELECT student_id, student_name, class_name, major
FROM student_info
WHERE grade = 3
ORDER BY student_id;
```

### 2. 统计查询

#### 统计各年级人数
```sql
SELECT grade AS 年级, COUNT(*) AS 人数
FROM student_info
GROUP BY grade
ORDER BY grade;
```

#### 统计各专业平均 GPA
```sql
SELECT major AS 专业,
       COUNT(*) AS 人数,
       AVG(gpa) AS 平均GPA
FROM student_info
GROUP BY major
ORDER BY 平均GPA DESC;
```

#### 统计性别分布
```sql
SELECT gender AS 性别, COUNT(*) AS 人数
FROM student_info
GROUP BY gender;
```

#### 统计各状态学生人数
```sql
SELECT status AS 状态, COUNT(*) AS 人数
FROM student_info
GROUP BY status;
```

### 3. 复杂查询

#### 查询每个专业 GPA 最高的学生
```sql
SELECT s1.major, s1.student_name, s1.gpa
FROM student_info s1
WHERE s1.gpa = (
    SELECT MAX(s2.gpa)
    FROM student_info s2
    WHERE s2.major = s1.major
)
ORDER BY s1.major;
```

#### 查询各年级平均年龄和平均 GPA
```sql
SELECT
    grade AS 年级,
    AVG(age) AS 平均年龄,
    AVG(gpa) AS 平均GPA,
    COUNT(*) AS 人数
FROM student_info
GROUP BY grade
ORDER BY grade;
```

#### 查询年龄大于平均年龄的学生
```sql
SELECT student_name, age, major, gpa
FROM student_info
WHERE age > (SELECT AVG(age) FROM student_info)
ORDER BY age DESC;
```

---

## 自然语言查询测试

在 SQLBot 聊天界面可以尝试以下自然语言查询：

### 简单查询
- "查询所有学生信息"
- "显示所有计算机专业的学生"
- "找出 GPA 最高的 10 个学生"
- "查看 2 年级的所有学生"

### 统计分析
- "统计每个专业的学生人数"
- "计算各年级的平均 GPA"
- "统计男女学生比例"
- "哪个专业的平均 GPA 最高"

### 复杂查询
- "找出每个班级 GPA 最高的学生"
- "统计休学的学生有多少人"
- "查询软件工程专业 GPA 大于 3.0 的学生"
- "比较各年级的平均年龄"

### 数据分析
- "分析各专业的 GPA 分布情况"
- "找出年龄小于 20 岁且 GPA 大于 3.5 的学生"
- "统计北京市的学生有多少"
- "哪些学生的邮箱域名是 university.edu.cn"

---

## 连接测试检查清单

### ✅ 连接校验成功标志
- 后端日志显示：`success`
- 前端提示：连接成功
- HTTP 状态码：200 OK

### ✅ 数据库发现功能
- [ ] 能够看到 `sqlbot_test_db` 数据库
- [ ] 能够看到 `student_info` 表
- [ ] 能够查看表的 13 个字段
- [ ] 字段类型显示正确

### ✅ 查询执行功能
- [ ] 简单 SELECT 查询成功
- [ ] 带 WHERE 条件的查询成功
- [ ] GROUP BY 聚合查询成功
- [ ] JOIN 关联查询成功（如果有多表）
- [ ] 中文数据显示正常

### ✅ 自然语言转 SQL
- [ ] 简单自然语言查询能正确转换
- [ ] 统计类查询能正确转换
- [ ] 复杂条件查询能正确转换
- [ ] 中文查询能正确理解

---

## 故障排查

### 连接失败

#### 1. 检查 GBase 服务状态
```bash
# 检查 Docker 容器是否运行
docker ps | grep gbase

# 如果容器未运行，启动它
docker start gbase8a-dev

# 查看容器日志
docker logs gbase8a-dev
```

#### 2. 检查网络连接
```bash
# 测试端口连通性
telnet localhost 5258

# 或使用 nc
nc -zv localhost 5258
```

#### 3. 验证数据库和表是否存在
```bash
# 进入 GBase 容器
docker exec -it gbase8a-dev bash

# 连接到 GBase
gccli -uroot -proot

# 查看数据库
SHOW DATABASES;

# 使用数据库
USE sqlbot_test_db;

# 查看表
SHOW TABLES;

# 查询记录数
SELECT COUNT(*) FROM student_info;
```

#### 4. 查看 SQLBot 后端日志
```bash
tail -f /projects/SqlBothp/logs/backend.log
```

### 常见错误及解决方案

| 错误信息 | 可能原因 | 解决方法 |
|---------|---------|---------|
| `No module named 'GBaseConnector'` | 驱动未安装 | 已解决（驱动已安装） |
| `Connection refused` | GBase 服务未启动 | 启动 Docker 容器 |
| `Access denied` | 用户名或密码错误 | 确认用户名 `root`，密码 `root` |
| `Database not found` | 数据库未创建 | 运行 `create_gbase_test_data.py` 脚本 |
| `Unread result found` | cursor 未读取结果 | 已修复 |

---

## Python 连接示例

```python
import GBaseConnector

# 连接配置
config = {
    'host': 'localhost',
    'port': 5258,
    'user': 'root',
    'password': 'root',
    'database': 'sqlbot_test_db',
    'charset': 'utf8'
}

# 建立连接
conn = GBaseConnector.connect(**config)
cursor = conn.cursor()

# 执行查询
cursor.execute("SELECT COUNT(*) FROM student_info")
result = cursor.fetchall()
print(f"总学生数: {result[0][0]}")

# 关闭连接
cursor.close()
conn.close()
```

---

## 相关文件

- **测试数据生成脚本**：`create_gbase_test_data.py`
- **连接测试脚本**：`test_gbase_live.py`
- **开发日志**：`GBASE_DEVELOPMENT_LOG.md`
- **驱动安装文档**：`GBASE_CONNECTOR_INSTALLATION.md`
- **集成指南**：`GBASE_INTEGRATION.md`

---

**创建时间**：2025-10-06
**最后更新**：2025-10-06
**状态**：✅ 测试数据已就绪，可用于测试
