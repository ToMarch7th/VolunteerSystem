USE Volunteer1;
GO

PRINT '开始执行数据库迁移脚本...';
PRINT '----------------------------------------';
GO

-- 1. 修复email唯一约束问题
PRINT '1. 修复email唯一约束问题';
GO

-- 检查是否存在UQ_User_Email约束
IF EXISTS (
    SELECT name 
    FROM sys.key_constraints 
    WHERE [type] = 'UQ' AND [parent_object_id] = OBJECT_ID('User') AND name = 'UQ_User_Email'
)
BEGIN
    -- 删除现有的唯一约束
    ALTER TABLE [User] DROP CONSTRAINT UQ_User_Email;
    PRINT '已删除现有的email唯一约束';
END
GO

-- 检查是否存在UQ_User_Email索引
IF EXISTS (
    SELECT name 
    FROM sys.indexes 
    WHERE [name] = 'UQ_User_Email' AND [object_id] = OBJECT_ID('User')
)
BEGIN
    -- 删除现有的唯一索引
    DROP INDEX UQ_User_Email ON [User];
    PRINT '已删除现有的email唯一索引';
END
GO

-- 检查是否存在UQ_User_Email_v2索引
IF EXISTS (
    SELECT name 
    FROM sys.indexes 
    WHERE [name] = 'UQ_User_Email_v2' AND [object_id] = OBJECT_ID('User')
)
BEGIN
    -- 删除现有的唯一索引
    DROP INDEX UQ_User_Email_v2 ON [User];
    PRINT '已删除现有的email唯一索引v2';
END
GO

-- 将空字符串email转为NULL
UPDATE [User]
SET email = NULL
WHERE email = '';
PRINT '已将空字符串email转为NULL';
GO

-- 创建新的允许NULL值的唯一索引
CREATE UNIQUE NONCLUSTERED INDEX UQ_User_Email ON [User](email)
WHERE email IS NOT NULL;
PRINT '已创建新的email唯一索引，允许NULL值';
GO

PRINT '----------------------------------------';

-- 2. 添加和修复gender字段
PRINT '2. 添加和修复gender字段';
GO

-- 检查gender字段是否已存在
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'User' AND COLUMN_NAME = 'gender'
)
BEGIN
    -- 添加gender字段
    ALTER TABLE [User]
    ADD gender TINYINT NULL;
    
    PRINT '已添加gender字段';
END
ELSE
BEGIN
    PRINT 'gender字段已存在，无需添加';
END;
GO

-- 检查gender约束是否已存在
IF NOT EXISTS (
    SELECT name
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID('User') AND name = 'CHK_User_Gender'
)
BEGIN
    -- 添加性别检查约束
    ALTER TABLE [User]
    ADD CONSTRAINT CHK_User_Gender CHECK (gender IN (0, 1) OR gender IS NULL);
    
    PRINT '已添加gender字段检查约束';
END
ELSE
BEGIN
    PRINT 'gender字段检查约束已存在，无需添加';
END;
GO

-- 更新现有数据，确保数据类型一致性
UPDATE [User] SET gender = 0 WHERE gender = N'男' OR gender = N'0';
UPDATE [User] SET gender = 1 WHERE gender = N'女' OR gender = N'1';
PRINT '已更新现有gender数据为标准格式';
GO

-- 添加或更新gender字段说明
IF EXISTS (
    SELECT 1 
    FROM sys.extended_properties 
    WHERE major_id = OBJECT_ID('User') 
      AND minor_id = (SELECT column_id FROM sys.columns WHERE object_id = OBJECT_ID('User') AND name = 'gender')
      AND name = 'MS_Description'
)
BEGIN
    -- 更新现有说明
    EXEC sp_updateextendedproperty 
        @name = N'MS_Description', 
        @value = N'性别：0-男，1-女', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'User', 
        @level2type = N'COLUMN', @level2name = N'gender';
    
    PRINT '已更新gender字段说明';
END
ELSE
BEGIN
    -- 添加新说明
    EXEC sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'性别：0-男，1-女', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'User', 
        @level2type = N'COLUMN', @level2name = N'gender';
    
    PRINT '已添加gender字段说明';
END;
GO

-- 修改password字段长度以支持哈希密码
ALTER TABLE [User]
ALTER COLUMN password NVARCHAR(255) NOT NULL;
PRINT '已修改password字段长度为255';
GO

PRINT '----------------------------------------';

-- 3. 修复Location表中的重复数据
PRINT '3. 修复Location表中的重复数据';
GO

-- 1. 首先检查并显示重复的Location数据
SELECT location_name, address, COUNT(*) as duplicate_count
FROM Location
GROUP BY location_name, address
HAVING COUNT(*) > 1;
GO

-- 2. 创建临时表存储需要保留的记录
CREATE TABLE #TempLocation (
    location_id INT,
    location_name NVARCHAR(50),
    address NVARCHAR(100),
    keep_record BIT
);
GO

-- 3. 插入所有记录到临时表，并标记每组中第一条记录为保留
INSERT INTO #TempLocation
SELECT 
    location_id,
    location_name,
    address,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY location_name, address ORDER BY location_id) = 1 THEN 1
        ELSE 0
    END as keep_record
FROM Location;
GO

-- 4. 查看要删除的记录
SELECT * FROM #TempLocation WHERE keep_record = 0;
GO

-- 5. 检查是否有活动引用了要删除的位置
SELECT a.activity_id, a.activity_name, l.location_id, l.location_name, l.address
FROM Activity a
JOIN #TempLocation l ON a.location_id = l.location_id
WHERE l.keep_record = 0;
GO

-- 6. 更新活动引用到保留的位置记录
BEGIN TRANSACTION;

DECLARE @old_location_id INT;
DECLARE @new_location_id INT;
DECLARE @location_name NVARCHAR(50);
DECLARE @address NVARCHAR(100);

-- 创建游标遍历需要更新的位置
DECLARE location_cursor CURSOR FOR
SELECT 
    old.location_id as old_location_id,
    new.location_id as new_location_id,
    old.location_name,
    old.address
FROM #TempLocation old
JOIN #TempLocation new ON old.location_name = new.location_name AND old.address = new.address
WHERE old.keep_record = 0 AND new.keep_record = 1;

OPEN location_cursor;
FETCH NEXT FROM location_cursor INTO @old_location_id, @new_location_id, @location_name, @address;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 更新引用旧位置ID的活动
    UPDATE Activity
    SET location_id = @new_location_id
    WHERE location_id = @old_location_id;
    
    PRINT '已将使用位置ID ' + CAST(@old_location_id AS NVARCHAR) + ' (' + @location_name + ', ' + @address + ') 的活动更新为使用位置ID ' + CAST(@new_location_id AS NVARCHAR);
    
    FETCH NEXT FROM location_cursor INTO @old_location_id, @new_location_id, @location_name, @address;
END

CLOSE location_cursor;
DEALLOCATE location_cursor;

-- 7. 删除重复的位置记录
DELETE FROM Location
WHERE location_id IN (SELECT location_id FROM #TempLocation WHERE keep_record = 0);

PRINT '已删除重复的位置记录';

-- 8. 为Location表添加唯一约束
IF NOT EXISTS (
    SELECT name
    FROM sys.key_constraints
    WHERE name = 'UQ_Location_Name_Address' AND parent_object_id = OBJECT_ID('Location')
)
BEGIN
    ALTER TABLE Location
    ADD CONSTRAINT UQ_Location_Name_Address UNIQUE (location_name, address);
    
    PRINT '已添加位置名称和地址的唯一约束';
END
ELSE
BEGIN
    PRINT '位置名称和地址的唯一约束已存在';
END

COMMIT;
GO

-- 9. 删除临时表
DROP TABLE #TempLocation;
GO

PRINT '----------------------------------------';

-- 4. 修复VolunteerOrganization表中的重复数据
PRINT '4. 修复VolunteerOrganization表中的重复数据';
GO

-- 1. 首先检查并显示重复的组织数据
SELECT org_name, COUNT(*) as duplicate_count
FROM VolunteerOrganization
GROUP BY org_name
HAVING COUNT(*) > 1;
GO

-- 2. 创建临时表存储需要保留的记录
CREATE TABLE #TempOrganization (
    org_id INT,
    org_name NVARCHAR(50),
    keep_record BIT
);
GO

-- 3. 插入所有记录到临时表，并标记每组中第一条记录为保留
INSERT INTO #TempOrganization
SELECT 
    org_id,
    org_name,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY org_name ORDER BY org_id) = 1 THEN 1
        ELSE 0
    END as keep_record
FROM VolunteerOrganization;
GO

-- 4. 查看要删除的记录
SELECT vo.* 
FROM VolunteerOrganization vo
JOIN #TempOrganization t ON vo.org_id = t.org_id
WHERE t.keep_record = 0;
GO

-- 5. 检查是否有用户引用了要删除的组织
SELECT u.user_id, u.username, u.real_name, o.org_id, o.org_name
FROM [User] u
JOIN #TempOrganization o ON u.org_id = o.org_id
WHERE o.keep_record = 0;
GO

-- 6. 更新用户引用到保留的组织记录
BEGIN TRANSACTION;

DECLARE @old_org_id INT;
DECLARE @new_org_id INT;
DECLARE @org_name NVARCHAR(50);

-- 创建游标遍历需要更新的组织
DECLARE org_cursor CURSOR FOR
SELECT 
    old.org_id as old_org_id,
    new.org_id as new_org_id,
    old.org_name
FROM #TempOrganization old
JOIN #TempOrganization new ON old.org_name = new.org_name
WHERE old.keep_record = 0 AND new.keep_record = 1;

OPEN org_cursor;
FETCH NEXT FROM org_cursor INTO @old_org_id, @new_org_id, @org_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 更新引用旧组织ID的用户
    UPDATE [User]
    SET org_id = @new_org_id
    WHERE org_id = @old_org_id;
    
    PRINT '已将使用组织ID ' + CAST(@old_org_id AS NVARCHAR) + ' (' + @org_name + ') 的用户更新为使用组织ID ' + CAST(@new_org_id AS NVARCHAR);
    
    FETCH NEXT FROM org_cursor INTO @old_org_id, @new_org_id, @org_name;
END

CLOSE org_cursor;
DEALLOCATE org_cursor;

-- 7. 删除重复的组织记录
DELETE FROM VolunteerOrganization
WHERE org_id IN (SELECT org_id FROM #TempOrganization WHERE keep_record = 0);

PRINT '已删除重复的组织记录';

-- 8. 为VolunteerOrganization表添加唯一约束
IF NOT EXISTS (
    SELECT name
    FROM sys.key_constraints
    WHERE name = 'UQ_Organization_Name' AND parent_object_id = OBJECT_ID('VolunteerOrganization')
)
BEGIN
    ALTER TABLE VolunteerOrganization
    ADD CONSTRAINT UQ_Organization_Name UNIQUE (org_name);
    
    PRINT '已添加组织名称的唯一约束';
END
ELSE
BEGIN
    PRINT '组织名称的唯一约束已存在';
END

COMMIT;
GO

-- 9. 删除临时表
DROP TABLE #TempOrganization;
GO

PRINT '----------------------------------------';

-- 5. 为College和ActivityType表添加唯一约束
PRINT '5. 为College和ActivityType表添加唯一约束';
GO

-- 1. 检查College表中是否有重复的college_name
SELECT college_name, COUNT(*) as duplicate_count
FROM College
GROUP BY college_name
HAVING COUNT(*) > 1;
GO

-- 2. 如果有重复的college_name，需要先处理重复数据
-- 创建临时表存储需要保留的记录
CREATE TABLE #TempCollege (
    college_id INT,
    college_name NVARCHAR(50),
    keep_record BIT
);
GO

-- 插入所有记录到临时表，并标记每组中第一条记录为保留
INSERT INTO #TempCollege
SELECT 
    college_id,
    college_name,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY college_name ORDER BY college_id) = 1 THEN 1
        ELSE 0
    END as keep_record
FROM College;
GO

-- 查看要删除的记录
SELECT c.* 
FROM College c
JOIN #TempCollege t ON c.college_id = t.college_id
WHERE t.keep_record = 0;
GO

-- 检查是否有用户引用了要删除的学院
SELECT u.user_id, u.username, u.real_name, c.college_id, c.college_name
FROM [User] u
JOIN #TempCollege c ON u.college_id = c.college_id
WHERE c.keep_record = 0;
GO

-- 更新用户引用到保留的学院记录
BEGIN TRANSACTION;

DECLARE @old_college_id INT;
DECLARE @new_college_id INT;
DECLARE @college_name NVARCHAR(50);

-- 创建游标遍历需要更新的学院
DECLARE college_cursor CURSOR FOR
SELECT 
    old.college_id as old_college_id,
    new.college_id as new_college_id,
    old.college_name
FROM #TempCollege old
JOIN #TempCollege new ON old.college_name = new.college_name
WHERE old.keep_record = 0 AND new.keep_record = 1;

OPEN college_cursor;
FETCH NEXT FROM college_cursor INTO @old_college_id, @new_college_id, @college_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 更新引用旧学院ID的用户
    UPDATE [User]
    SET college_id = @new_college_id
    WHERE college_id = @old_college_id;
    
    PRINT '已将使用学院ID ' + CAST(@old_college_id AS NVARCHAR) + ' (' + @college_name + ') 的用户更新为使用学院ID ' + CAST(@new_college_id AS NVARCHAR);
    
    FETCH NEXT FROM college_cursor INTO @old_college_id, @new_college_id, @college_name;
END

CLOSE college_cursor;
DEALLOCATE college_cursor;

-- 删除重复的学院记录
DELETE FROM College
WHERE college_id IN (SELECT college_id FROM #TempCollege WHERE keep_record = 0);

-- 为College表添加唯一约束
IF NOT EXISTS (
    SELECT name
    FROM sys.key_constraints
    WHERE name = 'UQ_College_Name' AND parent_object_id = OBJECT_ID('College')
)
BEGIN
    ALTER TABLE College
    ADD CONSTRAINT UQ_College_Name UNIQUE (college_name);
    
    PRINT '已添加学院名称的唯一约束';
END
ELSE
BEGIN
    PRINT '学院名称的唯一约束已存在';
END

COMMIT;
GO

-- 删除临时表
DROP TABLE #TempCollege;
GO

-- 3. 检查ActivityType表中是否有重复的type_name
SELECT type_name, COUNT(*) as duplicate_count
FROM ActivityType
GROUP BY type_name
HAVING COUNT(*) > 1;
GO

-- 4. 如果有重复的type_name，需要先处理重复数据
-- 创建临时表存储需要保留的记录
CREATE TABLE #TempActivityType (
    type_id INT,
    type_name NVARCHAR(30),
    keep_record BIT
);
GO

-- 插入所有记录到临时表，并标记每组中第一条记录为保留
INSERT INTO #TempActivityType
SELECT 
    type_id,
    type_name,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY type_name ORDER BY type_id) = 1 THEN 1
        ELSE 0
    END as keep_record
FROM ActivityType;
GO

-- 查看要删除的记录
SELECT at.* 
FROM ActivityType at
JOIN #TempActivityType t ON at.type_id = t.type_id
WHERE t.keep_record = 0;
GO

-- 检查是否有活动引用了要删除的活动类型
SELECT a.activity_id, a.activity_name, t.type_id, t.type_name
FROM Activity a
JOIN #TempActivityType t ON a.type_id = t.type_id
WHERE t.keep_record = 0;
GO

-- 更新活动引用到保留的活动类型记录
BEGIN TRANSACTION;

DECLARE @old_type_id INT;
DECLARE @new_type_id INT;
DECLARE @type_name NVARCHAR(30);

-- 创建游标遍历需要更新的活动类型
DECLARE type_cursor CURSOR FOR
SELECT 
    old.type_id as old_type_id,
    new.type_id as new_type_id,
    old.type_name
FROM #TempActivityType old
JOIN #TempActivityType new ON old.type_name = new.type_name
WHERE old.keep_record = 0 AND new.keep_record = 1;

OPEN type_cursor;
FETCH NEXT FROM type_cursor INTO @old_type_id, @new_type_id, @type_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 更新引用旧活动类型ID的活动
    UPDATE Activity
    SET type_id = @new_type_id
    WHERE type_id = @old_type_id;
    
    PRINT '已将使用活动类型ID ' + CAST(@old_type_id AS NVARCHAR) + ' (' + @type_name + ') 的活动更新为使用活动类型ID ' + CAST(@new_type_id AS NVARCHAR);
    
    FETCH NEXT FROM type_cursor INTO @old_type_id, @new_type_id, @type_name;
END

CLOSE type_cursor;
DEALLOCATE type_cursor;

-- 删除重复的活动类型记录
DELETE FROM ActivityType
WHERE type_id IN (SELECT type_id FROM #TempActivityType WHERE keep_record = 0);

-- 为ActivityType表添加唯一约束
IF NOT EXISTS (
    SELECT name
    FROM sys.key_constraints
    WHERE name = 'UQ_ActivityType_Name' AND parent_object_id = OBJECT_ID('ActivityType')
)
BEGIN
    ALTER TABLE ActivityType
    ADD CONSTRAINT UQ_ActivityType_Name UNIQUE (type_name);
    
    PRINT '已添加活动类型名称的唯一约束';
END
ELSE
BEGIN
    PRINT '活动类型名称的唯一约束已存在';
END

COMMIT;
GO

-- 删除临时表
DROP TABLE #TempActivityType;
GO

PRINT '----------------------------------------';

-- 6. 更新系统中的视图
PRINT '6. 更新系统中的视图';
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

-- 更新其他视图...
-- 此处省略其他视图更新代码，可以根据需要添加

PRINT '----------------------------------------';
PRINT '所有数据库迁移脚本执行完成！';
GO 