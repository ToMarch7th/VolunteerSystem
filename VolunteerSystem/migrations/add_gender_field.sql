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
    
    -- 添加性别检查约束
    ALTER TABLE [User]
    ADD CONSTRAINT CK_User_Gender CHECK (gender IN (0, 1));
    
    PRINT '已成功添加gender字段';
END
ELSE
BEGIN
    PRINT 'gender字段已存在，无需添加';
END;
GO

-- 修改password字段长度以支持哈希密码
ALTER TABLE [User]
ALTER COLUMN password NVARCHAR(255) NOT NULL;
PRINT '已修改password字段长度为255';
GO

-- 添加gender字段说明
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'User' AND COLUMN_NAME = 'gender'
)
BEGIN
    EXEC sp_addextendedproperty 
        @name = N'MS_Description', 
        @value = N'性别：0-男，1-女', 
        @level0type = N'SCHEMA', @level0name = N'dbo', 
        @level1type = N'TABLE',  @level1name = N'User', 
        @level2type = N'COLUMN', @level2name = N'gender';
    
    PRINT '已添加gender字段说明';
END;
GO 