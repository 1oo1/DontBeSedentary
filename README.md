# DontBeSedentary

macOS 菜单栏工具，监测键盘和鼠标活动，检测久坐并全屏提醒休息。

## 下载

最新版本: [v1.0.3](https://github.com/1oo1/DontBeSedentary/releases/download/v1.0.3/DontBeSedentary.zip)

## 功能

- 监听键盘与鼠标活动，自动判断用户是否在使用电脑
- 连续使用超过设定时间（默认 45 分钟）后，在**所有屏幕**全屏显示提醒
- 用户离开电脑达到设定时间（默认 10 分钟）后自动关闭提醒
- 点击右上角关闭按钮可关闭提醒并重置久坐计时器
- 菜单栏提供日志查看、启用/禁用开关、设置和开机启动选项
- 设置持久化到 UserDefaults（久坐时间、提醒显示时间、离开判定时间、提醒文本）
- 提醒窗口显示自动关闭倒计时，每分钟更新
- 活动日志按天记录到 `~/Documents/SittingMonitor-YYYYMMDD.log`，自动保留最近 2 天

## 系统要求

- macOS 26.3+
- Swift 6.3+

## 构建与运行

```bash
make build      # 清理并编译，生成 .build/DontBeSedentary.app
make run        # 编译并启动应用
make install    # 卸载旧版本并安装到 /Applications
make uninstall  # 结束进程并从 /Applications 删除
make clean      # 清理构建产物
```

## 使用说明

应用以菜单栏模式运行（无 Dock 图标），点击菜单栏的 🧍 图标可以：

- **Enabled** — 启用/禁用监测
- **Launch at Login** — 开机自动启动
- **Log → Open Log File** — 打开当天活动日志
- **Settings...** — 设置久坐提醒时间、提醒窗口显示时间、离开判定时间和提醒文本
- **Version x.x.x** — 当前版本号（不可点击）
- **Quit** — 退出应用

提醒窗口显示时，点击右上角关闭按钮可立即关闭提醒并重置计时器。

## 许可证

MIT
