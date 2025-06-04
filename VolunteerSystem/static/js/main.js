/**
 * 志愿者管理系统主JavaScript文件
 * 版本: 1.0.0
 */

// 页面加载完成后执行
document.addEventListener('DOMContentLoaded', function() {
  // 初始化工具提示
  initTooltips();
  
  // 初始化日期时间选择器
  initDateTimePickers();
  
  // 初始化表单验证
  initFormValidation();
  
  // 初始化数据表格
  initDataTables();
  
  // 处理活动过滤
  setupActivityFilters();
});

/**
 * 初始化Bootstrap工具提示
 */
function initTooltips() {
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });
}

/**
 * 初始化日期时间选择器
 */
function initDateTimePickers() {
  // 查找所有日期时间输入框
  const dateTimeInputs = document.querySelectorAll('input[type="datetime-local"]');
  
  // 为每个日期时间输入框添加最小日期限制
  dateTimeInputs.forEach(input => {
    // 如果输入框没有设置最小日期，则设置为当前日期
    if (!input.min) {
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      
      input.min = `${year}-${month}-${day}T${hours}:${minutes}`;
    }
  });
}

/**
 * 初始化表单验证
 */
function initFormValidation() {
  // 查找所有需要验证的表单
  const forms = document.querySelectorAll('.needs-validation');
  
  // 遍历表单并添加验证
  Array.prototype.slice.call(forms).forEach(function (form) {
    form.addEventListener('submit', function (event) {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
      }
      
      form.classList.add('was-validated');
    }, false);
  });
}

/**
 * 初始化数据表格
 */
function initDataTables() {
  // 查找所有数据表格
  const tables = document.querySelectorAll('.data-table');
  
  // 初始化每个表格
  tables.forEach(table => {
    if (table.rows.length > 1) {
      new DataTable(table, {
        paging: true,
        searching: true,
        ordering: true,
        info: true,
        language: {
          url: '//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese.json'
        }
      });
    }
  });
}

/**
 * 设置活动过滤器
 */
function setupActivityFilters() {
  const filterButtons = document.querySelectorAll('.filter-btn');
  const activityItems = document.querySelectorAll('.activity-item');
  
  filterButtons.forEach(button => {
    button.addEventListener('click', function() {
      // 移除所有按钮的active类
      filterButtons.forEach(btn => btn.classList.remove('active'));
      
      // 为当前按钮添加active类
      this.classList.add('active');
      
      // 获取过滤类型
      const filterType = this.getAttribute('data-filter');
      
      // 显示或隐藏活动项
      activityItems.forEach(item => {
        if (filterType === 'all' || item.getAttribute('data-status') === filterType) {
          item.style.display = 'block';
        } else {
          item.style.display = 'none';
        }
      });
    });
  });
}

/**
 * 确认删除操作
 * @param {string} itemType - 要删除的项目类型
 * @param {string} itemName - 要删除的项目名称
 * @returns {boolean} - 是否确认删除
 */
function confirmDelete(itemType, itemName) {
  return confirm(`确定要删除${itemType}【${itemName}】吗？此操作不可撤销。`);
}

/**
 * 格式化日期时间
 * @param {string} dateTimeString - 日期时间字符串
 * @returns {string} - 格式化后的日期时间
 */
function formatDateTime(dateTimeString) {
  const date = new Date(dateTimeString);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  
  return `${year}-${month}-${day} ${hours}:${minutes}`;
} 