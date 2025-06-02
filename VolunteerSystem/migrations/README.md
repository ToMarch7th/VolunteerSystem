# 志愿者管理系统数据库迁移脚本

本目录包含了志愿者管理系统数据库的迁移脚本，用于确保数据库结构符合BCNF规范，并修复各种数据问题。

## 迁移脚本列表

1. `fix_email_constraint.sql` - 修复User表中email字段的唯一约束问题，允许NULL值
2. `add_gender_field.sql` - 添加gender字段并设置约束，确保数据类型一致性
3. `fix_location_duplicates.sql` - 修复Location表中的重复数据问题
4. `fix_organization_duplicates.sql` - 修复VolunteerOrganization表中的重复数据问题
5. `add_college_activitytype_constraints.sql` - 为College和ActivityType表添加唯一约束
6. `update_views_for_bcnf.sql` - 更新系统中的视图，确保与新的BCNF规范兼容
7. `run_all_migrations.sql` - 按正确顺序运行所有迁移脚本

## 使用方法

### 运行所有迁移脚本

要一次性运行所有迁移脚本，可以执行：

```sql
sqlcmd -S <服务器名称> -d Volunteer1 -i run_all_migrations.sql -o migration_log.txt
```

### 单独运行特定迁移脚本

如果只需要运行特定的迁移脚本，可以执行：

```sql
sqlcmd -S <服务器名称> -d Volunteer1 -i <脚本名称>.sql -o <脚本名称>_log.txt
```

## 迁移内容说明

### 1. 修复email唯一约束问题

- 删除现有的email唯一约束
- 将空字符串email转为NULL
- 创建新的允许NULL值的唯一索引

### 2. 添加gender字段

- 添加gender字段（TINYINT类型，0表示男，1表示女）
- 添加检查约束，确保值为0、1或NULL
- 更新现有数据，确保数据类型一致性
- 添加字段说明

### 3. 修复表中的重复数据

- 修复Location表中的重复数据
- 修复VolunteerOrganization表中的重复数据
- 为College和ActivityType表添加唯一约束

### 4. 更新视图

更新系统中的视图，确保与新的BCNF规范兼容：

- vw_UserProfile
- vw_ActivityWithStatus
- vw_ActivityDetails
- vw_VolunteerRegisteredActivities
- vw_ApplicationManagement
- vw_VolunteerStatistics
- vw_ActivityStatistics
- vw_VolunteerApplications

## 注意事项

- 在运行迁移脚本前，请确保已备份数据库
- 迁移脚本应按照上述顺序执行，以避免依赖问题
- 如果在执行过程中出现错误，请检查日志文件并解决问题后再继续 