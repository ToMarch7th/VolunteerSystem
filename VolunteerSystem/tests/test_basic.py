import pyodbc

def test_all_connections():
    servers = [
        "白色",              # 仅计算机名
        "localhost",         # 本地别名
        "127.0.0.1",        # IPv4环回
        "白色\MSSQLSERVER",  # 显式默认实例
        "(local)"           # 本地特殊别名
    ]
    
    for server in servers:
        try:
            print(f"尝试连接: {server}...", end=" ")
            conn = pyodbc.connect(
                'DRIVER={ODBC Driver 17 for SQL Server};'
                f'SERVER={server};'
                'DATABASE=Volunteer1;'
                'Trusted_Connection=yes;'
                'timeout=3;'
            )
            cursor = conn.cursor()
            cursor.execute("SELECT DB_NAME()")  # 获取当前数据库名
            db_name = cursor.fetchone()[0]
            print(f"✅ 成功！当前数据库: {db_name}")
            conn.close()
            return True
        except Exception as e:
            print(f"❌ 失败: {str(e).split(']')[-1].strip()}")
    
    print("\n⚠️ 所有连接尝试均失败，请检查：")
    print("- SQL Server (MSSQLSERVER)服务是否正在运行")
    print("- 是否启用了TCP/IP协议（SQL Server配置管理器）")
    print("- 防火墙是否放行了1433端口")
    return False

if __name__ == "__main__":
    test_all_connections()
    input("按Enter键退出...")