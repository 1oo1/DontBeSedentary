# 请实现一个 macOS menu-bar 监测用户是否久坐（Swift，macOS 14+），具体要求：

1. 监听键盘敲击和鼠标活动，如果既没有使用键盘也没有使用鼠标，则认为用户离开电脑了，否则就认为用户在使用电脑。
2. 当用户开始使用电脑超过 45 分钟后，在**所有屏幕**显示提醒，比如用户使用三个显示器，就在三个显示器上显示提醒。
3. 提醒时在每个屏幕里都全屏显示一个提醒窗。使用 NSPanel（nonactivatingPanel）+ NSVisualEffectView（.hudWindow 材质），和屏幕尺寸一样，占据全屏，包含：
   - 该窗口是一个 #407245 渐变色，从四周渐变到中心逐渐透明，添加上呼吸动画，起到警示作用。
   - 窗口中央显示一行文字「你已经使用电脑 45 分钟了，休息一下吧！」，字体为 PingFang SC Medium，白色，大小 28pt，添加宽度平滑过渡动画。
   - 直到用户连续10分钟无任何键盘或鼠标活动时，才关闭所有提醒窗。
4. 在菜单栏提供 Log 和 Time Setting 子菜单，Time Setting 包含启用/禁用开关和 Settings 入口。Settings 窗口包含一个时间输入框，只能输入数字，默认值为 45。
5. 应用以 LSUIElement 模式运行（仅菜单栏图标，无 Dock 图标）。使用 Swift Package Manager 构建，提供 Makefile（build/run/install/clean），构建产物为签名的 .app bundle。
6. 记录log，包含用户每次开始使用电脑的时间、每次显示提醒的时间、每次关闭提醒的时间，以及用户在设置中修改时间的记录。日志文件保存在用户的 Documents 目录下，文件名为 "SittingMonitor.log"，可以通过菜单栏的 Log 子菜单打开日志查看。