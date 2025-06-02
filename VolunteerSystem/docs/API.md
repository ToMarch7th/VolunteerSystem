# 志愿者管理系统 API 文档

本文档描述了志愿者管理系统的主要API接口。

## 用户认证

### 登录

- **URL**: `/`
- **方法**: `POST`
- **描述**: 用户登录
- **参数**:
  - `username`: 用户名
  - `password`: 密码
- **返回**: 重定向到对应角色首页

### 登出

- **URL**: `/logout`
- **方法**: `GET`
- **描述**: 用户登出
- **返回**: 重定向到登录页面

## 志愿者管理

### 获取所有志愿者

- **URL**: `/volunteers`
- **方法**: `GET`
- **描述**: 获取所有志愿者列表
- **权限**: 管理员
- **返回**: 志愿者列表页面

### 添加志愿者

- **URL**: `/add_volunteer`
- **方法**: `POST`
- **描述**: 添加新志愿者
- **权限**: 管理员
- **参数**:
  - `username`: 用户名
  - `name`: 真实姓名
  - `gender`: 性别
  - `phone`: 电话
  - `email`: 电子邮箱（可选）
- **返回**: 重定向到志愿者列表

### 删除志愿者

- **URL**: `/delete_volunteer/<volunteer_id>`
- **方法**: `DELETE`
- **描述**: 删除志愿者
- **权限**: 管理员
- **参数**:
  - `volunteer_id`: 志愿者ID
- **返回**: JSON响应

## 活动管理

### 获取活动列表

- **URL**: `/activities`
- **方法**: `GET`
- **描述**: 获取所有活跃活动
- **返回**: 活动列表页面

### 添加活动

- **URL**: `/admin/activities/add`
- **方法**: `POST`
- **描述**: 添加新活动
- **权限**: 管理员
- **参数**:
  - `activity_name`: 活动名称
  - `location_name`: 活动地点
  - `start_time`: 开始时间
  - `end_time`: 结束时间
  - `registration_deadline`: 报名截止时间
  - `type_id`: 活动类型ID
  - `max_participants`: 最大参与人数
  - `requirements`: 参与要求（可选）
  - `description`: 活动描述（可选）
- **返回**: 重定向到活动列表

### 活动详情

- **URL**: `/activities/<activity_id>`
- **方法**: `GET`
- **描述**: 获取活动详情
- **参数**:
  - `activity_id`: 活动ID
- **返回**: 活动详情页面

## 报名管理

### 活动报名

- **URL**: `/activities/register/<activity_id>`
- **方法**: `POST`
- **描述**: 报名参加活动
- **权限**: 志愿者
- **参数**:
  - `activity_id`: 活动ID
- **返回**: 重定向到活动详情页面

### 取消报名

- **URL**: `/activities/cancel/<activity_id>`
- **方法**: `POST`
- **描述**: 取消活动报名
- **权限**: 志愿者
- **参数**:
  - `activity_id`: 活动ID
- **返回**: 重定向到活动详情页面

### 报名审核

- **URL**: `/admin/applications/review/<application_id>`
- **方法**: `POST`
- **描述**: 审核志愿者报名申请
- **权限**: 管理员
- **参数**:
  - `application_id`: 申请ID
  - `status`: 审核状态（1-通过，2-拒绝）
  - `comment`: 审核备注（可选）
- **返回**: 重定向到报名管理页面

## 服务记录

### 获取服务记录

- **URL**: `/volunteer/service_records`
- **方法**: `GET`
- **描述**: 获取志愿者服务记录
- **权限**: 志愿者
- **返回**: 服务记录页面

### 评价服务

- **URL**: `/evaluate/<application_id>`
- **方法**: `POST`
- **描述**: 评价志愿者服务
- **权限**: 管理员
- **参数**:
  - `application_id`: 申请ID
  - `actual_hours`: 实际服务时长
  - `score`: 评分
  - `comments`: 评价内容（可选）
- **返回**: 重定向到活动详情页面

## 个人资料

### 获取个人资料

- **URL**: `/index_volunteer/profile`
- **方法**: `GET`
- **描述**: 获取用户个人资料
- **返回**: 个人资料页面

### 编辑个人资料

- **URL**: `/profile/edit`
- **方法**: `POST`
- **描述**: 编辑个人资料
- **参数**:
  - `real_name`: 真实姓名
  - `email`: 电子邮箱（可选）
  - `phone`: 电话
  - `gender`: 性别
  - `college_id`: 学院ID（可选）
- **返回**: 重定向到个人资料页面 