-- 使用已存在的 Volunteer1 数据库
USE Volunteer1;
GO

-- 创建学院表
CREATE TABLE College (
    college_id INT PRIMARY KEY IDENTITY(1,1),
    college_name NVARCHAR(50) NOT NULL,
    description NVARCHAR(200),
    CONSTRAINT UQ_College_Name UNIQUE (college_name)
);
GO

-- 创建义工组织表
CREATE TABLE VolunteerOrganization (
    org_id INT PRIMARY KEY IDENTITY(1,1),
    org_name NVARCHAR(50) NOT NULL,
    description NVARCHAR(200),
    contact_person NVARCHAR(20),
    contact_phone NVARCHAR(15),
    CONSTRAINT UQ_Organization_Name UNIQUE (org_name)
);
GO

-- 创建用户表（包含志愿者和管理员）
CREATE TABLE [User] (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username NVARCHAR(30) NOT NULL UNIQUE,
    password NVARCHAR(255) NOT NULL, -- 增加长度以支持哈希密码
    real_name NVARCHAR(20) NOT NULL,
    email NVARCHAR(50) NULL, -- 允许为NULL
    phone NVARCHAR(15),
    college_id INT REFERENCES College(college_id),
    org_id INT REFERENCES VolunteerOrganization(org_id),
    user_type TINYINT NOT NULL DEFAULT 0, -- 0:志愿者, 1:管理员
    total_hours DECIMAL(5,1) DEFAULT 0, -- 累计服务时长
    average_score DECIMAL(3,1) DEFAULT 0, -- 平均服务得分
    register_time DATETIME DEFAULT GETDATE(),
    last_login_time DATETIME,
    gender TINYINT NULL, -- 0:男, 1:女
    CONSTRAINT CHK_User_Gender CHECK (gender IN (0, 1) OR gender IS NULL),
    CONSTRAINT CHK_User_Type CHECK (user_type IN (0, 1))
);
GO

-- 为email添加唯一约束，但允许NULL值
CREATE UNIQUE NONCLUSTERED INDEX UQ_User_Email ON [User](email)
WHERE email IS NOT NULL;
GO

-- 添加gender字段说明
EXEC sp_addextendedproperty 
    @name=N'MS_Description', 
    @value=N'性别：0-男，1-女', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE', @level1name=N'User', 
    @level2type=N'COLUMN', @level2name=N'gender';
GO

-- 创建地点表
CREATE TABLE Location (
    location_id INT PRIMARY KEY IDENTITY(1,1),
    location_name NVARCHAR(50) NOT NULL,
    address NVARCHAR(100) NOT NULL,
    capacity INT,
    description NVARCHAR(200),
    CONSTRAINT UQ_Location_Name_Address UNIQUE (location_name, address)
);
GO

-- 创建活动类型表
CREATE TABLE ActivityType (
    type_id INT PRIMARY KEY IDENTITY(1,1),
    type_name NVARCHAR(30) NOT NULL,
    description NVARCHAR(200),
    CONSTRAINT UQ_ActivityType_Name UNIQUE (type_name)
);
GO

-- 创建活动表
CREATE TABLE Activity (
    activity_id INT PRIMARY KEY IDENTITY(1,1),
    activity_name NVARCHAR(50) NOT NULL,
    description NVARCHAR(500),
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    registration_deadline DATETIME NOT NULL,
    location_id INT REFERENCES Location(location_id),
    type_id INT REFERENCES ActivityType(type_id),
    max_participants INT NOT NULL,
    current_participants INT DEFAULT 0,
    requirements NVARCHAR(200),
    status TINYINT DEFAULT 1, -- 0:已结束, 1:招募中, 2:已满员
    created_by INT REFERENCES [User](user_id) NOT NULL,
    created_time DATETIME DEFAULT GETDATE(),
    updated_time DATETIME,
    CONSTRAINT CHK_Activity_Status CHECK (status IN (0, 1, 2)),
    CONSTRAINT CHK_Activity_Time CHECK (end_time > start_time),
    CONSTRAINT CHK_Registration_Deadline CHECK (registration_deadline <= start_time)
);
GO

-- 创建申请表
CREATE TABLE Application (
    application_id INT PRIMARY KEY IDENTITY(1,1),
    activity_id INT REFERENCES Activity(activity_id) NOT NULL,
    volunteer_id INT REFERENCES [User](user_id) NOT NULL,
    application_time DATETIME NOT NULL,
    status TINYINT DEFAULT 0, -- 0:待审核, 1:已通过, 2:已拒绝
    reviewed_by INT REFERENCES [User](user_id),
    review_time DATETIME,
    review_comment NVARCHAR(200),
    CONSTRAINT UC_Application UNIQUE (activity_id, volunteer_id),
    CONSTRAINT CHK_Application_Status CHECK (status IN (0, 1, 2))
);
GO

-- 创建服务评价表
CREATE TABLE ServiceEvaluation (
    evaluation_id INT PRIMARY KEY IDENTITY(1,1),
    application_id INT REFERENCES Application(application_id) NOT NULL,
    actual_hours DECIMAL(4,1) NOT NULL,
    score DECIMAL(3,1) NOT NULL, -- 0-10分
    comments NVARCHAR(500),
    evaluated_by INT REFERENCES [User](user_id) NOT NULL,
    evaluation_time DATETIME DEFAULT GETDATE(),
    CONSTRAINT CHK_Score CHECK (score >= 0 AND score <= 10),
    CONSTRAINT CHK_Hours CHECK (actual_hours > 0),
    CONSTRAINT UC_ServiceEvaluation UNIQUE (application_id)
);
GO

-- 创建触发器1：自动设置申请时间为当前时间
CREATE TRIGGER trg_SetApplicationTime
ON Application
FOR INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE a
    SET a.application_time = GETDATE()
    FROM Application a
    INNER JOIN inserted i ON a.application_id = i.application_id
    WHERE a.application_time IS NULL;
END;
GO

-- 创建触发器2：新增服务评价后自动更新志愿者的累计服务时长和平均服务得分
CREATE TRIGGER trg_UpdateVolunteerStats
ON ServiceEvaluation
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 更新志愿者的累计服务时长和平均服务得分
    UPDATE u
    SET 
        total_hours = u.total_hours + i.actual_hours,
        average_score = CASE 
                            WHEN u.total_hours = 0 THEN i.score
                            ELSE (u.total_hours * u.average_score + i.actual_hours * i.score) / (u.total_hours + i.actual_hours)
                        END
    FROM [User] u
    JOIN Application a ON u.user_id = a.volunteer_id
    JOIN inserted i ON a.application_id = i.application_id;
END;
GO

-- 创建触发器3：申请通过后自动更新活动当前参与人数
CREATE TRIGGER trg_UpdateActivityParticipants
ON Application
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 如果申请状态从非1变为1（通过审核），增加活动参与人数
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.application_id = d.application_id 
               WHERE i.status = 1 AND (d.status <> 1 OR d.status IS NULL))
    BEGIN
        UPDATE a
        SET 
            current_participants = current_participants + 1,
            -- 如果达到最大参与人数，将状态更新为已满员
            status = CASE 
                        WHEN current_participants + 1 >= max_participants THEN 2 
                        ELSE status 
                     END
        FROM Activity a
        JOIN inserted i ON a.activity_id = i.activity_id
        WHERE i.status = 1;
    END
    
    -- 如果申请状态从1变为非1（取消通过），减少活动参与人数
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.application_id = d.application_id 
               WHERE d.status = 1 AND i.status <> 1)
    BEGIN
        UPDATE a
        SET 
            current_participants = current_participants - 1,
            -- 如果从已满员状态减少参与人数，将状态更新为招募中
            status = CASE 
                        WHEN status = 2 AND current_participants - 1 < max_participants THEN 1 
                        ELSE status 
                     END
        FROM Activity a
        JOIN inserted i ON a.activity_id = i.activity_id
        WHERE i.status <> 1 AND a.current_participants > 0;
    END
END;
GO

-- 创建活动状态更新触发器：自动关闭已过期的活动
CREATE TRIGGER trg_UpdateActivityStatus
ON Activity
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 更新已过期的活动状态
    UPDATE Activity
    SET status = 0 -- 已结束
    WHERE end_time < GETDATE() AND status <> 0;
END;
GO

-- 创建索引以提高查询性能
CREATE INDEX idx_activity_status ON Activity(status);
GO
CREATE INDEX idx_activity_time ON Activity(start_time, end_time);
GO
CREATE INDEX idx_application_status ON Application(status);
GO
CREATE INDEX idx_application_activity ON Application(activity_id);
GO
CREATE INDEX idx_application_volunteer ON Application(volunteer_id);
GO
CREATE INDEX idx_user_type ON [User](user_type);
GO

-- 创建视图：用户个人资料视图
CREATE VIEW vw_UserProfile AS
SELECT 
    u.user_id,
    u.username,
    u.real_name,
    u.email,
    u.phone,
    CASE u.gender 
        WHEN 0 THEN '男'
        WHEN 1 THEN '女'
        ELSE '未知'
    END AS gender_name,
    u.gender, -- 保留原始的数值类型以便于程序处理
    c.college_name,
    o.org_name,
    u.total_hours,
    u.average_score,
    u.register_time,
    u.last_login_time
FROM [User] u
LEFT JOIN College c ON u.college_id = c.college_id
LEFT JOIN VolunteerOrganization o ON u.org_id = o.org_id;
GO

-- 创建视图：活动查询视图
CREATE VIEW vw_ActivityWithStatus AS
SELECT 
    a.*,
    l.location_name,
    l.address,
    at.type_name,
    CASE a.status
        WHEN 0 THEN '已结束'
        WHEN 1 THEN '进行中'
        WHEN 2 THEN '已满员'
        ELSE '未知'
    END AS status_text,
    (SELECT COUNT(*) FROM Application ap WHERE ap.activity_id = a.activity_id) AS registered_count,
    (SELECT COUNT(*) FROM Application ap WHERE ap.activity_id = a.activity_id AND ap.status = 1) AS approved_count
FROM Activity a
JOIN Location l ON a.location_id = l.location_id
JOIN ActivityType at ON a.type_id = at.type_id;
GO

-- 创建视图：活动详情视图
CREATE VIEW vw_ActivityDetails AS
SELECT 
    a.activity_id,
    a.activity_name,
    a.description,
    a.start_time,
    a.end_time,
    a.registration_deadline,
    l.location_name,
    l.address,
    at.type_name AS activity_type,
    a.max_participants,
    a.current_participants,
    a.requirements,
    CASE a.status 
        WHEN 0 THEN '已结束'
        WHEN 1 THEN '招募中'
        WHEN 2 THEN '已满员'
        ELSE '未知'
    END AS status_text,
    a.status, -- 保留原始的数值类型以便于程序处理
    u.real_name AS created_by,
    a.created_time
FROM Activity a
JOIN Location l ON a.location_id = l.location_id
JOIN ActivityType at ON a.type_id = at.type_id
JOIN [User] u ON a.created_by = u.user_id;
GO

-- 创建视图：志愿者已报名活动视图
CREATE VIEW vw_VolunteerRegisteredActivities AS
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
    CASE a.status
        WHEN 0 THEN '待审核'
        WHEN 1 THEN '已通过'
        WHEN 2 THEN '已拒绝'
        ELSE '未知'
    END AS application_status,
    a.status AS application_status_code,
    a.review_comment,
    a.review_time,
    CASE act.status
        WHEN 0 THEN '已结束'
        WHEN 1 THEN '进行中'
        WHEN 2 THEN '已满员'
        ELSE '未知'
    END AS activity_status,
    act.status AS activity_status_code
FROM Application a
JOIN Activity act ON a.activity_id = act.activity_id
JOIN Location l ON act.location_id = l.location_id
JOIN ActivityType at ON act.type_id = at.type_id;
GO

-- 创建视图：志愿者申请状态视图
CREATE VIEW vw_VolunteerApplications AS
SELECT 
    app.application_id,
    a.activity_id,
    a.activity_name,
    u.user_id AS volunteer_id,
    u.real_name AS volunteer_name,
    app.application_time,
    CASE app.status
        WHEN 0 THEN '待审核'
        WHEN 1 THEN '已通过'
        WHEN 2 THEN '已拒绝'
        ELSE '未知'
    END AS status_text,
    app.status,
    app.review_comment,
    app.review_time,
    reviewer.real_name AS reviewer_name
FROM Application app
JOIN Activity a ON app.activity_id = a.activity_id
JOIN [User] u ON app.volunteer_id = u.user_id
LEFT JOIN [User] reviewer ON app.reviewed_by = reviewer.user_id;
GO

-- 创建视图：报名管理视图
CREATE VIEW vw_ApplicationManagement AS
SELECT 
    a.application_id,
    a.activity_id,
    act.activity_name,
    act.start_time,
    act.end_time,
    u.user_id AS volunteer_id,
    u.real_name AS volunteer_name,
    u.phone AS volunteer_phone,
    u.email AS volunteer_email,
    CASE u.gender 
        WHEN 0 THEN '男'
        WHEN 1 THEN '女'
        ELSE '未知'
    END AS volunteer_gender,
    a.application_time,
    CASE a.status
        WHEN 0 THEN '待审核'
        WHEN 1 THEN '已通过'
        WHEN 2 THEN '已拒绝'
        ELSE '未知'
    END AS status_text,
    a.status,
    a.review_time,
    a.review_comment,
    admin.real_name AS reviewer_name
FROM Application a
JOIN Activity act ON a.activity_id = act.activity_id
JOIN [User] u ON a.volunteer_id = u.user_id
LEFT JOIN [User] admin ON a.reviewed_by = admin.user_id;
GO

-- 创建视图：志愿者统计视图
CREATE VIEW vw_VolunteerStatistics AS
SELECT
    u.user_id,
    u.real_name,
    u.username,
    u.total_hours,
    u.average_score,
    c.college_name,
    CASE u.gender 
        WHEN 0 THEN '男'
        WHEN 1 THEN '女'
        ELSE '未知'
    END AS gender_name,
    (SELECT COUNT(*) FROM Application a WHERE a.volunteer_id = u.user_id) AS total_applications,
    (SELECT COUNT(*) FROM Application a WHERE a.volunteer_id = u.user_id AND a.status = 1) AS approved_applications,
    (SELECT COUNT(*) FROM ServiceEvaluation se 
     JOIN Application a ON se.application_id = a.application_id 
     WHERE a.volunteer_id = u.user_id) AS evaluations_count
FROM [User] u
LEFT JOIN College c ON u.college_id = c.college_id
WHERE u.user_type = 0;
GO

-- 创建视图：活动统计视图
CREATE VIEW vw_ActivityStatistics AS
SELECT
    a.activity_id,
    a.activity_name,
    a.start_time,
    a.end_time,
    at.type_name,
    l.location_name,
    l.address,
    a.max_participants,
    a.current_participants,
    CASE a.status
        WHEN 0 THEN '已结束'
        WHEN 1 THEN '进行中'
        WHEN 2 THEN '已满员'
        ELSE '未知'
    END AS status_text,
    a.status,
    (SELECT COUNT(*) FROM Application app WHERE app.activity_id = a.activity_id) AS total_applications,
    (SELECT COUNT(*) FROM Application app WHERE app.activity_id = a.activity_id AND app.status = 1) AS approved_applications,
    (SELECT AVG(se.score) FROM ServiceEvaluation se 
     JOIN Application app ON se.application_id = app.application_id 
     WHERE app.activity_id = a.activity_id) AS average_score,
    (SELECT SUM(se.actual_hours) FROM ServiceEvaluation se 
     JOIN Application app ON se.application_id = app.application_id 
     WHERE app.activity_id = a.activity_id) AS total_service_hours
FROM Activity a
JOIN ActivityType at ON a.type_id = at.type_id
JOIN Location l ON a.location_id = l.location_id;
GO

-- 创建存储过程：修改个人资料
CREATE PROCEDURE sp_UpdateUserProfile
    @user_id INT,
    @real_name NVARCHAR(20),
    @email NVARCHAR(50),
    @phone NVARCHAR(15),
    @gender TINYINT,
    @college_id INT
AS
BEGIN
    -- 如果email为空字符串，则设为NULL
    IF @email = '' SET @email = NULL;
    
    UPDATE [User]
    SET 
        real_name = @real_name,
        email = @email,
        phone = @phone,
        gender = @gender,
        college_id = @college_id
    WHERE user_id = @user_id;
END;
GO

-- 创建存储过程：审核志愿者申请
CREATE PROCEDURE sp_ReviewApplication
    @application_id INT,
    @status TINYINT,
    @review_comment NVARCHAR(200),
    @reviewed_by INT
AS
BEGIN
    UPDATE Application
    SET 
        status = @status,
        review_comment = @review_comment,
        reviewed_by = @reviewed_by,
        review_time = GETDATE()
    WHERE application_id = @application_id;
END;
GO

-- 创建存储过程：评价志愿者服务
CREATE PROCEDURE sp_EvaluateService
    @application_id INT,
    @actual_hours DECIMAL(4,1),
    @score DECIMAL(3,1),
    @comments NVARCHAR(500),
    @evaluated_by INT
AS
BEGIN
    -- 检查是否已有评价
    IF EXISTS (SELECT 1 FROM ServiceEvaluation WHERE application_id = @application_id)
    BEGIN
        UPDATE ServiceEvaluation
        SET 
            actual_hours = @actual_hours,
            score = @score,
            comments = @comments,
            evaluated_by = @evaluated_by,
            evaluation_time = GETDATE()
        WHERE application_id = @application_id;
    END
    ELSE
    BEGIN
        INSERT INTO ServiceEvaluation (application_id, actual_hours, score, comments, evaluated_by)
        VALUES (@application_id, @actual_hours, @score, @comments, @evaluated_by);
    END
END;
GO