USE Volunteer1;
GO

-- 更新用户个人资料视图，确保正确处理gender字段
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_UserProfile')
BEGIN
    DROP VIEW vw_UserProfile;
    PRINT '已删除旧的用户个人资料视图';
END
GO

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
PRINT '已创建更新的用户个人资料视图';

-- 更新活动查询视图，确保正确处理活动状态
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_ActivityWithStatus')
BEGIN
    DROP VIEW vw_ActivityWithStatus;
    PRINT '已删除旧的活动查询视图';
END
GO

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
PRINT '已创建更新的活动查询视图';

-- 更新活动详情视图，确保正确处理活动状态
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_ActivityDetails')
BEGIN
    DROP VIEW vw_ActivityDetails;
    PRINT '已删除旧的活动详情视图';
END
GO

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
PRINT '已创建更新的活动详情视图';

-- 更新志愿者已报名活动视图，确保正确处理活动和申请状态
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_VolunteerRegisteredActivities')
BEGIN
    DROP VIEW vw_VolunteerRegisteredActivities;
    PRINT '已删除旧的志愿者已报名活动视图';
END
GO

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
PRINT '已创建更新的志愿者已报名活动视图';

-- 更新报名管理视图，确保包含必要的字段
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_ApplicationManagement')
BEGIN
    DROP VIEW vw_ApplicationManagement;
    PRINT '已删除旧的报名管理视图';
END
GO

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
PRINT '已创建更新的报名管理视图';

-- 更新志愿者统计视图，确保正确关联学院表
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_VolunteerStatistics')
BEGIN
    DROP VIEW vw_VolunteerStatistics;
    PRINT '已删除旧的志愿者统计视图';
END
GO

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
PRINT '已创建更新的志愿者统计视图';

-- 更新活动统计视图，确保正确关联地点和活动类型表
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_ActivityStatistics')
BEGIN
    DROP VIEW vw_ActivityStatistics;
    PRINT '已删除旧的活动统计视图';
END
GO

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
PRINT '已创建更新的活动统计视图';

-- 更新志愿者申请状态视图
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_VolunteerApplications')
BEGIN
    DROP VIEW vw_VolunteerApplications;
    PRINT '已删除旧的志愿者申请状态视图';
END
GO

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
PRINT '已创建更新的志愿者申请状态视图';
GO 