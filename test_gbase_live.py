#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
测试 GBase 8a 实际连接和数据操作
"""

import sys
import os

# 将 GBase 驱动添加到 Python 路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'GBasePython3-9.5.0.1_build4'))

try:
    import GBaseConnector

    print("=" * 60)
    print("GBase 8a 连接测试")
    print("=" * 60)

    # 连接配置
    config = {
        'host': 'localhost',
        'port': 5258,
        'user': 'root',
        'password': 'root',
        'charset': 'utf8'
    }

    print(f"\n连接配置:")
    print(f"  Host: {config['host']}")
    print(f"  Port: {config['port']}")
    print(f"  User: {config['user']}")

    # 1. 测试基本连接
    print("\n[1] 测试基本连接...")
    conn = GBaseConnector.connect(**config)
    cursor = conn.cursor()
    print("✅ 连接成功!")

    # 2. 获取版本信息
    print("\n[2] 获取GBase版本...")
    cursor.execute("SELECT VERSION()")
    version = cursor.fetchone()
    print(f"✅ GBase版本: {version[0]}")

    # 3. 创建测试数据库
    print("\n[3] 创建测试数据库 test_db...")
    try:
        cursor.execute("CREATE DATABASE IF NOT EXISTS test_db")
        print("✅ 数据库创建成功")
    except Exception as e:
        print(f"⚠️  数据库可能已存在: {e}")

    # 4. 切换到测试数据库
    print("\n[4] 切换到 test_db...")
    cursor.execute("USE test_db")
    print("✅ 成功切换数据库")

    # 5. 创建测试表
    print("\n[5] 创建测试表 users...")
    cursor.execute("DROP TABLE IF EXISTS users")
    cursor.execute("""
        CREATE TABLE users (
            id INT PRIMARY KEY,
            name VARCHAR(100),
            age INT,
            email VARCHAR(200)
        )
    """)
    print("✅ 表创建成功")

    # 6. 插入测试数据
    print("\n[6] 插入测试数据...")
    test_data = [
        (1, '张三', 25, 'zhangsan@example.com'),
        (2, '李四', 30, 'lisi@example.com'),
        (3, '王五', 28, 'wangwu@example.com'),
        (4, 'Alice', 22, 'alice@example.com'),
        (5, 'Bob', 35, 'bob@example.com')
    ]

    for row in test_data:
        cursor.execute(
            "INSERT INTO users (id, name, age, email) VALUES (%s, %s, %s, %s)",
            row
        )
    print(f"✅ 成功插入 {len(test_data)} 条记录")

    # 7. 查询数据验证
    print("\n[7] 查询数据验证...")
    cursor.execute("SELECT * FROM users ORDER BY id")
    results = cursor.fetchall()
    print(f"✅ 查询到 {len(results)} 条记录:")
    print("\n  ID | Name  | Age | Email")
    print("  " + "-" * 50)
    for row in results:
        print(f"  {row[0]:2d} | {row[1]:5s} | {row[2]:3d} | {row[3]}")

    # 8. 测试查询统计
    print("\n[8] 测试聚合查询...")
    cursor.execute("SELECT COUNT(*) as total, AVG(age) as avg_age FROM users")
    result = cursor.fetchone()
    print(f"✅ 总记录数: {result[0]}, 平均年龄: {result[1]:.1f}")

    # 9. 查看表结构
    print("\n[9] 查看表结构...")
    cursor.execute("SHOW TABLES")
    tables = cursor.fetchall()
    print(f"✅ test_db 中的表: {[t[0] for t in tables]}")

    # 10. 获取字段信息
    print("\n[10] 获取字段信息...")
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, COLUMN_COMMENT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'test_db' AND TABLE_NAME = 'users'
        ORDER BY ORDINAL_POSITION
    """)
    columns = cursor.fetchall()
    print("✅ users 表字段:")
    for col in columns:
        print(f"  - {col[0]} ({col[1]})")

    # 关闭连接
    cursor.close()
    conn.close()

    print("\n" + "=" * 60)
    print("✅ 所有测试通过!")
    print("=" * 60)
    print("\nGBase 8a 数据库已准备就绪,可以在 SQLBot 中配置数据源:")
    print("  - 类型: GBase")
    print("  - 主机: localhost")
    print("  - 端口: 5258")
    print("  - 用户名: root")
    print("  - 密码: root")
    print("  - 数据库: test_db")
    print("=" * 60)

except Exception as e:
    print(f"\n❌ 错误: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
