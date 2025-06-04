USE Volunteer1;
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