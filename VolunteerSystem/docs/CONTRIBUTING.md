# 志愿者管理系统贡献指南

感谢您对志愿者管理系统的关注！本文档将指导您如何为项目做出贡献。

## 目录

- [行为准则](#行为准则)
- [开发环境设置](#开发环境设置)
- [代码风格](#代码风格)
- [提交流程](#提交流程)
- [问题报告](#问题报告)
- [功能请求](#功能请求)
- [文档贡献](#文档贡献)
- [测试](#测试)
- [许可证](#许可证)

## 行为准则

我们希望所有贡献者都能遵守以下准则：

- 尊重每一位项目参与者
- 接受建设性的批评
- 专注于项目的最佳利益
- 展示同理心和友善

## 开发环境设置

1. Fork项目仓库
2. 克隆您的Fork到本地
   ```bash
   git clone https://github.com/YOUR-USERNAME/VolunteerSystem.git
   cd VolunteerSystem
   ```
3. 设置上游远程仓库
   ```bash
   git remote add upstream https://github.com/ORIGINAL-OWNER/VolunteerSystem.git
   ```
4. 创建虚拟环境并安装依赖
   ```bash
   python -m venv venv
   source venv/bin/activate  # 在Windows上使用 venv\Scripts\activate
   pip install -r requirements.txt
   ```
5. 设置数据库（参见[安装指南](INSTALL.md)）

## 代码风格

我们使用以下代码风格规范：

### Python代码

- 遵循[PEP 8](https://www.python.org/dev/peps/pep-0008/)风格指南
- 使用4个空格进行缩进（不使用制表符）
- 每行最大长度为79个字符
- 使用有意义的变量名和函数名
- 添加适当的文档字符串

示例：

```python
def calculate_total_hours(volunteer_id):
    """
    计算志愿者的总服务时长
    
    Args:
        volunteer_id: 志愿者ID
        
    Returns:
        float: 总服务时长（小时）
    """
    # 实现代码
    pass
```

### HTML/CSS代码

- 使用2个空格进行缩进
- 使用小写标签和属性名
- 使用双引号包裹属性值
- 保持代码整洁和一致的缩进

### JavaScript代码

- 使用2个空格进行缩进
- 使用分号结束语句
- 使用有意义的变量名
- 避免全局变量

## 提交流程

1. 确保您的分支与最新的上游代码同步
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. 创建新的功能分支
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. 进行更改并提交
   ```bash
   git add .
   git commit -m "简明扼要的提交消息"
   ```

4. 推送到您的Fork
   ```bash
   git push origin feature/your-feature-name
   ```

5. 创建Pull Request
   - 前往GitHub上您的Fork
   - 点击"Compare & pull request"
   - 填写PR描述，详细说明您的更改

### 提交消息规范

提交消息应遵循以下格式：

```
<类型>: <简短描述>

<详细描述>
```

类型包括：
- `feat`：新功能
- `fix`：bug修复
- `docs`：文档更改
- `style`：不影响代码含义的更改（空格、格式等）
- `refactor`：既不修复bug也不添加功能的代码更改
- `test`：添加或修改测试
- `chore`：对构建过程或辅助工具的更改

示例：
```
feat: 添加志愿者服务时长统计功能

实现了按月、按年统计志愿者服务时长的功能，
并在个人资料页面显示统计结果。
```

## 问题报告

如果您发现了bug或有改进建议，请创建一个Issue：

1. 使用清晰的标题描述问题
2. 详细描述问题的复现步骤
3. 描述预期行为和实际行为
4. 提供环境信息（操作系统、浏览器、Python版本等）
5. 如果可能，添加截图或错误日志

## 功能请求

如果您想请求新功能：

1. 使用"Feature Request"标签创建Issue
2. 详细描述该功能的用例
3. 解释为什么这个功能对项目有价值
4. 如果可能，提供功能的实现思路

## 文档贡献

文档改进也是非常重要的贡献：

1. 更新或添加文档内容
2. 修复文档中的错误
3. 添加示例或教程
4. 改进文档的组织结构

## 测试

所有新功能和bug修复都应包含测试：

1. 为新功能编写单元测试
2. 为修复的bug编写回归测试
3. 确保所有测试都能通过

运行测试：
```bash
pytest
```

我们使用pytest框架进行测试。测试文件应放在`tests/`目录下，并以`test_`开头。

示例测试：

```python
# tests/test_volunteer.py
def test_calculate_total_hours():
    # 设置测试数据
    # 执行测试
    # 验证结果
    assert calculated_hours == expected_hours
```

## 许可证

通过贡献代码，您同意您的贡献将在项目的MIT许可证下提供。请确保您了解并接受此条款。

如果您对贡献过程有任何疑问，请随时在Issue中提问或联系项目维护者。

感谢您的贡献！
 