# 优化app

## 菜单
在菜单中添加 App 当前版本号显示，不可点击。位置在 Quit 上面，用分割线与其他菜单项分隔开。

## Makefile

- 在 `make build` 前调用 `make clean`，确保每次构建都是干净的。
- 添加 `make uninstall`，结束进程，删除 /Applications 中的 .app 文件
- 在 `make install` 前调用 `make uninstall`。

## 更新文档
- README.md
- specs/spec1.md
- .github/copilot-instructions.md

## 更新 App 版本号

## git 提交代码