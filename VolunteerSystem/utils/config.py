"""配置工具

加载和管理系统配置
"""
import os
from dotenv import load_dotenv
import logging

# 加载环境变量
load_dotenv()

# 数据库配置
DB_CONFIG = {
    'server': os.getenv('DB_SERVER', 'localhost'),
    'database': os.getenv('DB_NAME', 'Volunteer1'),
    'driver': os.getenv('DB_DRIVER', 'SQL Server'),
}

# 应用配置
APP_CONFIG = {
    'secret_key': os.getenv('SECRET_KEY', 'dev_key_change_in_production'),
    'debug': os.getenv('DEBUG', 'True').lower() == 'true',
}

# 日志配置
LOG_CONFIG = {
    'level': getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    'filename': os.getenv('LOG_FILE', 'logs/volunteer_system.log'),
    'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
}

def setup_logging():
    """设置日志"""
    # 确保日志目录存在
    log_dir = os.path.dirname(LOG_CONFIG['filename'])
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    
    # 配置日志
    logging.basicConfig(
        level=LOG_CONFIG['level'],
        filename=LOG_CONFIG['filename'],
        format=LOG_CONFIG['format']
    )
    
    return logging.getLogger('volunteer_system') 