USE Volunteer1;
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