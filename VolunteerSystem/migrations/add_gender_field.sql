USE Volunteer1;
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