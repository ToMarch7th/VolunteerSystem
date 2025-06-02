# 志愿者管理系统安装指南

本文档提供了志愿者管理系统的详细安装和配置步骤。

## 系统要求

- Python 3.8+
- SQL Server 2016+
- ODBC Driver 17 for SQL Server

## 安装步骤

### 1. 克隆代码库

```bash
git clone <repository-url>
cd VolunteerSystem
```

### 2. 创建虚拟环境

```bash
# 使用venv
python -m venv venv

# 激活虚拟环境
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate
```

### 3. 安装依赖

```bash
pip install -r requirements.txt
```

### 4. 配置数据库

#### 4.1 创建数据库

使用SQL Server Management Studio或命令行创建数据库：

```sql
CREATE DATABASE Volunteer1;
```

#### 4.2 初始化数据库结构

```bash
sqlcmd -S <服务器名> -i volunteer_schema.sql
```

#### 4.3 运行数据库迁移脚本

```bash
sqlcmd -S <服务器名> -i migrations/fix_email_constraint.sql
sqlcmd -S <服务器名> -i migrations/add_gender_field.sql
```

### 5. 配置环境变量

复制环境变量示例文件并进行配置：

```bash
cp env.example .env
```

编辑`.env`文件，设置以下参数：

```
# 数据库连接参数
DB_SERVER=<你的SQL Server实例名>
DB_NAME=Volunteer1
DB_DRIVER=SQL Server
DB_TRUSTED_CONNECTION=yes

# 应用配置
SECRET_KEY=<生成一个强密钥>
DEBUG=True
```

### 6. 创建必要的目录

```bash
mkdir -p logs
```

## 启动应用

```bash
python volunteer_web.py
```

默认情况下，应用将在 http://127.0.0.1:5000 上运行。

## 生产环境部署

### 使用Gunicorn和Nginx

#### 1. 安装Gunicorn

```bash
pip install gunicorn
```

#### 2. 创建Gunicorn启动脚本

创建文件`start.sh`：

```bash
#!/bin/bash
source venv/bin/activate
exec gunicorn -w 4 -b 127.0.0.1:8000 volunteer_web:app
```

赋予执行权限：

```bash
chmod +x start.sh
```

#### 3. 配置Nginx

创建Nginx配置文件`/etc/nginx/sites-available/volunteer_system`：

```
server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /static {
        alias /path/to/VolunteerSystem/static;
    }
}
```

创建符号链接并重启Nginx：

```bash
sudo ln -s /etc/nginx/sites-available/volunteer_system /etc/nginx/sites-enabled
sudo systemctl restart nginx
```

### 使用Supervisor管理进程

#### 1. 安装Supervisor

```bash
sudo apt-get install supervisor
```

#### 2. 创建Supervisor配置

创建文件`/etc/supervisor/conf.d/volunteer_system.conf`：

```
[program:volunteer_system]
command=/path/to/VolunteerSystem/start.sh
directory=/path/to/VolunteerSystem
user=www-data
autostart=true
autorestart=true
stderr_logfile=/var/log/volunteer_system/error.log
stdout_logfile=/var/log/volunteer_system/access.log
```

#### 3. 更新Supervisor

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start volunteer_system
```

## 故障排除

### 数据库连接问题

1. 确保SQL Server服务正在运行
2. 检查连接字符串是否正确
3. 确认防火墙设置允许连接
4. 验证ODBC驱动程序安装正确

### 应用启动失败

1. 检查日志文件`logs/volunteer_system.log`
2. 确保所有依赖都已正确安装
3. 验证环境变量配置是否正确

### 权限问题

1. 确保应用目录具有适当的读写权限
2. 检查日志目录是否可写

## 更新系统

```bash
git pull
pip install -r requirements.txt
# 如有数据库更新，运行相应的迁移脚本
``` 