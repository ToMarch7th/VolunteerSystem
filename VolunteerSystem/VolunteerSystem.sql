USE [master]
GO
/****** Object:  Database [Volunteer1]    Script Date: 2025/6/1 16:45:27 ******/
CREATE DATABASE [Volunteer1]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Volunteer1', FILENAME = N'D:\DCdownload\Microsoft SQL Server\MSSQL16.SQL\MSSQL\DATA\Volunteer1.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Volunteer1_log', FILENAME = N'D:\DCdownload\Microsoft SQL Server\MSSQL16.SQL\MSSQL\DATA\Volunteer1_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [Volunteer1] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Volunteer1].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Volunteer1] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Volunteer1] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Volunteer1] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Volunteer1] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Volunteer1] SET ARITHABORT OFF 
GO
ALTER DATABASE [Volunteer1] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Volunteer1] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Volunteer1] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Volunteer1] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Volunteer1] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Volunteer1] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Volunteer1] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Volunteer1] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Volunteer1] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Volunteer1] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Volunteer1] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Volunteer1] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Volunteer1] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Volunteer1] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Volunteer1] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Volunteer1] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Volunteer1] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Volunteer1] SET RECOVERY FULL 
GO
ALTER DATABASE [Volunteer1] SET  MULTI_USER 
GO
ALTER DATABASE [Volunteer1] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Volunteer1] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Volunteer1] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Volunteer1] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Volunteer1] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [Volunteer1] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'Volunteer1', N'ON'
GO
ALTER DATABASE [Volunteer1] SET QUERY_STORE = ON
GO
ALTER DATABASE [Volunteer1] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [Volunteer1]
GO
/****** Object:  UserDefinedFunction [dbo].[HashPassword]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 创建计算密码哈希的函数
CREATE FUNCTION [dbo].[HashPassword] (@password NVARCHAR(50))
RETURNS NVARCHAR(100)
AS
BEGIN
    -- 使用SHA2_256算法加盐哈希
    DECLARE @salt NVARCHAR(16) = 'RandomSaltValue'; -- 应该使用每个用户唯一的盐值
    DECLARE @hashedPassword NVARCHAR(100);
    
    SET @hashedPassword = CONVERT(NVARCHAR(100), HASHBYTES('SHA2_256', @password + @salt), 2);
    
    RETURN @hashedPassword;
END;
GO
/****** Object:  Table [dbo].[College]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[College](
	[college_id] [int] IDENTITY(1,1) NOT NULL,
	[college_name] [nvarchar](50) NOT NULL,
	[description] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[college_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[VolunteerOrganization]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VolunteerOrganization](
	[org_id] [int] IDENTITY(1,1) NOT NULL,
	[org_name] [nvarchar](50) NOT NULL,
	[description] [nvarchar](200) NULL,
	[contact_person] [nvarchar](20) NULL,
	[contact_phone] [nvarchar](15) NULL,
PRIMARY KEY CLUSTERED 
(
	[org_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[User]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[User](
	[user_id] [int] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](30) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[real_name] [nvarchar](20) NOT NULL,
	[email] [nvarchar](50) NULL,
	[phone] [nvarchar](15) NULL,
	[college_id] [int] NULL,
	[org_id] [int] NULL,
	[user_type] [tinyint] NOT NULL,
	[total_hours] [decimal](5, 1) NULL,
	[average_score] [decimal](3, 1) NULL,
	[register_time] [datetime] NULL,
	[last_login_time] [datetime] NULL,
	[gender] [tinyint] NULL,
PRIMARY KEY CLUSTERED 
(
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_UserProfile]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 创建用户个人资料视图
CREATE VIEW [dbo].[vw_UserProfile] AS
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
/****** Object:  Table [dbo].[Location]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Location](
	[location_id] [int] IDENTITY(1,1) NOT NULL,
	[location_name] [nvarchar](50) NOT NULL,
	[address] [nvarchar](100) NOT NULL,
	[capacity] [int] NULL,
	[description] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[location_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ActivityType]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityType](
	[type_id] [int] IDENTITY(1,1) NOT NULL,
	[type_name] [nvarchar](30) NOT NULL,
	[description] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[type_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Activity]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Activity](
	[activity_id] [int] IDENTITY(1,1) NOT NULL,
	[activity_name] [nvarchar](50) NOT NULL,
	[description] [nvarchar](500) NULL,
	[start_time] [datetime] NOT NULL,
	[end_time] [datetime] NOT NULL,
	[registration_deadline] [datetime] NOT NULL,
	[location_id] [int] NULL,
	[type_id] [int] NULL,
	[max_participants] [int] NOT NULL,
	[current_participants] [int] NULL,
	[requirements] [nvarchar](200) NULL,
	[status] [tinyint] NULL,
	[created_by] [int] NOT NULL,
	[created_time] [datetime] NULL,
	[updated_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[activity_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Application]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Application](
	[application_id] [int] IDENTITY(1,1) NOT NULL,
	[activity_id] [int] NOT NULL,
	[volunteer_id] [int] NOT NULL,
	[application_time] [datetime] NOT NULL,
	[status] [tinyint] NULL,
	[reviewed_by] [int] NULL,
	[review_time] [datetime] NULL,
	[review_comment] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[application_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_ActivityWithStatus]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 创建活动查询视图，包括活动状态文本
CREATE VIEW [dbo].[vw_ActivityWithStatus] AS
SELECT 
    a.*,
    l.location_name,
    at.type_name,
    CASE a.status
        WHEN 0 THEN '已结束'
        WHEN 1 THEN '进行中'
        WHEN 2 THEN '已满员'
        ELSE '未知'
    END AS status_text,
    (SELECT COUNT(*) FROM Application ap WHERE ap.activity_id = a.activity_id) AS registered_count
FROM Activity a
JOIN Location l ON a.location_id = l.location_id
JOIN ActivityType at ON a.type_id = at.type_id;

GO
/****** Object:  View [dbo].[vw_ApplicationManagement]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建报名管理视图
CREATE VIEW [dbo].[vw_ApplicationManagement] AS
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
    a.application_time,
    CASE a.status
        WHEN 0 THEN '待审核'
        WHEN 1 THEN '已通过'
        WHEN 2 THEN '已拒绝'
    END AS status_text,
    a.status,
    a.review_time,
    admin.real_name AS reviewer_name
FROM Application a
JOIN Activity act ON a.activity_id = act.activity_id
JOIN [User] u ON a.volunteer_id = u.user_id
LEFT JOIN [User] admin ON a.reviewed_by = admin.user_id;

GO
/****** Object:  View [dbo].[vw_VolunteerRegisteredActivities]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建志愿者已报名活动视图
CREATE VIEW [dbo].[vw_VolunteerRegisteredActivities] AS
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
    END AS application_status,
    a.status AS application_status_code,
    a.review_comment,
    a.review_time,
    CASE act.status
        WHEN 0 THEN '已结束'
        WHEN 1 THEN '进行中'
        WHEN 2 THEN '已满员'
        ELSE '未知'
    END AS activity_status
FROM Application a
JOIN Activity act ON a.activity_id = act.activity_id
JOIN Location l ON act.location_id = l.location_id
JOIN ActivityType at ON act.type_id = at.type_id;

GO
/****** Object:  Table [dbo].[ServiceEvaluation]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServiceEvaluation](
	[evaluation_id] [int] IDENTITY(1,1) NOT NULL,
	[application_id] [int] NOT NULL,
	[actual_hours] [decimal](4, 1) NOT NULL,
	[score] [decimal](3, 1) NOT NULL,
	[comments] [nvarchar](500) NULL,
	[evaluated_by] [int] NOT NULL,
	[evaluation_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[evaluation_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_VolunteerStatistics]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建报告管理相关视图
CREATE VIEW [dbo].[vw_VolunteerStatistics] AS
SELECT
    u.user_id,
    u.real_name,
    u.username,
    u.total_hours,
    u.average_score,
    c.college_name,
    (SELECT COUNT(*) FROM Application a WHERE a.volunteer_id = u.user_id) AS total_applications,
    (SELECT COUNT(*) FROM Application a WHERE a.volunteer_id = u.user_id AND a.status = 1) AS approved_applications,
    (SELECT COUNT(*) FROM ServiceEvaluation se 
     JOIN Application a ON se.application_id = a.application_id 
     WHERE a.volunteer_id = u.user_id) AS evaluations_count
FROM [User] u
LEFT JOIN College c ON u.college_id = c.college_id
WHERE u.user_type = 0;

GO
/****** Object:  View [dbo].[vw_ActivityStatistics]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建活动统计视图
CREATE VIEW [dbo].[vw_ActivityStatistics] AS
SELECT
    a.activity_id,
    a.activity_name,
    a.start_time,
    a.end_time,
    at.type_name,
    l.location_name,
    a.max_participants,
    a.current_participants,
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
/****** Object:  View [dbo].[vw_ActivityDetails]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建视图：活动详情视图
CREATE VIEW [dbo].[vw_ActivityDetails] AS
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
        WHEN 2 THEN '已取消'
    END AS status,
    u.real_name AS created_by,
    a.created_time
FROM Activity a
JOIN Location l ON a.location_id = l.location_id
JOIN ActivityType at ON a.type_id = at.type_id
JOIN [User] u ON a.created_by = u.user_id;
GO
/****** Object:  View [dbo].[vw_VolunteerApplications]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建视图：志愿者申请状态视图
CREATE VIEW [dbo].[vw_VolunteerApplications] AS
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
    END AS status,
    app.review_comment,
    app.review_time,
    reviewer.real_name AS reviewer_name
FROM Application app
JOIN Activity a ON app.activity_id = a.activity_id
JOIN [User] u ON app.volunteer_id = u.user_id
LEFT JOIN [User] reviewer ON app.reviewed_by = reviewer.user_id;
GO
SET IDENTITY_INSERT [dbo].[Activity] ON 

INSERT [dbo].[Activity] ([activity_id], [activity_name], [description], [start_time], [end_time], [registration_deadline], [location_id], [type_id], [max_participants], [current_participants], [requirements], [status], [created_by], [created_time], [updated_time]) VALUES (1, N'社区清洁行动', N'为社区环境贡献力量，清理社区公共区域垃圾，美化社区环境。', CAST(N'2025-06-06T15:37:33.707' AS DateTime), CAST(N'2025-06-06T19:37:33.707' AS DateTime), CAST(N'2025-06-04T15:37:33.707' AS DateTime), 2, 2, 20, 2, N'请穿着舒适的衣服和鞋子，自备水和零食。', 1, 1, CAST(N'2025-05-30T15:37:33.707' AS DateTime), NULL)
INSERT [dbo].[Activity] ([activity_id], [activity_name], [description], [start_time], [end_time], [registration_deadline], [location_id], [type_id], [max_participants], [current_participants], [requirements], [status], [created_by], [created_time], [updated_time]) VALUES (2, N'希望小学支教活动', N'前往希望小学开展支教活动，为孩子们带去知识和欢乐。', CAST(N'2025-06-13T15:37:33.707' AS DateTime), CAST(N'2025-06-14T15:37:33.707' AS DateTime), CAST(N'2025-06-09T15:37:33.707' AS DateTime), 4, 3, 10, 2, N'有教学经验者优先，请准备一份简单的课程计划。', 1, 1, CAST(N'2025-05-30T15:37:33.707' AS DateTime), NULL)
INSERT [dbo].[Activity] ([activity_id], [activity_name], [description], [start_time], [end_time], [registration_deadline], [location_id], [type_id], [max_participants], [current_participants], [requirements], [status], [created_by], [created_time], [updated_time]) VALUES (3, N'校园马拉松志愿者', N'为校园马拉松比赛提供志愿服务，包括引导、补给站服务等。', CAST(N'2025-06-20T15:37:33.707' AS DateTime), CAST(N'2025-06-20T23:37:33.707' AS DateTime), CAST(N'2025-06-17T15:37:33.707' AS DateTime), 1, 4, 30, 1, N'需要有一定体力，能够长时间站立。将提供志愿者服装和午餐。', 1, 2, CAST(N'2025-05-30T15:37:33.707' AS DateTime), NULL)
INSERT [dbo].[Activity] ([activity_id], [activity_name], [description], [start_time], [end_time], [registration_deadline], [location_id], [type_id], [max_participants], [current_participants], [requirements], [status], [created_by], [created_time], [updated_time]) VALUES (4, N'图书馆整理活动', N'帮助学校图书馆整理图书、清点库存。', CAST(N'2025-05-20T15:37:33.733' AS DateTime), CAST(N'2025-05-20T20:37:33.733' AS DateTime), CAST(N'2025-05-15T15:37:33.733' AS DateTime), 1, 1, 15, 1, N'需要有耐心和细心，能够按照图书分类方法整理图书。', 0, 1, CAST(N'2025-05-10T15:37:33.733' AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[Activity] OFF
GO
SET IDENTITY_INSERT [dbo].[ActivityType] ON 

INSERT [dbo].[ActivityType] ([type_id], [type_name], [description]) VALUES (1, N'社区服务', N'为社区提供各种志愿服务')
INSERT [dbo].[ActivityType] ([type_id], [type_name], [description]) VALUES (2, N'环境保护', N'环保宣传、清洁活动等')
INSERT [dbo].[ActivityType] ([type_id], [type_name], [description]) VALUES (3, N'教育支持', N'支教、辅导等教育活动')
INSERT [dbo].[ActivityType] ([type_id], [type_name], [description]) VALUES (4, N'大型活动', N'大型赛事、会议等志愿服务')
SET IDENTITY_INSERT [dbo].[ActivityType] OFF
GO
SET IDENTITY_INSERT [dbo].[Application] ON 

INSERT [dbo].[Application] ([application_id], [activity_id], [volunteer_id], [application_time], [status], [reviewed_by], [review_time], [review_comment]) VALUES (1, 1, 3, CAST(N'2025-05-30T15:37:33.717' AS DateTime), 1, NULL, NULL, NULL)
INSERT [dbo].[Application] ([application_id], [activity_id], [volunteer_id], [application_time], [status], [reviewed_by], [review_time], [review_comment]) VALUES (2, 1, 4, CAST(N'2025-05-30T15:37:33.717' AS DateTime), 1, 1, CAST(N'2025-05-31T22:18:34.650' AS DateTime), N'')
INSERT [dbo].[Application] ([application_id], [activity_id], [volunteer_id], [application_time], [status], [reviewed_by], [review_time], [review_comment]) VALUES (3, 2, 3, CAST(N'2025-05-30T15:37:33.717' AS DateTime), 1, NULL, NULL, NULL)
INSERT [dbo].[Application] ([application_id], [activity_id], [volunteer_id], [application_time], [status], [reviewed_by], [review_time], [review_comment]) VALUES (4, 3, 5, CAST(N'2025-05-30T15:37:33.717' AS DateTime), 1, NULL, NULL, NULL)
INSERT [dbo].[Application] ([application_id], [activity_id], [volunteer_id], [application_time], [status], [reviewed_by], [review_time], [review_comment]) VALUES (5, 4, 3, CAST(N'2025-05-12T15:37:33.733' AS DateTime), 1, 1, CAST(N'2025-05-13T15:37:33.733' AS DateTime), NULL)
INSERT [dbo].[Application] ([application_id], [activity_id], [volunteer_id], [application_time], [status], [reviewed_by], [review_time], [review_comment]) VALUES (6, 2, 17, CAST(N'2025-05-31T22:44:43.253' AS DateTime), 1, 1, CAST(N'2025-05-31T22:45:06.573' AS DateTime), N'')
INSERT [dbo].[Application] ([application_id], [activity_id], [volunteer_id], [application_time], [status], [reviewed_by], [review_time], [review_comment]) VALUES (7, 4, 17, CAST(N'2025-05-31T22:50:22.360' AS DateTime), 2, 1, CAST(N'2025-05-31T22:52:40.020' AS DateTime), N'已过截止时间')
SET IDENTITY_INSERT [dbo].[Application] OFF
GO
SET IDENTITY_INSERT [dbo].[College] ON 

INSERT [dbo].[College] ([college_id], [college_name], [description]) VALUES (1, N'计算机学院', N'计算机科学与技术、软件工程等专业')
INSERT [dbo].[College] ([college_id], [college_name], [description]) VALUES (2, N'经济管理学院', N'经济学、管理学、金融学等专业')
INSERT [dbo].[College] ([college_id], [college_name], [description]) VALUES (3, N'外国语学院', N'英语、日语、法语等专业')
INSERT [dbo].[College] ([college_id], [college_name], [description]) VALUES (4, N'艺术学院', N'音乐、美术、设计等专业')
SET IDENTITY_INSERT [dbo].[College] OFF
GO
SET IDENTITY_INSERT [dbo].[Location] ON 

INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (1, N'学校大礼堂', N'第一教学楼旁', 500, N'可举办大型活动')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (2, N'社区活动中心', N'阳光社区内', 200, N'社区活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (3, N'城市公园', N'市中心人民公园', 1000, N'户外活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (4, N'希望小学', N'城郊希望小学', 300, N'支教活动地点')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (5, N'学校大礼堂', N'第一教学楼旁', 500, N'可举办大型活动')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (6, N'社区活动中心', N'阳光社区内', 200, N'社区活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (7, N'城市公园', N'市中心人民公园', 1000, N'户外活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (8, N'希望小学', N'城郊希望小学', 300, N'支教活动地点')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (9, N'学校大礼堂', N'第一教学楼旁', 500, N'可举办大型活动')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (10, N'社区活动中心', N'阳光社区内', 200, N'社区活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (11, N'城市公园', N'市中心人民公园', 1000, N'户外活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (12, N'希望小学', N'城郊希望小学', 300, N'支教活动地点')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (13, N'学校大礼堂', N'第一教学楼旁', 500, N'可举办大型活动')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (14, N'社区活动中心', N'阳光社区内', 200, N'社区活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (15, N'城市公园', N'市中心人民公园', 1000, N'户外活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (16, N'希望小学', N'城郊希望小学', 300, N'支教活动地点')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (17, N'学校大礼堂', N'第一教学楼旁', 500, N'可举办大型活动')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (18, N'社区活动中心', N'阳光社区内', 200, N'社区活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (19, N'城市公园', N'市中心人民公园', 1000, N'户外活动场所')
INSERT [dbo].[Location] ([location_id], [location_name], [address], [capacity], [description]) VALUES (20, N'希望小学', N'城郊希望小学', 300, N'支教活动地点')
SET IDENTITY_INSERT [dbo].[Location] OFF
GO
SET IDENTITY_INSERT [dbo].[ServiceEvaluation] ON 

INSERT [dbo].[ServiceEvaluation] ([evaluation_id], [application_id], [actual_hours], [score], [comments], [evaluated_by], [evaluation_time]) VALUES (1, 5, CAST(5.0 AS Decimal(4, 1)), CAST(9.5 AS Decimal(3, 1)), N'表现优秀，认真负责，能够主动解决问题，与团队协作良好。', 1, CAST(N'2025-05-21T15:37:33.733' AS DateTime))
SET IDENTITY_INSERT [dbo].[ServiceEvaluation] OFF
GO
SET IDENTITY_INSERT [dbo].[User] ON 

INSERT [dbo].[User] ([user_id], [username], [password], [real_name], [email], [phone], [college_id], [org_id], [user_type], [total_hours], [average_score], [register_time], [last_login_time], [gender]) VALUES (1, N'admin1', N'admin123', N'系统管理员', N'admin1@school.edu', N'13800138111', NULL, NULL, 1, CAST(0.0 AS Decimal(5, 1)), CAST(0.0 AS Decimal(3, 1)), CAST(N'2025-05-30T15:03:41.433' AS DateTime), CAST(N'2025-06-01T16:20:07.453' AS DateTime), NULL)
INSERT [dbo].[User] ([user_id], [username], [password], [real_name], [email], [phone], [college_id], [org_id], [user_type], [total_hours], [average_score], [register_time], [last_login_time], [gender]) VALUES (2, N'org_admin1', N'orgadmin123', N'组织管理员', N'orgadmin1@school.edu', N'13800138222', 1, 1, 1, CAST(0.0 AS Decimal(5, 1)), CAST(0.0 AS Decimal(3, 1)), CAST(N'2025-05-30T15:03:41.433' AS DateTime), NULL, NULL)
INSERT [dbo].[User] ([user_id], [username], [password], [real_name], [email], [phone], [college_id], [org_id], [user_type], [total_hours], [average_score], [register_time], [last_login_time], [gender]) VALUES (3, N'volunteer1', N'vol123', N'张三', N'zhangsan@school.edu', N'13800138333', 1, 1, 0, CAST(5.0 AS Decimal(5, 1)), CAST(9.5 AS Decimal(3, 1)), CAST(N'2025-05-30T15:03:41.437' AS DateTime), NULL, NULL)
INSERT [dbo].[User] ([user_id], [username], [password], [real_name], [email], [phone], [college_id], [org_id], [user_type], [total_hours], [average_score], [register_time], [last_login_time], [gender]) VALUES (4, N'volunteer2', N'vol123', N'李四', N'lisi@school.edu', N'13800138444', 2, 2, 0, CAST(0.0 AS Decimal(5, 1)), CAST(0.0 AS Decimal(3, 1)), CAST(N'2025-05-30T15:03:41.437' AS DateTime), NULL, NULL)
INSERT [dbo].[User] ([user_id], [username], [password], [real_name], [email], [phone], [college_id], [org_id], [user_type], [total_hours], [average_score], [register_time], [last_login_time], [gender]) VALUES (5, N'volunteer3', N'vol123', N'王五', N'wangwu@school.edu', N'13800138555', 3, 3, 0, CAST(0.0 AS Decimal(5, 1)), CAST(0.0 AS Decimal(3, 1)), CAST(N'2025-05-30T15:03:41.437' AS DateTime), NULL, NULL)
INSERT [dbo].[User] ([user_id], [username], [password], [real_name], [email], [phone], [college_id], [org_id], [user_type], [total_hours], [average_score], [register_time], [last_login_time], [gender]) VALUES (17, N'admin', N'123456', N'huali', NULL, N'15280706818', NULL, NULL, 0, CAST(0.0 AS Decimal(5, 1)), CAST(0.0 AS Decimal(3, 1)), CAST(N'2025-05-31T20:18:59.967' AS DateTime), CAST(N'2025-06-01T16:19:34.053' AS DateTime), N'0')
INSERT [dbo].[User] ([user_id], [username], [password], [real_name], [email], [phone], [college_id], [org_id], [user_type], [total_hours], [average_score], [register_time], [last_login_time], [gender]) VALUES (22, N'admin2', N'706817', N'hualii', N'', N'15280706817', NULL, NULL, 0, CAST(0.0 AS Decimal(5, 1)), CAST(0.0 AS Decimal(3, 1)), CAST(N'2025-05-31T21:22:32.637' AS DateTime), NULL, N'男')
SET IDENTITY_INSERT [dbo].[User] OFF
GO
SET IDENTITY_INSERT [dbo].[VolunteerOrganization] ON 

INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (1, N'青年志愿者协会', N'校级志愿者组织', N'张明', N'13800138001')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (2, N'爱心社', N'专注于社区服务的志愿者组织', N'李华', N'13800138002')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (3, N'环保协会', N'致力于环境保护的志愿者组织', N'王芳', N'13800138003')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (4, N'青年志愿者协会', N'校级志愿者组织', N'张明', N'13800138001')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (5, N'爱心社', N'专注于社区服务的志愿者组织', N'李华', N'13800138002')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (6, N'环保协会', N'致力于环境保护的志愿者组织', N'王芳', N'13800138003')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (7, N'青年志愿者协会', N'校级志愿者组织', N'张明', N'13800138001')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (8, N'爱心社', N'专注于社区服务的志愿者组织', N'李华', N'13800138002')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (9, N'环保协会', N'致力于环境保护的志愿者组织', N'王芳', N'13800138003')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (10, N'青年志愿者协会', N'校级志愿者组织', N'张明', N'13800138001')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (11, N'爱心社', N'专注于社区服务的志愿者组织', N'李华', N'13800138002')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (12, N'环保协会', N'致力于环境保护的志愿者组织', N'王芳', N'13800138003')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (13, N'青年志愿者协会', N'校级志愿者组织', N'张明', N'13800138001')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (14, N'爱心社', N'专注于社区服务的志愿者组织', N'李华', N'13800138002')
INSERT [dbo].[VolunteerOrganization] ([org_id], [org_name], [description], [contact_person], [contact_phone]) VALUES (15, N'环保协会', N'致力于环境保护的志愿者组织', N'王芳', N'13800138003')
SET IDENTITY_INSERT [dbo].[VolunteerOrganization] OFF
GO
/****** Object:  Index [idx_activity_status]    Script Date: 2025/6/1 16:45:27 ******/
CREATE NONCLUSTERED INDEX [idx_activity_status] ON [dbo].[Activity]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_activity_time]    Script Date: 2025/6/1 16:45:27 ******/
CREATE NONCLUSTERED INDEX [idx_activity_time] ON [dbo].[Activity]
(
	[start_time] ASC,
	[end_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UC_Application]    Script Date: 2025/6/1 16:45:27 ******/
ALTER TABLE [dbo].[Application] ADD  CONSTRAINT [UC_Application] UNIQUE NONCLUSTERED 
(
	[activity_id] ASC,
	[volunteer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_application_activity]    Script Date: 2025/6/1 16:45:27 ******/
CREATE NONCLUSTERED INDEX [idx_application_activity] ON [dbo].[Application]
(
	[activity_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_application_status]    Script Date: 2025/6/1 16:45:27 ******/
CREATE NONCLUSTERED INDEX [idx_application_status] ON [dbo].[Application]
(
	[status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_application_volunteer]    Script Date: 2025/6/1 16:45:27 ******/
CREATE NONCLUSTERED INDEX [idx_application_volunteer] ON [dbo].[Application]
(
	[volunteer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [idx_user_type]    Script Date: 2025/6/1 16:45:27 ******/
CREATE NONCLUSTERED INDEX [idx_user_type] ON [dbo].[User]
(
	[user_type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_User_Email]    Script Date: 2025/6/1 16:45:27 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_User_Email] ON [dbo].[User]
(
	[email] ASC
)
WHERE ([email] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_User_Email_v2]    Script Date: 2025/6/1 16:45:27 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_User_Email_v2] ON [dbo].[User]
(
	[email] ASC
)
WHERE ([email] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Activity] ADD  DEFAULT ((0)) FOR [current_participants]
GO
ALTER TABLE [dbo].[Activity] ADD  DEFAULT ((1)) FOR [status]
GO
ALTER TABLE [dbo].[Activity] ADD  DEFAULT (getdate()) FOR [created_time]
GO
ALTER TABLE [dbo].[Application] ADD  DEFAULT ((0)) FOR [status]
GO
ALTER TABLE [dbo].[ServiceEvaluation] ADD  DEFAULT (getdate()) FOR [evaluation_time]
GO
ALTER TABLE [dbo].[User] ADD  DEFAULT ((0)) FOR [user_type]
GO
ALTER TABLE [dbo].[User] ADD  DEFAULT ((0)) FOR [total_hours]
GO
ALTER TABLE [dbo].[User] ADD  DEFAULT ((0)) FOR [average_score]
GO
ALTER TABLE [dbo].[User] ADD  DEFAULT (getdate()) FOR [register_time]
GO
ALTER TABLE [dbo].[Activity]  WITH CHECK ADD FOREIGN KEY([created_by])
REFERENCES [dbo].[User] ([user_id])
GO
ALTER TABLE [dbo].[Activity]  WITH CHECK ADD FOREIGN KEY([location_id])
REFERENCES [dbo].[Location] ([location_id])
GO
ALTER TABLE [dbo].[Activity]  WITH CHECK ADD FOREIGN KEY([type_id])
REFERENCES [dbo].[ActivityType] ([type_id])
GO
ALTER TABLE [dbo].[Application]  WITH CHECK ADD FOREIGN KEY([activity_id])
REFERENCES [dbo].[Activity] ([activity_id])
GO
ALTER TABLE [dbo].[Application]  WITH CHECK ADD FOREIGN KEY([reviewed_by])
REFERENCES [dbo].[User] ([user_id])
GO
ALTER TABLE [dbo].[Application]  WITH CHECK ADD FOREIGN KEY([volunteer_id])
REFERENCES [dbo].[User] ([user_id])
GO
ALTER TABLE [dbo].[ServiceEvaluation]  WITH CHECK ADD FOREIGN KEY([application_id])
REFERENCES [dbo].[Application] ([application_id])
GO
ALTER TABLE [dbo].[ServiceEvaluation]  WITH CHECK ADD FOREIGN KEY([evaluated_by])
REFERENCES [dbo].[User] ([user_id])
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD FOREIGN KEY([college_id])
REFERENCES [dbo].[College] ([college_id])
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD FOREIGN KEY([org_id])
REFERENCES [dbo].[VolunteerOrganization] ([org_id])
GO
ALTER TABLE [dbo].[ServiceEvaluation]  WITH CHECK ADD  CONSTRAINT [CHK_Hours] CHECK  (([actual_hours]>(0)))
GO
ALTER TABLE [dbo].[ServiceEvaluation] CHECK CONSTRAINT [CHK_Hours]
GO
ALTER TABLE [dbo].[ServiceEvaluation]  WITH CHECK ADD  CONSTRAINT [CHK_Score] CHECK  (([score]>=(0) AND [score]<=(10)))
GO
ALTER TABLE [dbo].[ServiceEvaluation] CHECK CONSTRAINT [CHK_Score]
GO
/****** Object:  StoredProcedure [dbo].[sp_DeleteActivity]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建活动删除存储过程
CREATE PROCEDURE [dbo].[sp_DeleteActivity]
    @activity_id INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 删除活动相关的评价
        DELETE FROM ServiceEvaluation 
        WHERE application_id IN (
            SELECT application_id 
            FROM Application 
            WHERE activity_id = @activity_id
        );
        
        -- 删除活动的报名
        DELETE FROM Application 
        WHERE activity_id = @activity_id;
        
        -- 删除活动
        DELETE FROM Activity 
        WHERE activity_id = @activity_id;
        
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetActivityRegistrationStats]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 创建获取活动报名统计信息的存储过程
CREATE PROCEDURE [dbo].[sp_GetActivityRegistrationStats]
    @activity_id INT
AS
BEGIN
    SELECT
        (SELECT COUNT(*) FROM Application WHERE activity_id = @activity_id) AS total_registrations,
        (SELECT COUNT(*) FROM Application WHERE activity_id = @activity_id AND status = 0) AS pending_count,
        (SELECT COUNT(*) FROM Application WHERE activity_id = @activity_id AND status = 1) AS approved_count,
        (SELECT COUNT(*) FROM Application WHERE activity_id = @activity_id AND status = 2) AS rejected_count;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_RegisterForActivity]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 创建报名活动的存储过程
CREATE PROCEDURE [dbo].[sp_RegisterForActivity]
    @volunteer_id INT,
    @activity_id INT
AS
BEGIN
    -- 检查是否已存在报名
    IF EXISTS (SELECT 1 FROM Application WHERE volunteer_id = @volunteer_id AND activity_id = @activity_id)
    BEGIN
        THROW 50001, '您已经报名了此活动', 1;
        RETURN;
    END
    
    -- 检查活动状态
    DECLARE @activity_status TINYINT, @max_participants INT, @current_participants INT, @deadline DATETIME;
    SELECT 
        @activity_status = status, 
        @max_participants = max_participants, 
        @current_participants = current_participants,
        @deadline = registration_deadline
    FROM Activity
    WHERE activity_id = @activity_id;
    
    IF @activity_status = 0
    BEGIN
        THROW 50002, '该活动已结束', 1;
        RETURN;
    END
    
    IF @activity_status = 2
    BEGIN
        THROW 50003, '该活动已满员', 1;
        RETURN;
    END
    
    IF GETDATE() > @deadline
    BEGIN
        THROW 50004, '该活动报名已截止', 1;
        RETURN;
    END
    
    -- 创建报名记录
    INSERT INTO Application (activity_id, volunteer_id, application_time, status)
    VALUES (@activity_id, @volunteer_id, GETDATE(), 0);
    
    -- 不立即更新当前参与人数，等待审核通过后再更新
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_ReviewApplication]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建审核报名的存储过程
CREATE PROCEDURE [dbo].[sp_ReviewApplication]
    @application_id INT,
    @status TINYINT,
    @reviewer_id INT,
    @review_comment NVARCHAR(200)
AS
BEGIN
    UPDATE Application
    SET 
        status = @status,
        reviewed_by = @reviewer_id,
        review_time = GETDATE(),
        review_comment = @review_comment
    WHERE application_id = @application_id;
    
    -- 如果批准了报名，更新活动的当前参与人数
    IF @status = 1
    BEGIN
        DECLARE @activity_id INT;
        SELECT @activity_id = activity_id FROM Application WHERE application_id = @application_id;
        
        UPDATE Activity
        SET current_participants = current_participants + 1
        WHERE activity_id = @activity_id;
        
        -- 检查是否已满员，如果满员则更新状态
        UPDATE Activity
        SET status = 2
        WHERE activity_id = @activity_id 
          AND current_participants >= max_participants;
    END
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateUserProfile]    Script Date: 2025/6/1 16:45:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 创建修改个人资料的存储过程
CREATE PROCEDURE [dbo].[sp_UpdateUserProfile]
    @user_id INT,
    @real_name NVARCHAR(20),
    @email NVARCHAR(50),
    @phone NVARCHAR(15),
    @gender TINYINT,
    @college_id INT
AS
BEGIN
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
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'性别：0-男，1-女' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'User', @level2type=N'COLUMN',@level2name=N'gender'
GO
USE [master]
GO
ALTER DATABASE [Volunteer1] SET  READ_WRITE 
GO

-- 修改Location表结构，添加唯一约束确保符合BCNF
USE [Volunteer1]
GO

-- 1. 首先删除依赖于Location表的外键约束
ALTER TABLE [dbo].[Activity] DROP CONSTRAINT FK__Activity__locati__4BAC3F29
GO

-- 2. 删除重复的Location数据，只保留每个location_name和address组合的第一条记录
WITH CTE AS (
    SELECT location_id, location_name, address,
           ROW_NUMBER() OVER (PARTITION BY location_name, address ORDER BY location_id) AS rn
    FROM [dbo].[Location]
)
DELETE FROM CTE WHERE rn > 1
GO

-- 3. 为Location表添加唯一约束，确保location_name和address的组合是唯一的
ALTER TABLE [dbo].[Location] ADD CONSTRAINT UQ_Location_Name_Address UNIQUE (location_name, address)
GO

-- 4. 重新建立外键约束
ALTER TABLE [dbo].[Activity] ADD CONSTRAINT FK__Activity__locati__4BAC3F29 FOREIGN KEY (location_id)
REFERENCES [dbo].[Location] (location_id)
GO

-- 修改VolunteerOrganization表，添加唯一约束确保符合BCNF
-- 1. 首先删除依赖于VolunteerOrganization表的外键约束
ALTER TABLE [dbo].[User] DROP CONSTRAINT FK__User__org_id__3C69FB99
GO

-- 2. 删除重复的VolunteerOrganization数据，只保留每个org_name的第一条记录
WITH CTE AS (
    SELECT org_id, org_name,
           ROW_NUMBER() OVER (PARTITION BY org_name ORDER BY org_id) AS rn
    FROM [dbo].[VolunteerOrganization]
)
DELETE FROM CTE WHERE rn > 1
GO

-- 3. 为VolunteerOrganization表添加唯一约束，确保org_name是唯一的
ALTER TABLE [dbo].[VolunteerOrganization] ADD CONSTRAINT UQ_Organization_Name UNIQUE (org_name)
GO

-- 4. 重新建立外键约束
ALTER TABLE [dbo].[User] ADD CONSTRAINT FK__User__org_id__3C69FB99 FOREIGN KEY (org_id)
REFERENCES [dbo].[VolunteerOrganization] (org_id)
GO

-- 修改User表中的gender字段，确保数据类型一致性
-- 1. 修改gender字段为tinyint类型
ALTER TABLE [dbo].[User] ALTER COLUMN gender tinyint NULL
GO

-- 2. 更新现有数据
UPDATE [dbo].[User] SET gender = 0 WHERE gender = N'男' OR gender = N'0'
GO
UPDATE [dbo].[User] SET gender = 1 WHERE gender = N'女' OR gender = N'1'
GO

-- 3. 添加检查约束，确保gender只能是0或1
ALTER TABLE [dbo].[User] ADD CONSTRAINT CHK_User_Gender CHECK (gender IN (0, 1) OR gender IS NULL)
GO

-- 更新视图以适应新的数据结构
ALTER VIEW [dbo].[vw_UserProfile] AS
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

-- 更新扩展属性说明
EXEC sys.sp_updateextendedproperty 
    @name=N'MS_Description', 
    @value=N'性别：0-男，1-女', 
    @level0type=N'SCHEMA', @level0name=N'dbo', 
    @level1type=N'TABLE', @level1name=N'User', 
    @level2type=N'COLUMN', @level2name=N'gender'
GO

-- 为College表添加唯一约束，确保college_name是唯一的
ALTER TABLE [dbo].[College] ADD CONSTRAINT UQ_College_Name UNIQUE (college_name)
GO

-- 为ActivityType表添加唯一约束，确保type_name是唯一的
ALTER TABLE [dbo].[ActivityType] ADD CONSTRAINT UQ_ActivityType_Name UNIQUE (type_name)
GO
