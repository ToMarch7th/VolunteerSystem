USE Volunteer1;
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