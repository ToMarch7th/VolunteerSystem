USE Volunteer1;
GO

-- 第一步：查询实际存在的约束名称
SELECT name 
FROM sys.key_constraints 
WHERE [type] = 'UQ' AND [parent_object_id] = OBJECT_ID('User');
GO

-- 第二步：根据查询结果删除现有约束
-- 注意：执行前请先查看上一步的结果，并替换下面的约束名
-- 如果找不到约束，可能是因为约束是以索引形式存在，则查询索引
SELECT name 
FROM sys.indexes 
WHERE [is_unique] = 1 AND [object_id] = OBJECT_ID('User') AND [name] LIKE 'UQ%';
GO

-- 删除现有索引或约束
-- 执行前需要替换实际的约束/索引名
-- DROP INDEX [约束名] ON [User];
-- 或
-- ALTER TABLE [User] DROP CONSTRAINT [约束名];

-- 第三步：创建新的允许NULL值的唯一索引
-- 检查是否已存在该索引
IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE [name] = 'UQ_User_Email_v2' AND [object_id] = OBJECT_ID('User')
)
BEGIN
    -- 创建新的唯一索引，允许NULL值
    CREATE UNIQUE NONCLUSTERED INDEX UQ_User_Email_v2 
    ON [User](email)
    WHERE email IS NOT NULL;
    
    PRINT '已创建新的email唯一索引，允许NULL值';
END
ELSE
BEGIN
    PRINT '索引UQ_User_Email_v2已存在，无需创建';
END;
GO

-- 第四步：修复已有的NULL或空字符串email
-- 将空字符串转为NULL
UPDATE [User]
SET email = NULL
WHERE email = '';

PRINT '已将空字符串email转为NULL';
GO 