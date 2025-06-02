from werkzeug.security import generate_password_hash

def generate_password_hashes(passwords_dict):
    """生成指定密码的哈希值
    
    Args:
        passwords_dict: 用户名和密码的字典，如{'admin1': 'admin123'}
        
    Returns:
        生成的SQL语句列表
    """
    sql_statements = ["-- SQL Server密码更新语句", "USE Volunteer1;", "GO", ""]
    
    # 生成每个用户的密码哈希并输出SQL更新语句
    for username, password in passwords_dict.items():
        hash_value = generate_password_hash(password)
        sql_statements.append(f"UPDATE [User] SET password = '{hash_value}' WHERE username = '{username}';")
    
    sql_statements.append("GO")
    return sql_statements

# 测试代码
if __name__ == "__main__":
    # 所有用户及其密码
    passwords = {
        'admin1': 'admin123',
        'org_admin1': 'orgadmin123',
        'volunteer1': 'vol123',
        'volunteer2': 'vol123',
        'volunteer3': 'vol123'
    }
    
    for sql in generate_password_hashes(passwords):
        print(sql)
