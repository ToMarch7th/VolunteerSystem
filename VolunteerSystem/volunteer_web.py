from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import os
from datetime import datetime
from dotenv import load_dotenv
from functools import wraps

# 导入数据库类
from volunteer_models import Database, VolunteerSystem

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "dev_key_change_in_production")

# 初始化系统
system = VolunteerSystem()

#######################
# 权限控制装饰器
#######################

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session or session.get('user_type') != 1:  # 1代表管理员
            flash('无权访问此页面', 'danger')
            return redirect(url_for('index_administrator'))
        return f(*args, **kwargs)
    return decorated_function

@app.before_request
def check_logged_in():
    if 'user_id' not in session and request.endpoint != 'login' and request.endpoint != 'register_volunteer':
        return redirect(url_for('login'))

#######################
# 基础路由 - 登录/登出/首页
#######################

@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        user = system.get_user_by_username(username)
        
        # 临时直接比较明文密码（仅用于测试）
        if user and user.password == password:
            session['user_id'] = user.user_id
            session['username'] = user.username
            session['user_type'] = user.user_type
            
            system.update_user_last_login(user.user_id)
            
            flash('登录成功！', 'success')
            # 判断用户类型
            if user.user_type == 1:  # 管理员
                return redirect(url_for('index_administrator'))
            else:  # 志愿者或其他用户类型
                return redirect(url_for('index_volunteer'))  
        else:
            flash('用户名或密码错误', 'danger')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('user_id', None)
    session.pop('username', None)
    session.pop('user_type', None)
    flash('您已退出登录', 'info')
    return redirect(url_for('login'))

@app.route('/index_administrator')
def index_administrator():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    user = system.get_user_by_id(session['user_id'])
    activities = system.get_active_activities()
    
    return render_template('index_administrator.html', user=user, activities=activities)

@app.route('/index_volunteer')
def index_volunteer():
    if 'user_id' not in session:
        return redirect(url_for('login'))

    user = system.get_user_by_id(session['user_id'])
    # 获取志愿者已报名且未开始的活动，用于显示在首页
    activities = system.get_volunteer_upcoming_activities(session['user_id'])

    return render_template('index_volunteer.html', user=user, activities=activities)

#######################
# 志愿者管理相关路由
#######################

@app.route('/volunteers')
@admin_required
def volunteers():
    volunteers = system.get_all_volunteers()
    return render_template('volunteers.html', volunteers=volunteers)

@app.route('/add_volunteer', methods=['GET', 'POST'])
@admin_required
def add_volunteer():
    if request.method == 'POST':
        try:
            username = request.form['username']
            name = request.form['name']
            gender = request.form['gender']
            phone = request.form['phone']
            email = request.form.get('email')

            if not username or not name or not phone:
                flash('请填写所有必填字段', 'danger')
                return redirect(url_for('add_volunteer'))

            existing_user = system.get_user_by_username(username)
            if existing_user:
                flash('用户名已存在，请选择其他用户名', 'danger')
                return redirect(url_for('add_volunteer'))

            system.add_volunteer(username, name, gender, phone, email)
            flash('志愿者添加成功！', 'success')
            return redirect(url_for('volunteers'))

        except Exception as e:
            flash(str(e), 'danger')
            return redirect(url_for('add_volunteer'))
    
    return render_template('add_volunteer.html')

@app.route('/verify_admin_password', methods=['POST'])
@admin_required
def verify_admin_password():
    data = request.get_json()
    admin_password = data.get('password')
    
    admin_user = system.get_user_by_id(session['user_id'])
    
    # 使用明文比较代替哈希验证
    if admin_user and admin_user.password == admin_password:
        return jsonify({'success': True})
    else:
        return jsonify({'success': False})

@app.route('/get_volunteer_password/<int:volunteer_id>')
@admin_required
def get_volunteer_password(volunteer_id):
    volunteer = system.get_user_by_id(volunteer_id)
    
    if volunteer:
        phone = volunteer.phone or ''
        default_password = phone[-6:] if len(phone) >= 6 else phone
        return jsonify({
            'success': True,
            'password': default_password
        })
    else:
        return jsonify({
            'success': False,
            'message': '未找到该志愿者'
        })

@app.route('/update_volunteer_password', methods=['POST'])
@admin_required
def update_volunteer_password():
    data = request.get_json()
    volunteer_id = data.get('volunteer_id')
    new_password = data.get('new_password')
    
    try:
        # 直接使用明文密码，不生成哈希值
        system.update_volunteer_password(volunteer_id, new_password)
        return jsonify({
            'success': True,
            'message': '密码更新成功'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        })

@app.route('/delete_volunteer/<int:volunteer_id>', methods=['DELETE'])
@admin_required
def delete_volunteer(volunteer_id):
    try:
        system.delete_volunteer(volunteer_id)
        return jsonify({
            'success': True,
            'message': '志愿者删除成功'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        })

#######################
# 活动管理相关路由
#######################

@app.route('/activities')
def activities():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    activities = system.get_active_activities()
    # 根据用户类型设置is_admin变量
    is_admin = session.get('user_type') == 1
    return render_template('activities.html', activities=activities, is_admin=is_admin)

@app.route('/enrollable_activities')
def enrollable_activities():
    """志愿者可报名活动列表"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    # 获取筛选参数
    filter_type = request.args.get('filter', 'all')
    
    # 获取所有活跃活动
    activities = system.get_active_activities()
    
    # 获取当前时间用于检查报名截止时间
    current_time = datetime.now()
    
    # 将pyodbc.Row对象转换为可修改的字典列表
    activities_list = []
    for activity in activities:
        # 检查用户是否已报名此活动
        is_registered = system.check_user_registered(session['user_id'], activity.activity_id)
        
        # 检查是否已过报名截止时间
        is_deadline_passed = activity.registration_deadline and current_time > activity.registration_deadline
        
        # 检查活动是否已开始
        is_activity_started = activity.start_time and current_time >= activity.start_time
        
        # 将行对象转换为字典
        activity_dict = {
            'activity_id': activity.activity_id,
            'activity_name': activity.activity_name,
            'type_name': activity.type_name,
            'location_name': activity.location_name,
            'start_time': activity.start_time,
            'end_time': activity.end_time,
            'registration_deadline': activity.registration_deadline,
            'registered_count': activity.registered_count,
            'max_participants': activity.max_participants,
            'status': activity.status,
            'is_registered': is_registered,
            'is_deadline_passed': is_deadline_passed,
            'is_activity_started': is_activity_started
        }
        activities_list.append(activity_dict)
    
    # 根据筛选类型过滤活动
    if filter_type == 'registered':
        activities_list = [a for a in activities_list if a['is_registered']]
    elif filter_type == 'unregistered':
        activities_list = [a for a in activities_list if not a['is_registered']]
    
    return render_template('enrollable_activities.html', 
                          activities=activities_list,
                          filter=filter_type)

@app.route('/activities/<int:activity_id>')
def activity_detail(activity_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    # 检查用户类型，志愿者应该使用志愿者专用的活动详情页面
    if session.get('user_type') == 0:  # 0代表志愿者
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    activity = system.get_activity_by_id(activity_id)
    if not activity:
        flash('活动不存在', 'danger')
        return redirect(url_for('activities'))
    
    # 获取该活动的所有志愿者
    volunteers = system.get_activity_volunteers(activity_id)
    
    return render_template('activity_volunteer.html', 
                         activity=activity,
                         volunteers=volunteers)

@app.route('/activities/detail/<int:activity_id>')
def activity_detail_volunteer(activity_id):
    """志愿者查看活动详情"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    activity_row = system.get_activity_by_id(activity_id)
    if not activity_row:
        flash('活动不存在', 'danger')
        return redirect(url_for('enrollable_activities'))
    
    # 将pyodbc.Row转换为字典
    activity = {
        'activity_id': activity_row.activity_id,
        'activity_name': activity_row.activity_name,
        'type_name': activity_row.type_name,
        'location_name': activity_row.location_name,
        'start_time': activity_row.start_time,
        'end_time': activity_row.end_time,
        'registration_deadline': activity_row.registration_deadline,
        'description': activity_row.description,
        'requirements': activity_row.requirements,
        'registered_count': activity_row.registered_count,
        'max_participants': activity_row.max_participants,
        'status': activity_row.status
    }
    
    # 检查用户是否已报名此活动
    is_registered = system.check_user_registered(session['user_id'], activity_id)
    
    # 检查是否已过报名截止时间
    current_time = datetime.now()
    is_deadline_passed = activity['registration_deadline'] and current_time > activity['registration_deadline']
    
    # 检查活动是否已开始
    is_activity_started = activity['start_time'] and current_time >= activity['start_time']
    
    return render_template('activity_detail_volunteer.html', 
                         activity=activity,
                         is_registered=is_registered,
                         is_deadline_passed=is_deadline_passed,
                         is_activity_started=is_activity_started)

@app.route('/admin/activities')
@admin_required
def admin_activities():
    activities = system.get_active_activities()
    # 使用已存在的activities.html模板，并添加is_admin标志
    return render_template('activities.html', activities=activities, is_admin=True)

@app.route('/admin/activities/add', methods=['GET', 'POST'])
@admin_required
def add_activity():
    if request.method == 'POST':
        try:
            # 将字符串格式的日期时间转换为datetime对象
            start_time = datetime.strptime(request.form['start_time'], '%Y-%m-%dT%H:%M')
            end_time = datetime.strptime(request.form['end_time'], '%Y-%m-%dT%H:%M')
            registration_deadline = datetime.strptime(request.form['registration_deadline'], '%Y-%m-%dT%H:%M')
            
            # 验证时间逻辑
            if end_time <= start_time:
                flash('活动结束时间必须晚于开始时间', 'danger')
                return redirect(url_for('add_activity'))
            
            if registration_deadline > start_time:
                flash('报名截止时间必须早于或等于活动开始时间', 'danger')
                return redirect(url_for('add_activity'))
            
            # 获取活动地点名称
            location_name = request.form['location_name']
            
            # 在数据库中查找或创建地点
            location_id = _get_or_create_location(location_name)
            
            activity_data = {
                'activity_name': request.form['activity_name'],
                'description': request.form.get('description', ''),
                'start_time': start_time,
                'end_time': end_time,
                'registration_deadline': registration_deadline,
                'location_id': location_id,
                'type_id': int(request.form['type_id']),
                'max_participants': int(request.form['max_participants']),
                'requirements': request.form.get('requirements', ''),
                'created_by': session['user_id']
            }
            
            system.add_activity(activity_data)
            flash('活动添加成功！', 'success')
            return redirect(url_for('admin_activities'))
        except Exception as e:
            flash(f'添加失败: {str(e)}', 'danger')
            return redirect(url_for('add_activity'))
    
    # 获取活动类型列表（已在模型层去重）
    activity_types = system.get_activity_types()
    
    return render_template('add_activity.html', activity_types=activity_types)

def _get_or_create_location(location_name):
    """查找或创建活动地点"""
    db = Database()
    try:
        # 先查找是否已存在该地点
        cursor = db.execute_query(
            "SELECT location_id FROM [Location] WHERE location_name = ?", 
            (location_name,)
        )
        result = cursor.fetchone()
        
        if result:
            return result.location_id
        
        # 如果不存在，则创建新地点
        db.execute_non_query(
            "INSERT INTO [Location] (location_name, address) VALUES (?, ?)", 
            (location_name, location_name)
        )
        
        # 获取新创建的地点ID
        cursor = db.execute_query(
            "SELECT location_id FROM [Location] WHERE location_name = ?", 
            (location_name,)
        )
        result = cursor.fetchone()
        return int(result.location_id)
    finally:
        if hasattr(db, 'conn') and db.conn:
            db.conn.commit()

#######################
# 活动报名相关路由
#######################

@app.route('/activities/register/<int:activity_id>', methods=['POST'])
def register_for_activity(activity_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    if session.get('user_type') != 0:  # 0代表志愿者
        flash('只有志愿者可以报名活动', 'danger')
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    # 检查用户是否已报名
    if system.check_user_registered(session['user_id'], activity_id):
        flash('您已报名此活动', 'info')
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    # 检查活动是否已满
    activity_row = system.get_activity_by_id(activity_id)
    if activity_row.registered_count >= activity_row.max_participants:
        flash('该活动名额已满', 'danger')
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    # 检查是否已过报名截止时间
    current_time = datetime.now()
    if activity_row.registration_deadline and current_time > activity_row.registration_deadline:
        flash('该活动已过报名截止时间', 'danger')
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    try:
        system.register_for_activity(
            user_id=session['user_id'],
            activity_id=activity_id
        )
        flash('报名成功！请等待审核', 'success')
    except Exception as e:
        flash(f'报名失败: {e}', 'danger')
    
    return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))

@app.route('/activities/cancel/<int:activity_id>', methods=['POST'])
def cancel_registration(activity_id):
    """取消活动报名"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    if session.get('user_type') != 0:  # 0代表志愿者
        flash('只有志愿者可以取消报名', 'danger')
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    # 检查用户是否已报名
    if not system.check_user_registered(session['user_id'], activity_id):
        flash('您尚未报名此活动', 'warning')
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    # 获取活动信息，检查活动是否已开始
    activity_row = system.get_activity_by_id(activity_id)
    current_time = datetime.now()
    
    # 如果活动已经开始，不允许取消报名
    if activity_row.start_time and current_time >= activity_row.start_time:
        flash('活动已开始，无法取消报名', 'danger')
        return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))
    
    try:
        system.cancel_registration(
            user_id=session['user_id'],
            activity_id=activity_id
        )
        flash('已成功取消报名', 'success')
    except Exception as e:
        flash(f'取消报名失败: {e}', 'danger')
    
    return redirect(url_for('activity_detail_volunteer', activity_id=activity_id))

#######################
# 评价管理相关路由
#######################

@app.route('/evaluate/<int:application_id>', methods=['GET', 'POST'])
def evaluate_application(application_id):
    if 'user_id' not in session or session.get('user_type') != 2:  # 2通常代表管理员/组织者
        flash('无权访问此页面', 'danger')
        return redirect(url_for('index_administrator'))
    
    application = system.get_application_by_id(application_id)
    
    if request.method == 'POST':
        try:
            actual_hours = float(request.form['actual_hours'])
            score = float(request.form['score'])
            comments = request.form.get('comments', '')
            
            system.evaluate_application(
                application_id=application_id,
                actual_hours=actual_hours,
                score=score,
                comments=comments,
                evaluated_by=session['user_id']
            )
            
            flash('评价成功！', 'success')
            return redirect(url_for('activity_detail', activity_id=application.activity_id))
        except Exception as e:
            flash(f'评价失败: {e}', 'danger')
    
    return render_template('evaluate_application.html', application=application)

#######################
# 个人中心相关路由
#######################

@app.route('/index_volunteer/profile')
def profile():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    user = system.get_user_by_id(session['user_id'])
    completed_activities = system.get_volunteer_completed_activities(session['user_id'])
    
    return render_template('profile.html', 
                         user=user, 
                         completed_activities=completed_activities)

@app.route('/register', methods=['GET', 'POST'])
def register_volunteer():
    if request.method == 'POST':
        try:
            username = request.form['username']
            password = request.form['password']
            real_name = request.form['real_name']
            gender = request.form['gender']
            phone = request.form['phone']
            email = request.form.get('email', '').strip()  # 获取邮箱并去除空白字符
            college_id = request.form['college_id']
            
            # 检查用户名是否已存在
            if system.get_user_by_username(username):
                flash('用户名已存在', 'danger')
                return redirect(url_for('register_volunteer'))
            
            # 检查密码确认
            if request.form['password'] != request.form['confirm_password']:
                flash('两次输入的密码不一致', 'danger')
                return redirect(url_for('register_volunteer'))
            
            # 创建新用户（默认为志愿者类型）- 使用明文密码
            system.add_volunteer(username, real_name, gender, phone, email if email else None)
            
            flash('注册成功！请登录', 'success')
            return redirect(url_for('login'))
            
        except Exception as e:
            flash(f'注册失败: {str(e)}', 'danger')
            return redirect(url_for('register_volunteer'))
    
    # 获取所有学院信息（已在模型层去重）
    colleges = system.get_colleges()
    
    return render_template('register_volunteer.html', colleges=colleges)

@app.route('/activities/<int:activity_id>/volunteers')
@admin_required
def activity_volunteers(activity_id):
    # 获取活动信息
    activity = system.get_activity_by_id(activity_id)
    if not activity:
        flash('活动不存在', 'danger')
        return redirect(url_for('activities'))
    
    # 获取该活动的所有志愿者
    volunteers = system.get_activity_volunteers(activity_id)
    
    return render_template('activity_volunteer.html', 
                         activity=activity,
                         volunteers=volunteers)

@app.route('/profile/edit', methods=['GET', 'POST'])
def edit_profile():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    user = system.get_user_by_id(session['user_id'])
    
    # 获取所有学院信息（已在模型层去重）
    colleges = system.get_colleges()
    
    if request.method == 'POST':
        try:
            # 获取表单数据
            real_name = request.form['real_name']
            email = request.form.get('email', '')
            phone = request.form['phone']
            gender = request.form['gender']
            college_id = request.form.get('college_id', '')
            
            # 表单验证
            if not real_name or not phone or not gender:
                flash('请填写所有必填字段', 'danger')
                return render_template('edit_profile.html', user=user, colleges=colleges)
            
            # 转换空字符串为None或适当的默认值
            if college_id == '':
                college_id = None
            
            # 更新用户资料
            system.update_user_profile(
                user_id=session['user_id'],
                real_name=real_name,
                email=email,
                phone=phone,
                gender=gender,
                college_id=college_id
            )
            
            flash('个人资料更新成功！', 'success')
            return redirect(url_for('profile'))
        except Exception as e:
            flash(f'更新失败: {str(e)}', 'danger')
            return render_template('edit_profile.html', user=user, colleges=colleges)
    
    return render_template('edit_profile.html', user=user, colleges=colleges)

@app.route('/admin/applications')
@admin_required
def manage_applications():
    # 获取所有待审核的报名
    pending_applications = system.get_pending_applications()
    return render_template('manage_applications.html', applications=pending_applications)

@app.route('/admin/applications/review/<int:application_id>', methods=['POST'])
@admin_required
def review_application(application_id):
    status = int(request.form['status'])
    comment = request.form.get('comment', '')
    
    try:
        system.review_application(
            application_id=application_id,
            status=status,
            reviewer_id=session['user_id'],
            comment=comment
        )
        flash('审核完成！', 'success')
    except Exception as e:
        flash(f'审核失败: {str(e)}', 'danger')
    
    return redirect(url_for('manage_applications'))

@app.route('/volunteer/activities')
def volunteer_activities():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    # 获取用户信息（用于显示总时长）
    user = system.get_user_by_id(session['user_id'])
    
    # 获取所有已报名活动
    registered_activities = system.get_volunteer_registered_activities(session['user_id'])
    
    # 根据活动状态分类
    upcoming_activities = []
    completed_activities = []
    
    for activity in registered_activities:
        # 只考虑申请已通过的活动
        if activity['application_status'] == 1:  # 1表示申请已通过
            if activity['activity_status'] in ['进行中', '已满员']:
                upcoming_activities.append(activity)
            elif activity['activity_status'] == '已结束':
                completed_activities.append(activity)
    
    return render_template('volunteer_activities.html', 
                          activities=registered_activities,
                          upcoming_activities=upcoming_activities,
                          completed_activities=completed_activities,
                          user=user)

@app.route('/volunteer/service_records')
def volunteer_service_records():
    """志愿者服务记录：查看已报名的未开始/已结束活动"""
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    if session.get('user_type') != 0:  # 确保只有志愿者可以访问
        flash('无权访问此页面', 'danger')
        return redirect(url_for('index_administrator'))
    
    # 获取未开始的活动
    upcoming_activities = system.get_volunteer_upcoming_activities(session['user_id'])
    
    # 获取已完成的活动
    completed_activities = system.get_volunteer_completed_activities(session['user_id'])
    
    return render_template('service_records.html',
                          upcoming_activities=upcoming_activities,
                          completed_activities=completed_activities)

if __name__ == '__main__':
    app.run(debug=True)