# Project Guidelines

## Overview

macOS menu-bar utility that monitors keyboard/mouse activity to detect prolonged sitting and shows full-screen reminders. Swift, macOS 14+, menu-bar-only (LSUIElement).

## Build and Test

```bash
make build    # SPM release build → .build/DontBeSedentary.app (ad-hoc signed)
make run      # Build + open the app
make install  # Copy .app to /Applications
make clean    # Remove build artifacts
```

No test target exists. Verify changes by building (`make build`) and running (`make run`).

## Architecture

```
Sources/
  main.swift                    # Entry point: creates NSApplication + AppDelegate
  AppDelegate.swift             # Menu bar setup, coordinates monitor ↔ reminders
  ActivityMonitor.swift         # Global keyboard/mouse event listeners, session state machine
  ReminderWindowController.swift # Full-screen NSPanel on every connected display
  SettingsWindowController.swift # Time-input settings window
  Logger.swift                  # Thread-safe append logger → ~/Documents/SittingMonitor.log
  Info.plist                    # LSUIElement=true, excluded from SPM target
```

**Data flow:** ActivityMonitor detects activity → triggers callbacks on AppDelegate → AppDelegate calls ReminderWindowController to show/dismiss panels. Logger is a singleton called from all components.

## Conventions

- **Language:** Code and identifiers in English; UI text and log messages in Chinese
- **Threading:** All UI updates via `DispatchQueue.main.async`; always use `[weak self]` in event monitor closures
- **Classes:** Mark as `final class`; use stored closures (`var onEvent: (() -> Void)?`) for inter-component communication instead of delegates
- **Event monitors:** Must be explicitly removed with `NSEvent.removeMonitor()` on teardown to prevent leaks
- **Settings:** In-memory only (no UserDefaults persistence) — by design per spec

## Key Constants

| Constant | Default | Location |
|----------|---------|----------|
| Sedentary threshold | 45 min | `ActivityMonitor.sedentaryMinutes` |
| Dismiss inactivity | 10 min | `ActivityMonitor.inactivityThresholdForDismiss` |
| Session-end inactivity | 2 min | `ActivityMonitor.checkStatus()` |
| Check interval | 5 sec | `ActivityMonitor.startTimer()` |
| Gradient color | #407245 | `ReminderView.setupGradient()` |

## Pitfalls

- **Multi-screen:** Always call `dismissAll()` before creating new panels; iterate all `NSScreen.screens`
- **Window level:** Reminder panels must use `.statusBar` level + `.fullScreenAuxiliary` to appear above fullscreen apps
- **LSUIElement mode:** No Dock icon, no Cmd+Tab — only menu bar access; test menu interactions accordingly
- **Info.plist:** Excluded from SPM target via `exclude:` in Package.swift; copied to .app bundle by Makefile

## Spec Reference

See [specs/spec1.md](specs/spec1.md) for the full requirements specification.
