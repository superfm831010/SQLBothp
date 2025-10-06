#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
为 GBase 8a 创建包含1000条学生数据的测试表
"""

import sys
import os
import random
from datetime import datetime, timedelta

# 将 GBase 驱动添加到 Python 路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'GBasePython3-9.5.0.1_build4'))

try:
    import GBaseConnector

    print("=" * 70)
    print("GBase 8a 测试数据生成脚本")
    print("=" * 70)

    # 连接配置
    config = {
        'host': 'localhost',
        'port': 5258,
        'user': 'root',
        'password': 'root',
        'charset': 'utf8'
    }

    # 连接到GBase
    print("\n[1] 连接到GBase数据库...")
    conn = GBaseConnector.connect(**config)
    cursor = conn.cursor()
    print("✅ 连接成功!")

    # 创建数据库
    print("\n[2] 创建数据库 sqlbot_test_db...")
    cursor.execute("DROP DATABASE IF EXISTS sqlbot_test_db")
    cursor.execute("CREATE DATABASE sqlbot_test_db")
    cursor.execute("USE sqlbot_test_db")
    print("✅ 数据库创建成功")

    # 创建学生表
    print("\n[3] 创建学生信息表 student_info...")
    cursor.execute("""
        CREATE TABLE student_info (
            student_id INT PRIMARY KEY,
            student_name VARCHAR(50) NOT NULL,
            gender VARCHAR(10) NOT NULL,
            age INT NOT NULL,
            grade INT NOT NULL,
            class_name VARCHAR(20) NOT NULL,
            major VARCHAR(50) NOT NULL,
            phone VARCHAR(20),
            email VARCHAR(100),
            address VARCHAR(200),
            enrollment_date DATE,
            gpa DECIMAL(3, 2),
            status VARCHAR(20) DEFAULT '在读'
        )
    """)
    print("✅ 表创建成功")

    # 准备测试数据
    print("\n[4] 生成1000条学生测试数据...")

    # 姓氏和名字库
    surnames = ['王', '李', '张', '刘', '陈', '杨', '黄', '赵', '吴', '周',
                '徐', '孙', '马', '朱', '胡', '郭', '何', '林', '高', '罗',
                '郑', '梁', '谢', '宋', '唐', '许', '韩', '冯', '邓', '曹']
    given_names_male = ['伟', '强', '磊', '军', '洋', '勇', '杰', '涛', '明', '超',
                        '鹏', '辉', '刚', '峰', '斌', '龙', '华', '宇', '亮', '浩']
    given_names_female = ['芳', '娜', '秀英', '敏', '静', '丽', '强', '洁', '莉', '艳',
                          '红', '玲', '梅', '霞', '燕', '欣', '雪', '慧', '琳', '婷']

    # 专业列表
    majors = ['计算机科学与技术', '软件工程', '人工智能', '数据科学与大数据技术',
              '信息安全', '网络工程', '物联网工程', '电子信息工程', '自动化',
              '机械工程', '土木工程', '建筑学', '会计学', '金融学', '市场营销',
              '国际贸易', '英语', '汉语言文学', '新闻学', '法学']

    # 城市列表
    cities = ['北京市', '上海市', '广州市', '深圳市', '成都市', '杭州市', '武汉市',
              '西安市', '重庆市', '南京市', '天津市', '苏州市', '长沙市', '郑州市',
              '青岛市', '济南市', '大连市', '厦门市', '宁波市', '福州市']

    districts = ['海淀区', '朝阳区', '西城区', '东城区', '丰台区', '浦东新区',
                 '徐汇区', '黄浦区', '天河区', '番禺区', '南山区', '福田区']

    streets = ['中山路', '人民路', '建设路', '解放路', '和平路', '新华路',
               '光明路', '胜利路', '文化路', '幸福路']

    # 生成数据
    students = []
    base_date = datetime(2020, 9, 1)

    for i in range(1, 1001):
        # 随机性别
        gender = random.choice(['男', '女'])

        # 生成姓名
        surname = random.choice(surnames)
        if gender == '男':
            given_name = random.choice(given_names_male)
        else:
            given_name = random.choice(given_names_female)
        name = surname + given_name

        # 年龄和年级
        grade = random.randint(1, 4)  # 1-4年级
        age = 18 + grade - 1 + random.randint(0, 2)  # 18-24岁

        # 班级
        class_num = random.randint(1, 10)
        class_name = f"{grade}年级{class_num}班"

        # 专业
        major = random.choice(majors)

        # 电话号码
        phone = f"1{random.choice(['3', '5', '7', '8'])}{random.randint(100000000, 999999999)}"

        # 邮箱
        email = f"student{i:04d}@university.edu.cn"

        # 地址
        city = random.choice(cities)
        district = random.choice(districts)
        street = random.choice(streets)
        building = random.randint(1, 200)
        address = f"{city}{district}{street}{building}号"

        # 入学日期
        enrollment_year = 2024 - grade + 1
        enrollment_date = f"{enrollment_year}-09-01"

        # GPA (1.00 - 4.00)
        gpa = round(random.uniform(2.0, 4.0), 2)

        # 状态
        status = random.choice(['在读'] * 90 + ['休学'] * 5 + ['交流'] * 5)

        students.append((
            i, name, gender, age, grade, class_name, major,
            phone, email, address, enrollment_date, gpa, status
        ))

    # 批量插入数据
    print(f"\n[5] 插入 {len(students)} 条学生记录...")

    batch_size = 100
    for i in range(0, len(students), batch_size):
        batch = students[i:i + batch_size]
        cursor.executemany("""
            INSERT INTO student_info
            (student_id, student_name, gender, age, grade, class_name, major,
             phone, email, address, enrollment_date, gpa, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, batch)
        print(f"  已插入 {min(i + batch_size, len(students))} / {len(students)} 条记录...")

    conn.commit()
    print("✅ 数据插入成功!")

    # 验证数据
    print("\n[6] 验证数据...")
    cursor.execute("SELECT COUNT(*) FROM student_info")
    total = cursor.fetchone()[0]
    print(f"✅ 总记录数: {total}")

    # 统计信息
    print("\n[7] 数据统计信息:")

    cursor.execute("SELECT gender, COUNT(*) FROM student_info GROUP BY gender")
    gender_stats = cursor.fetchall()
    print("  性别分布:")
    for row in gender_stats:
        print(f"    {row[0]}: {row[1]} 人")

    cursor.execute("SELECT grade, COUNT(*) FROM student_info GROUP BY grade ORDER BY grade")
    grade_stats = cursor.fetchall()
    print("\n  年级分布:")
    for row in grade_stats:
        print(f"    {row[0]}年级: {row[1]} 人")

    cursor.execute("SELECT AVG(gpa) FROM student_info")
    avg_gpa = cursor.fetchone()[0]
    print(f"\n  平均GPA: {float(avg_gpa):.2f}")

    cursor.execute("SELECT AVG(age) FROM student_info")
    avg_age = cursor.fetchone()[0]
    print(f"  平均年龄: {float(avg_age):.1f} 岁")

    # 查询示例
    print("\n[8] 数据样例 (前10条):")
    cursor.execute("""
        SELECT student_id, student_name, gender, age, grade, major, gpa
        FROM student_info
        LIMIT 10
    """)
    samples = cursor.fetchall()
    print("\n  ID   | 姓名 | 性别 | 年龄 | 年级 | 专业 | GPA")
    print("  " + "-" * 70)
    for row in samples:
        print(f"  {row[0]:04d} | {row[1]:4s} | {row[2]:2s} | {row[3]:2d} | {row[4]:d} | {row[5]:20s} | {float(row[6]):.2f}")

    # 关闭连接
    cursor.close()
    conn.close()

    print("\n" + "=" * 70)
    print("✅ 测试数据生成完成!")
    print("=" * 70)
    print("\n【GBase 数据库连接信息】")
    print(f"  主机: localhost")
    print(f"  端口: 5258")
    print(f"  用户名: root")
    print(f"  密码: root")
    print(f"  数据库: sqlbot_test_db")
    print(f"  表名: student_info")
    print(f"  记录数: {total} 条")
    print("\n【表结构】")
    print("  student_id      INT          学号(主键)")
    print("  student_name    VARCHAR(50)  姓名")
    print("  gender          VARCHAR(10)  性别")
    print("  age             INT          年龄")
    print("  grade           INT          年级(1-4)")
    print("  class_name      VARCHAR(20)  班级")
    print("  major           VARCHAR(50)  专业")
    print("  phone           VARCHAR(20)  电话")
    print("  email           VARCHAR(100) 邮箱")
    print("  address         VARCHAR(200) 地址")
    print("  enrollment_date DATE         入学日期")
    print("  gpa             DECIMAL(3,2) 绩点(0.00-4.00)")
    print("  status          VARCHAR(20)  状态(在读/休学/交流)")
    print("\n【测试查询示例】")
    print("  1. 查询所有计算机专业的学生:")
    print("     SELECT * FROM student_info WHERE major LIKE '%计算机%'")
    print("\n  2. 统计各年级人数:")
    print("     SELECT grade, COUNT(*) FROM student_info GROUP BY grade")
    print("\n  3. 查询GPA大于3.5的优秀学生:")
    print("     SELECT student_name, major, gpa FROM student_info WHERE gpa > 3.5 ORDER BY gpa DESC")
    print("\n  4. 统计各专业平均GPA:")
    print("     SELECT major, AVG(gpa) FROM student_info GROUP BY major ORDER BY AVG(gpa) DESC")
    print("=" * 70)

except Exception as e:
    print(f"\n❌ 错误: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
