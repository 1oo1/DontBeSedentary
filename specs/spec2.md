# 优化app

## Session-end inactivity 改为10分钟

## log
日志文件名改为 "SittingMonitor-YYYYMMDD.log"，每天一个日志文件，保留最近2天的日志，自动删除过期日志

## 菜单

1. 外层菜单里添加开机启动选项，默认不开启，开启后会在用户登录时自动启动应用
2. Time Setting -- Enabled 移到外层菜单
3. Time Setting -- Settings 移到外层菜单

### Settings
- 添加 reminder 窗口的显示时间设置，默认值为 10 分钟
- 添加 reminder 窗口文本设置，默认值为「久坐 {{sedentaryMinutes}} 分钟了，休息一下吧！」
- 设置保存到 UserDefaults，应用启动时加载设置并应用

## 文档更新
- README.md：按需更新
- .github/copilot-instructions.md：更新架构图、数据流、常量表、约定等相关内容
- specs/spec1.md：更新需求说明，添加新的功能点和细节要求

## git 提交代码