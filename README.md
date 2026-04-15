# DontBeSedentary

macOS 菜单栏工具，监测键盘和鼠标活动，检测久坐并全屏提醒休息。

## 功能

- 监听键盘与鼠标活动，自动判断用户是否在使用电脑
- 连续使用超过设定时间（默认 45 分钟）后，在**所有屏幕**全屏显示提醒
- 用户离开电脑 10 分钟后自动关闭提醒
- 菜单栏提供日志查看、启用/禁用开关和时间设置
- 活动日志记录到 `~/Documents/SittingMonitor.log`

## 系统要求

- macOS 14.0+
- Swift 5.9+

## 构建与运行

```bash
make build    # 编译并生成 .build/DontBeSedentary.app
make run      # 编译并启动应用
make install  # 安装到 /Applications
make clean    # 清理构建产物
```

## 使用说明

应用以菜单栏模式运行（无 Dock 图标），点击菜单栏的 🧍 图标可以：

- **Log → Open Log File** — 打开活动日志
- **Time Setting → Enabled** — 启用/禁用监测
- **Time Setting → Settings...** — 修改久坐提醒时间（分钟）
- **Quit** — 退出应用

## 许可证

MIT
