USE Volunteer1;
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