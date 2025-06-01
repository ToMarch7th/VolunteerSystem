# 志愿者管理系统

这是一个基于Python Flask和SQL Server的志愿者管理系统，提供完整的志愿者招募、活动管理和服务记录功能。

## 系统角色

1. **管理员**：负责系统管理，包括活动创建、志愿者审核、报名管理等。
2. **志愿者**：可以注册、报名参加活动，查看自己的活动记录和服务时长等。

## 主要功能

### 用户管理
- 用户注册与登录
- 个人资料管理
- 密码管理

### 志愿者管理
- 志愿者信息管理
- 志愿者服务时长统计
- 志愿者评分与评价

### 活动管理
- 活动创建与编辑
- 活动类型与地点管理
- 活动状态跟踪（未开始、进行中、已满员、已结束）

### 报名管理
- 活动报名与取消
- 报名申请审核
- 报名状态跟踪

### 服务记录
- 服务时长记录
- 服务评价与反馈
- 服务记录查询

### 系统管理
- 数据统计与分析
- 日志记录与监控

## 目录结构

```
VolunteerSystem/
├── volunteer_models.py   # 数据模型和业务逻辑
├── volunteer_web.py      # Web应用和路由处理
├── volunteer_schema.sql  # 数据库初始化脚本
├── requirements.txt      # 项目依赖
├── env.example           # 环境变量示例
├── README.md             # 项目说明文档
├── .gitignore            # Git忽略文件
├── templates/            # HTML模板文件
│   ├── base.html                    # 基础模板
│   ├── login.html                   # 登录页面
│   ├── register_volunteer.html      # 志愿者注册
│   ├── index_administrator.html     # 管理员首页
│   ├── index_volunteer.html         # 志愿者首页
│   ├── profile.html                 # 个人资料
│   ├── edit_profile.html            # 编辑个人资料
│   ├── volunteers.html              # 志愿者列表
│   ├── add_volunteer.html           # 添加志愿者
│   ├── activities.html              # 活动列表
│   ├── add_activity.html            # 添加活动
│   ├── activity_detail_volunteer.html # 志愿者查看活动详情
│   ├── activity_volunteer.html      # 活动志愿者管理
│   ├── enrollable_activities.html   # 可报名活动列表
│   ├── manage_applications.html     # 报名管理
│   ├── volunteer_activities.html    # 志愿者活动列表
│   └── service_records.html         # 服务记录
├── migrations/          # 数据库迁移脚本
│   ├── fix_email_constraint.sql     # 修复邮箱约束
│   └── add_gender_field.sql         # 添加性别字段
├── utils/               # 工具函数和辅助模块
│   ├── __init__.py                  # 包初始化
│   ├── config.py                    # 配置工具
│   └── password_generator.py        # 密码生成工具
├── tests/               # 测试代码
│   ├── __init__.py                  # 测试包初始化
│   └── test_basic.py                # 基础测试
└── logs/                # 日志文件
    └── volunteer_system.log         # 系统日志
```

## 安装与设置

1. **克隆代码库**：
   ```
   git clone <repository-url>
   cd VolunteerSystem
   ```

2. **安装依赖**：
   ```
   pip install -r requirements.txt
   ```

3. **配置环境变量**：
   ```
   cp env.example .env
   # 编辑.env文件，设置数据库连接等参数
   ```

4. **创建数据库**：
   ```
   sqlcmd -S <服务器名> -i volunteer_schema.sql
   ```

5. **运行数据库迁移**：
   ```
   sqlcmd -S <服务器名> -i migrations/fix_email_constraint.sql
   sqlcmd -S <服务器名> -i migrations/add_gender_field.sql
   ```

6. **启动应用**：
   ```
   python volunteer_web.py
   ```

## 使用说明

### 管理员功能
1. 管理志愿者：添加、编辑、删除志愿者信息
2. 管理活动：创建活动、查看报名情况、评价志愿者服务
3. 管理报名：审核志愿者的活动报名申请

### 志愿者功能
1. 个人资料：查看和编辑个人信息
2. 活动报名：浏览可报名活动、提交报名申请
3. 服务记录：查看服务时长、活动评价和历史记录

## 系统账户

系统默认创建以下测试账户：
- 管理员：admin1/admin123
- 志愿者：volunteer1/vol123, volunteer2/vol123, volunteer3/vol123

## 开发指南

### 技术栈
- 后端：Python + Flask
- 数据库：SQL Server
- 前端：Bootstrap + jQuery

### 代码规范
- 使用统一的命名规范
- 添加适当的注释
- 编写单元测试

### 贡献流程
1. Fork项目
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

## 许可证

本项目采用MIT许可证。详见LICENSE文件。 