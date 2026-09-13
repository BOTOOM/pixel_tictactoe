---
name: flutter-android-showcase
description: Run and record Pixel Tic-Tac-Toe on Android, including authentic adaptive CPU progression.
---

# Android gameplay testing

## Devin Secrets Needed
None: this app runs offline.

## Setup
- Export Flutter and Android SDK paths from the repo blueprint.
- Check `adb devices` first. Reuse a running AVD; otherwise start `emulator -avd pixel_ttt -no-snapshot-load -no-audio`, then `adb wait-for-device`.
- Run `flutter run -d emulator-5554` in an interactive (`tty: true`) exec session so `R` can hot-restart when code changes. The device ID can differ if more than one emulator is running.
- Preserve pre-existing local Maven mirror edits. Do not overwrite Gradle files to bypass build issues.
- Use `wmctrl -l` to find the emulator. If maximize is ignored, resize it explicitly with `wmctrl -ir <id> -e 0,<x>,<y>,<w>,<h>`. Keep the entire phone visible.

## CPU-mode coverage
- Select VS CPU; human is X and machine O. Use visible legal moves, never inject levels or game state.
- CPU moves are random at lower levels. Adapt to the observed board: take wins, block threats, and create forks to beat CASUAL. CASUAL blocks single threats but may miss double threats.
- A SMART CPU that starts center can demonstrate `OPPOSITE CORNER` and `FORK`: human plays a corner, CPU takes opposite corner, human plays an adjacent edge that does not make an immediate threat. Inspect actual board before choosing a move.
- Test input lock with two rapid taps in one `adb shell` command. If the CPU coincidentally chooses the attempted square, repeat with another target rather than claiming this proves the lock.
- Inspect captured frames for `CPU THINKING...` → O mark → `YOUR TURN`; record frame timestamps to assess the approximate response delay.
- Human win advances level, CPU win lowers it, draw preserves it. Continue alternates the starter; when CPU starts, it must place O automatically.

## Recording
- Use annotations for the test evidence. Auto-edited recordings may accelerate animation pauses, so also provide a clean portrait cut from raw recording chunks with game actions and celebrations at normal speed.
- Raw recordings can span multiple MKV chunks; concatenate them in numbered order before trimming with global annotation timestamps.
- When the lead sends a nonbehavioral fix during gameplay, preserve valid progression evidence, state its commit scope, and do a separate latest-commit smoke test after hot restart.
