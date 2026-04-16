# Project Guidelines

## Overview

macOS menu-bar utility that monitors keyboard/mouse activity to detect prolonged sitting and shows full-screen reminders. Swift, macOS 26.3+, menu-bar-only (LSUIElement).

## Build and Test

```bash
make build      # Clean + SPM release build → .build/DontBeSedentary.app (ad-hoc signed)
make run        # Build + open the app
make install    # Uninstall old + copy .app to /Applications
make uninstall  # Kill process + remove .app from /Applications
make clean      # Remove build artifacts
```

No test target exists. Verify changes by building (`make build`) and running (`make run`).

## Architecture

```
Sources/
  main.swift                    # Entry point: creates NSApplication + AppDelegate
  AppDelegate.swift             # Menu bar setup, coordinates monitor ↔ reminders, UserDefaults persistence
  ActivityMonitor.swift         # Global keyboard/mouse event listeners, session state machine
  ReminderWindowController.swift # Full-screen NSPanel on every connected display
  SettingsWindowController.swift # Settings window (sedentary time, dismiss time, session-end time, reminder text)
  Logger.swift                  # Thread-safe daily log → ~/Documents/SittingMonitor-YYYYMMDD.log
  Info.plist                    # LSUIElement=true, excluded from SPM target
```

**Data flow:** ActivityMonitor detects activity → triggers callbacks on AppDelegate → AppDelegate formats reminder text and calls ReminderWindowController to show/dismiss panels. Settings are persisted to UserDefaults and loaded on launch. Logger is a singleton called from all components.

## Conventions

- **Language:** Code and identifiers in English; UI text and log messages in Chinese
- **Threading:** All UI updates via `DispatchQueue.main.async`; always use `[weak self]` in event monitor closures
- **Classes:** Mark as `final class`; use stored closures (`var onEvent: (() -> Void)?`) for inter-component communication instead of delegates
- **Event monitors:** Must be explicitly removed with `NSEvent.removeMonitor()` on teardown to prevent leaks
- **Settings:** Persisted to UserDefaults; loaded on launch via `AppDelegate.loadSettings()`
- **Logging:** Daily log files (`SittingMonitor-YYYYMMDD.log`), auto-cleanup keeps 2 days

## Key Constants

| Constant | Default | Location |
|----------|---------|----------|
| Sedentary threshold | 45 min | `ActivityMonitor.sedentaryMinutes` |
| Dismiss inactivity | 10 min | `ActivityMonitor.reminderDismissMinutes` |
| Session-end inactivity | 10 min | `ActivityMonitor.sessionEndMinutes` |
| Check interval | 5 sec | `ActivityMonitor.startTimer()` |
| Gradient color | #407245 | `ReminderView.setupGradient()` |
| Reminder text template | `久坐 {{sedentaryMinutes}} 分钟了，休息一下吧！` | `AppDelegate.reminderText` |
| Log retention | 2 days | `Logger.cleanupOldLogs()` |
| Countdown update | 60 sec | `ReminderWindowController.startCountdownTimer()` |
| Close button size | 36pt | `CloseButton` |

## Pitfalls

- **Multi-screen:** Always call `dismissAll()` before creating new panels; iterate all `NSScreen.screens`
- **Window level:** Reminder panels must use `.statusBar` level + `.fullScreenAuxiliary` to appear above fullscreen apps
- **LSUIElement mode:** No Dock icon, no Cmd+Tab — only menu bar access; test menu interactions accordingly
- **Info.plist:** Excluded from SPM target via `exclude:` in Package.swift; copied to .app bundle by Makefile
- **Launch at Login:** Uses `SMAppService.mainApp` (macOS 13+); requires signed app bundle to function
- **Close button:** Uses `hitTest` override in ReminderView to pass through mouse events except on the close button; panel `ignoresMouseEvents` is `false`

## Spec Reference

See [specs/spec1.md](specs/spec1.md) for the base requirements and [specs/spec2.md](specs/spec2.md) for optimization updates.
