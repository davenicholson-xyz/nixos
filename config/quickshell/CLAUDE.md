# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a [Quickshell](https://quickshell.outfoxxed.me/) status bar configuration written in QML. Quickshell is a Wayland shell framework. The bar targets Hyprland as the window manager.

## Running

Quickshell loads `bar.qml` directly — there is no build step. To reload after changes:

```sh
quickshell -p /path/to/this/dir   # initial launch
# or kill and relaunch the quickshell process to pick up changes
```

## Architecture

Everything lives in a single file, `bar.qml`, as one `PanelWindow` with:

- **Left side (implicit):** nothing — workspace pill is centered
- **Center:** Workspace switcher pill — 4 workspaces with per-workspace SVG icons, colored by state (active/occupied/empty), clickable to switch via `Hyprland.dispatch`
- **Right side:** System info pills (CPU, RAM, disk) + dot toggle + clock pill

### Info pills (CPU / RAM / disk)

Each pill is a `Rectangle` with:
- An SVG icon colored via `ColorOverlay`
- A thin progress bar (`width: 44, height: 3`) filled proportionally to usage
- A `Process` + `Timer` polling system data from `/proc/stat`, `/proc/meminfo`, `df`, and `/sys/class/thermal/`
- A `MouseArea` for hover detection
- An associated `PopupWindow` anchored below the pill, shown on hover

### Show/hide animation

Pills start hidden (`opacity: 0`, `xOff: 24`). Toggle is exposed two ways:
1. `GlobalShortcut` (appid `quickshell`, name `togglePills`)
2. A small dot `Rectangle` on the right

`showAnim` / `hideAnim` are `SequentialAnimation`s that stagger the three pills in/out using `NumberAnimation` on `opacity` and the custom `xOff` property (applied via `Translate`).

### Color scheme

All colors are properties on `root` (`colBg`, `colPill`, `colWsActive`, `colWsOccupied`, `colWsEmpty`, `colClock`, `colBarTrack`). Threshold colors for high usage are inline: `>= 80%` → yellow `#e0c94a`, `>= 95%` → red `#e05252`.

### SVG icons

`wsIcons` maps workspace index to SVG filename. All icons use the same `Image` + `ColorOverlay` pattern to tint them at runtime.

## Key Quickshell APIs used

- `PanelWindow` — anchored top bar
- `PopupWindow` — tooltip popups anchored to pill items
- `GlobalShortcut` — global keybind registration with Wayland compositor
- `Process` + `SplitParser` — spawning shell commands and reading stdout line-by-line
- `Hyprland.workspaces`, `Hyprland.focusedWorkspace`, `Hyprland.dispatch` — workspace state and control
- `Qt5Compat.GraphicalEffects.ColorOverlay` — SVG icon tinting
