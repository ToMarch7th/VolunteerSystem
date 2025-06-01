import pyodbc
import os
from datetime import datetime
import logging
from dotenv import load_dotenv
from flask_wtf import FlaskForm
from wtforms import StringField, SelectField, IntegerField, SubmitField
from wtforms.validators import DataRequired, Email, Length
from werkzeug.security import generate_password_hash, check_password_hash

# 加载环境变量（将敏感信息如数据库密码放在.env文件中）
load_dotenv()

# 配置日志
logging.basicConfig(filename='volunteer_system.log', level=logging.INFO,
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('volunteer_system')

#######################
# 数据库连接类
#######################
class Database:
    def __init__(self):
        try:
            self.conn = pyodbc.connect(
                'DRIVER={ODBC Driver 17 for SQL Server};'
                'SERVER=幼稚无聊低龄蠢\\SQL;'  
                'DATABASE=Volunteer1;'
                'Trusted_Connection=yes;'
                'timeout=5;'
            )
            logger.info("数据库连接成功")
        except Exception as e:
            logger.error(f"数据库连接失败: {e}")
            raise
    
    def __del__(self):
        if hasattr(self, 'conn') and self.conn:
            self.conn.close()
    
    def execute_query(self, query, params=None):
        try:
            cursor = self.conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            return cursor
        except Exception as e:
            logger.error(f"查询执行失败: {query}, 错误: {e}")
            raise
    
    def execute_non_query(self, query, params=None):
        try:
            cursor = self.conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            self.conn.commit()
            return cursor.rowcount
        except Exception as e:
            self.conn.rollback()
            logger.error(f"非查询执行失败: {query}, 错误: {e}")
            raise
    
    def call_procedure(self, proc_name, *args):
        try:
            cursor = self.conn.cursor()
            cursor.execute(f"EXEC {proc_name} {','.join(['?' for _ in args])}", args)
            self.conn.commit()
            return cursor
        except Exception as e:
            self.conn.rollback()
            logger.error(f"存储过程执行失败: {proc_name}, 错误: {e}")
            raise

#######################
# 志愿者系统核心类
#######################
class VolunteerSystem:
    def __init__(self):
        self.db = Database()

    #######################
    # 用户管理方法
    #######################
    
    def get_user_by_username(self, username):
        """根据用户名获取用户"""
        cursor = self.db.execute_query(
            "SELECT * FROM [User] WHERE username = ?", 
            (username,)
        )
        return cursor.fetchone()
    
    def get_user_by_id(self, user_id):
        """根据用户ID获取用户信息"""
        cursor = self.db.execute_query(
            "SELECT * FROM [User] WHERE user_id = ?", 
            (user_id,)
        )
        return cursor.fetchone() if cursor else None

    def add_user(self, username, password, real_name, college_id, user_type=1, email=None, phone=None):
        """添加新用户
        Args:
            username: 用户名
            password: 密码
            real_name: 真实姓名
            college_id: 学院ID
            user_type: 用户类型（默认为1-普通用户）
            email: 电子邮箱（可选）
            phone: 电话号码（可选）
        """
        query = """
        INSERT INTO [User] 
        (username, password, real_name, college_id, user_type, email, phone, register_time) 
        VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE())
        """
        self.db.execute_non_query(query, (username, password, real_name, college_id, user_type, email, phone))
        logging.info(f"新用户添加成功: {username}")

    def update_user_last_login(self, user_id):
        """更新用户最后登录时间"""
        self.db.execute_non_query(
            "UPDATE [User] SET last_login_time = GETDATE() WHERE user_id = ?",
            (user_id,)
        )

    #######################
    # 志愿者管理方法
    #######################

    def get_all_volunteers(self):
        """获取所有志愿者信息，包括基本信息和统计数据"""
        query = """
        SELECT 
            user_id as VolunteerID,
            username as Username,
            real_name as Name,
            gender as Gender,
            phone as Phone,
            email as Email,
            register_time as JoinDate,
            password as Password
        FROM [User]
        WHERE user_type = 0
        ORDER BY user_id DESC
        """
        cursor = self.db.execute_query(query)
        results = cursor.fetchall()
        
        # 在Python中处理性别转换
        for row in results:
            row.Gender = '女' if row.Gender == 1 else '男'
        
        return results
    
    def add_volunteer(self, username, name, gender, phone, email=None):
        """添加新志愿者
        Args:
            username: 用户名
            name: 真实姓名
            gender: 性别
            phone: 电话号码
            email: 电子邮箱（可选）
        """
        query = """
        INSERT INTO [User] (
            username, 
            password, 
            real_name, 
            gender,
            phone, 
            email, 
            user_type,
            register_time,
            total_hours,
            average_score
        ) VALUES (?, ?, ?, ?, ?, ?, 0, GETDATE(), 0, 0)
        """
        # 使用手机号后6位作为默认密码
        default_password = phone[-6:] if len(phone) >= 6 else phone
        
        params = (
            username,
            default_password,  # 直接使用明文密码
            name,
            gender,
            phone,
            email
        )
        
        try:
            self.db.execute_non_query(query, params)
            logging.info(f"新志愿者添加成功: {name}")
        except Exception as e:
            logging.error(f"添加志愿者失败: {str(e)}")
            raise Exception(f"添加失败: {str(e)}")
    
    def update_volunteer_password(self, volunteer_id, new_password):
        """更新志愿者密码"""
        query = """
        UPDATE [User] 
        SET password = ?
        WHERE user_id = ? AND user_type = 0
        """
        affected_rows = self.db.execute_non_query(query, (new_password, volunteer_id))
        if affected_rows == 0:
            raise Exception("未找到该志愿者或更新失败")
        logging.info(f"志愿者(ID:{volunteer_id})密码更新成功")

    def delete_volunteer(self, volunteer_id):
        """删除志愿者及其所有相关信息（包括服务评价和活动申请）"""
        try:
            # 开始事务
            cursor = self.db.conn.cursor()
            
            # 删除志愿者的服务评价记录
            cursor.execute("""
                DELETE FROM ServiceEvaluation 
                WHERE application_id IN (
                    SELECT application_id 
                    FROM Application 
                    WHERE volunteer_id = ?
                )
            """, (volunteer_id,))
            
            # 删除志愿者的活动申请记录
            cursor.execute("""
                DELETE FROM Application 
                WHERE volunteer_id = ?
            """, (volunteer_id,))
            
            # 删除志愿者记录
            cursor.execute("""
                DELETE FROM [User] 
                WHERE user_id = ? AND user_type = 0
            """, (volunteer_id,))
            
            if cursor.rowcount == 0:
                raise Exception("未找到该志愿者或删除失败")
            
            self.db.conn.commit()
            logging.info(f"志愿者(ID:{volunteer_id})及其相关信息删除成功")
            
        except Exception as e:
            self.db.conn.rollback()
            logging.error(f"删除志愿者(ID:{volunteer_id})失败: {str(e)}")
            raise Exception(f"删除志愿者失败: {str(e)}")

    def get_user_total_hours(self, user_id):
        """获取用户的累计志愿时长"""
        cursor = self.db.execute_query(
            "SELECT total_hours FROM [User] WHERE user_id = ?",
            (user_id,)
        )
        result = cursor.fetchone()
        return result[0] if result else 0
    
    def update_user_profile(self, user_id, real_name, email, phone, gender, college_id):
        """更新用户个人资料
        Args:
            user_id: 用户ID
            real_name: 真实姓名
            email: 电子邮箱
            phone: 电话号码
            gender: 性别（0-男，1-女）
            college_id: 学院ID
        """
        # 处理空值和类型转换
        if not real_name or not phone or gender is None:
            raise ValueError("姓名、电话和性别为必填项")
        
        # 如果email为空字符串，则设为None
        if email == '':
            email = None
        
        # 转换gender为整数
        if isinstance(gender, str):
            gender = int(gender)
            
        # 转换college_id为整数或None
        if college_id and isinstance(college_id, str):
            if college_id.isdigit():
                college_id = int(college_id)
            elif college_id == '':
                college_id = None
        
        query = """
        UPDATE [User]
        SET 
            real_name = ?,
            email = ?,
            phone = ?,
            gender = ?,
            college_id = ?
        WHERE user_id = ?
        """
        try:
            self.db.execute_non_query(query, (real_name, email, phone, gender, college_id, user_id))
            logging.info(f"用户(ID:{user_id})资料更新成功")
        except Exception as e:
            logging.error(f"更新用户资料失败: {str(e)}")
            raise Exception(f"更新失败: {str(e)}")

    #######################
    # 活动管理方法
    #######################

    def get_active_activities(self,user_id=None):
        """获取所有活跃活动(未开始：status=0，正在进行：status=1)，包括活动类型和地点信息"""
        cursor = self.db.execute_query("""
        SELECT 
            a.*,
            at.type_name,
            l.location_name,
            (SELECT COUNT(*) FROM Application ap WHERE ap.activity_id = a.activity_id) as registered_count
        FROM Activity a
        LEFT JOIN ActivityType at ON a.type_id = at.type_id
        LEFT JOIN Location l ON a.location_id = l.location_id
        WHERE a.status = 0 or a.status = 1
        """)
        return cursor.fetchall()

    def get_activity_by_id(self, activity_id):
        """根据活动ID获取活动详细信息"""
        query = """
        SELECT 
            a.*,
            l.location_name,
            at.type_name,
            (SELECT COUNT(*) FROM Application ap WHERE ap.activity_id = a.activity_id) as registered_count
        FROM Activity a
        LEFT JOIN Location l ON a.location_id = l.location_id
        LEFT JOIN ActivityType at ON a.type_id = at.type_id
        WHERE a.activity_id = ?
        """
        cursor = self.db.execute_query(query, (activity_id,))
        return cursor.fetchone() if cursor else None

    def get_volunteer_completed_activities(self, volunteer_id):
        """获取指定志愿者已参加过的活动（已结束）"""
        query = """
        SELECT 
            a.activity_id,
            a.activity_name,
            a.start_time,
            a.end_time,
            a.location_id,
            a.type_id,
            se.actual_hours,
            se.score,
            se.comments,
            se.evaluation_time
        FROM ServiceEvaluation se
        JOIN Application ap ON se.application_id = ap.application_id
        JOIN Activity a ON ap.activity_id = a.activity_id
        WHERE ap.volunteer_id = ? AND a.status = 3  -- 已结束的活动
        ORDER BY a.end_time DESC
        """
        cursor = self.db.execute_query(query, (volunteer_id,))
        rows = cursor.fetchall()

        # 将pyodbc.Row对象转换为可修改的字典列表
        activities = []
        for row in rows:
            activity_dict = {
                'activity_id': row.activity_id,
                'activity_name': row.activity_name,
                'start_time': row.start_time,
                'end_time': row.end_time,
                'location_id': row.location_id,
                'type_id': row.type_id,
                'actual_hours': row.actual_hours,
                'score': row.score,
                'comments': row.comments,
                'evaluation_time': row.evaluation_time,
                'status_label': "已结束"  # 添加状态标签
            }
            activities.append(activity_dict)
        
        return activities

    def add_activity(self, activity_data):
        """添加新活动
        Args:
            activity_data: 字典，包含活动的所有必要信息
        """
        query = """
        INSERT INTO [Activity] (
            activity_name, description, start_time, end_time, 
            registration_deadline, location_id, type_id, 
            max_participants, current_participants, requirements, 
            status, created_by, created_time
        ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, 1, ?, GETDATE()
        )
        """
        params = (
            activity_data['activity_name'],
            activity_data['description'],
            activity_data['start_time'],
            activity_data['end_time'],
            activity_data['registration_deadline'],
            activity_data['location_id'],
            activity_data['type_id'],
            activity_data['max_participants'],
            activity_data['requirements'],
            activity_data['created_by']
        )
        self.db.execute_non_query(query, params)
        logging.info(f"新活动添加成功: {activity_data['activity_name']}")

    def get_activity_volunteers(self, activity_id):
        """获取活动的所有志愿者信息"""
        query = """
        SELECT 
            u.user_id,
            u.real_name,
            u.gender,
            u.phone,
            a.application_time,
            a.status
        FROM [User] u
        JOIN [Application] a ON u.user_id = a.volunteer_id
        WHERE a.activity_id = ?
        ORDER BY a.application_time DESC
        """
        cursor = self.db.execute_query(query, (activity_id,))
        return cursor.fetchall()

    #######################
    # 报名管理方法
    #######################

    def get_applications_for_activity(self, activity_id):
        """获取某个活动的所有报名信息"""
        cursor = self.db.execute_query(
            "SELECT * FROM [Application] WHERE activity_id = ?", 
            (activity_id,)
        )
        return cursor.fetchall()

    def check_user_registered(self, user_id, activity_id):
        """检查用户是否已报名参加某个活动"""
        cursor = self.db.execute_query(
            "SELECT * FROM [Application] WHERE volunteer_id = ? AND activity_id = ?", 
            (user_id, activity_id)
        )
        return cursor.fetchone() is not None

    def register_for_activity(self, user_id, activity_id):
        """创建活动报名记录"""
        query = """
        INSERT INTO [Application] 
        (activity_id, volunteer_id, application_time, status)
        VALUES (?, ?, GETDATE(), 0)
        """
        self.db.execute_non_query(query, (activity_id, user_id))

    def cancel_registration(self, user_id, activity_id):
        """取消活动报名
        Args:
            user_id: 用户ID
            activity_id: 活动ID
        Returns:
            bool: 是否成功取消
        """
        # 查询申请记录
        query_check = """
        SELECT application_id, status FROM [Application] 
        WHERE volunteer_id = ? AND activity_id = ?
        """
        cursor = self.db.execute_query(query_check, (user_id, activity_id))
        application = cursor.fetchone()
        
        if not application:
            raise Exception("未找到报名记录")
        
        # 如果申请已通过，需要更新活动的当前参与人数
        if application.status == 1:  # 1表示申请已通过
            self.db.execute_non_query(
                "UPDATE Activity SET current_participants = current_participants - 1 WHERE activity_id = ?",
                (activity_id,)
            )
        
        # 删除申请记录
        query_delete = """
        DELETE FROM [Application] 
        WHERE volunteer_id = ? AND activity_id = ?
        """
        self.db.execute_non_query(query_delete, (user_id, activity_id))
        
        return True

    def get_pending_applications(self):
        """获取所有待审核的报名申请"""
        query = """
        SELECT 
            a.application_id,
            a.activity_id,
            act.activity_name,
            a.volunteer_id,
            u.real_name AS volunteer_name,
            u.phone AS volunteer_phone,
            u.email AS volunteer_email,
            a.application_time,
            a.status
        FROM Application a
        JOIN Activity act ON a.activity_id = act.activity_id
        JOIN [User] u ON a.volunteer_id = u.user_id
        WHERE a.status = 0
        ORDER BY a.application_time DESC
        """
        cursor = self.db.execute_query(query)
        return cursor.fetchall()
    
    def review_application(self, application_id, status, reviewer_id, comment):
        """审核志愿者的活动报名申请
        Args:
            application_id: 申请ID
            status: 审核状态（1-通过，2-拒绝）
            reviewer_id: 审核人ID
            comment: 审核备注
        """
        query = """
        UPDATE Application
        SET 
            status = ?,
            reviewed_by = ?,
            review_time = GETDATE(),
            review_comment = ?
        WHERE application_id = ?
        """
        self.db.execute_non_query(query, (status, reviewer_id, comment, application_id))
        
        # 如果审核通过，更新活动的当前参与人数
        if status == 1:
            # 获取活动ID
            cursor = self.db.execute_query(
                "SELECT activity_id FROM Application WHERE application_id = ?",
                (application_id,)
            )
            activity_id = cursor.fetchone()[0]
            
            # 更新活动参与人数
            self.db.execute_non_query(
                "UPDATE Activity SET current_participants = current_participants + 1 WHERE activity_id = ?",
                (activity_id,)
            )
            
            # 检查是否已满员，如果满员则更新状态
            cursor = self.db.execute_query(
                "SELECT current_participants, max_participants FROM Activity WHERE activity_id = ?",
                (activity_id,)
            )
            result = cursor.fetchone()
            current = result[0]
            max_num = result[1]
            
            if current >= max_num:
                self.db.execute_non_query(
                    "UPDATE Activity SET status = 2 WHERE activity_id = ?",
                    (activity_id,)
                )
    
    def get_volunteer_registered_activities(self, volunteer_id):
        """获取志愿者已报名的所有活动
        Args:
            volunteer_id: 志愿者用户ID
        """
        query = """
        SELECT 
            a.application_id,
            act.activity_id,
            act.activity_name,
            act.description,
            act.start_time,
            act.end_time,
            l.location_name,
            l.address,
            at.type_name AS activity_type,
            a.application_time,
            a.status AS application_status,
            a.review_comment,
            CASE a.status
                WHEN 0 THEN '待审核'
                WHEN 1 THEN '已通过'
                WHEN 2 THEN '已拒绝'
            END AS application_status_text,
            CASE act.status
                WHEN 0 THEN '已结束'
                WHEN 1 THEN '进行中'
                WHEN 2 THEN '已满员'
            END AS activity_status
        FROM Application a
        JOIN Activity act ON a.activity_id = act.activity_id
        JOIN Location l ON act.location_id = l.location_id
        JOIN ActivityType at ON act.type_id = at.type_id
        WHERE a.volunteer_id = ?
        ORDER BY a.application_time DESC
        """
        cursor = self.db.execute_query(query, (volunteer_id,))
        rows = cursor.fetchall()
        
        # 将pyodbc.Row对象转换为可修改的字典列表
        activities = []
        for row in rows:
            activity_dict = {
                'application_id': row.application_id,
                'activity_id': row.activity_id,
                'activity_name': row.activity_name,
                'description': row.description,
                'start_time': row.start_time,
                'end_time': row.end_time,
                'location_name': row.location_name,
                'address': row.address,
                'activity_type': row.activity_type,
                'application_time': row.application_time,
                'application_status': row.application_status,
                'review_comment': row.review_comment,
                'application_status_text': row.application_status_text,
                'activity_status': row.activity_status
            }
            activities.append(activity_dict)
            
        return activities

    #######################
    # 评价管理方法
    #######################

    def get_application_by_id(self, application_id):
        """根据申请ID获取申请信息"""
        cursor = self.db.execute_query(
            "SELECT * FROM [Application] WHERE application_id = ?", 
            (application_id,)
        )
        return cursor.fetchone()

    def evaluate_application(self, application_id, actual_hours, score, comments, evaluated_by):
        """添加服务评价"""
        query = """
        INSERT INTO [ServiceEvaluation] 
        (application_id, actual_hours, score, comments, evaluated_by, evaluation_time)
        VALUES (?, ?, ?, ?, ?, GETDATE())
        """
        self.db.execute_non_query(query, (
            application_id, actual_hours, score, comments, evaluated_by
        ))
        
        # 更新用户的总服务时长和平均分
        self._update_user_volunteer_stats(application_id)

    def _update_user_volunteer_stats(self, application_id):
        """更新志愿者服务统计信息（总时长和平均分）"""
        # 获取志愿者ID
        cursor = self.db.execute_query(
            "SELECT volunteer_id FROM [Application] WHERE application_id = ?",
            (application_id,)
        )
        volunteer_id = cursor.fetchone()[0]

        # 计算总时长和平均分
        cursor = self.db.execute_query("""
        SELECT 
            SUM(se.actual_hours) as total_hours,
            AVG(se.score) as avg_score
        FROM [ServiceEvaluation] se
        JOIN [Application] a ON se.application_id = a.application_id
        WHERE a.volunteer_id = ?
        """, (volunteer_id,))
        
        result = cursor.fetchone()
        total_hours = result[0] or 0
        avg_score = result[1] or 0

        # 更新用户记录
        self.db.execute_non_query("""
        UPDATE [User] 
        SET total_hours = ?, average_score = ?
        WHERE user_id = ?
        """, (total_hours, avg_score, volunteer_id))

    #######################
    # 基础数据方法
    #######################

    def get_colleges(self):
        """获取所有学院信息(已去重)"""
        cursor = self.db.execute_query("SELECT DISTINCT college_id, college_name FROM [College] ORDER BY college_id")
        return cursor.fetchall()

    def get_locations(self):
        """获取所有地点信息(已去重)"""
        cursor = self.db.execute_query("SELECT DISTINCT location_id, location_name, address FROM [Location] ORDER BY location_id")
        return cursor.fetchall()

    def get_activity_types(self):
        """获取所有活动类型(已去重)"""
        cursor = self.db.execute_query("SELECT DISTINCT type_id, type_name FROM [ActivityType] ORDER BY type_id")
        return cursor.fetchall()

    def get_organizations(self):
        """获取所有志愿者组织(已去重)"""
        cursor = self.db.execute_query("SELECT DISTINCT organization_id, organization_name FROM [VolunteerOrganization] ORDER BY organization_id")
        return cursor.fetchall()

    def get_all_locations(self):
        """获取所有活动地点(已去重)"""
        return self.get_locations()

    def get_volunteer_upcoming_activities(self, volunteer_id):
        """获取指定志愿者已报名但尚未开始的活动"""
        query = """
        SELECT 
            a.activity_id,
            a.activity_name,
            a.start_time,
            a.end_time,
            a.location_id,
            a.type_id,
            ap.application_time,
            a.registration_deadline
        FROM Application ap
        JOIN Activity a ON ap.activity_id = a.activity_id
        WHERE ap.volunteer_id = ? AND a.status = 1  -- 未开始的活动
        ORDER BY a.start_time ASC
        """
        cursor = self.db.execute_query(query, (volunteer_id,))
        rows = cursor.fetchall()

        # 将pyodbc.Row对象转换为可修改的字典列表
        activities = []
        for row in rows:
            activity_dict = {
                'activity_id': row.activity_id,
                'activity_name': row.activity_name,
                'start_time': row.start_time,
                'end_time': row.end_time,
                'location_id': row.location_id,
                'type_id': row.type_id,
                'application_time': row.application_time,
                'registration_deadline': row.registration_deadline,
                'status_label': "未开始"  # 添加状态标签
            }
            activities.append(activity_dict)

        return activities

#######################
# 命令行界面方法
#######################

def display_menu():
    """显示主菜单"""
    print("\n志愿者管理系统")
    print("1. 志愿者管理")
    print("2. 活动管理")
    print("3. 报名管理")
    print("4. 服务记录管理")
    print("5. 退出")
    return input("请选择: ")

def volunteer_menu(system):
    """志愿者管理菜单"""
    while True:
        print("\n志愿者管理")
        print("1. 添加志愿者")
        print("2. 查询所有志愿者")
        print("3. 返回主菜单")
        choice = input("请选择: ")
        
        if choice == '1':
            try:
                name = input("姓名: ")
                gender = input("性别: ")
                phone = input("电话: ")
                email = input("邮箱: ")
                
                system.add_volunteer(name, name, gender, phone, email)
                print("添加成功！")
            except Exception as e:
                print(f"添加失败: {e}")
        
        elif choice == '2':
            try:
                volunteers = system.get_all_volunteers()
                if not volunteers:
                    print("暂无志愿者记录")
                else:
                    for v in volunteers:
                        print(f"ID:{v.VolunteerID} 姓名:{v.Name} 性别:{v.Gender} 电话:{v.Phone}")
            except Exception as e:
                print(f"查询失败: {e}")
        
        elif choice == '3':
            break

def main():
    """主程序入口"""
    try:
        print("系统启动中...")
        logger.info("系统启动中...")
        
        print("正在初始化数据库连接...")
        system = VolunteerSystem()
        print("数据库连接初始化完成")
        
        while True:
            choice = display_menu()
            
            if choice == '1':
                volunteer_menu(system)
            elif choice == '2':
                print("活动管理功能待实现")
            elif choice == '3':
                print("报名管理功能待实现")
            elif choice == '4':
                print("服务记录管理功能待实现")
            elif choice == '5':
                print("感谢使用，再见！")
                break
            else:
                print("无效选择，请重试")
    
    except Exception as e:
        logger.critical(f"系统错误: {e}")
        print(f"系统发生错误: {e}")

if __name__ == "__main__":
    main()