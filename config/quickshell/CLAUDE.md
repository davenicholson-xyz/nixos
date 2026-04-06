# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A [Quickshell](https://quickshell.outfoxxed.me/) status bar written in QML, targeting Hyprland. No build step — Quickshell loads `bar.qml` directly. Reload by killing and relaunching the quickshell process.

## Architecture

`bar.qml` is the root `PanelWindow`. It owns all shared state (colors, font, `pillsVisible`, `kvmConnected`) and instantiates components as children of a single full-width `Item`.

### Layout

- **Left:** `SpotifyPill` + `LauncherPill` (Row, anchored left)
- **Center:** `workspacePill` — always `anchors.centerIn: parent`; never push it into a layout or it loses true centering
- **Right:** `CpuPill`, `RamPill`, `DrivePill`, `NetworkPill` (staggered show/hide) + arrow toggle + `ClockPill`

### Component conventions

Every pill is a `Rectangle` that takes `required property var panelRoot` to access shared colors and font. Heights follow `height: contentItem.height + 10`. SVG icons always use `Image` (with `visible: false; layer.enabled: true`) + `ColorOverlay` to tint at runtime.

Popups use `PopupWindow` anchored `Edges.Bottom` to the pill, with `color: "transparent"` on the window and a `Rectangle` inside with `topMargin: 8` for the visual gap.

For rounded popup corners that correctly clip child content, set both `radius`, `clip: true`, and `layer.enabled: true` on the popup's inner `Rectangle`.

### Show/hide animation

`pillsVisible` in `bar.qml` controls the right-side info pills. `showAnim`/`hideAnim` are `SequentialAnimation`s that stagger pills using `NumberAnimation` on `opacity` and a custom `xOff` property applied via `Translate`. Each pill starts at `opacity: 0`, `xOff: 24`.

### Color scheme

All colors are properties on `root`: `colBg`, `colPill`, `colWsActive`, `colWsOccupied`, `colWsEmpty`, `colClock`, `colBarTrack`. Threshold colors for high usage are defined inline per pill: `>= 80%` → `#e0c94a`, `>= 95%` → `#e05252`.

### Data sources

| Pill | Source |
|------|--------|
| CPU | `/proc/stat` polled via `Process` |
| RAM | `/proc/meminfo` |
| Disk | `df` |
| Network | `/proc/net/dev` |
| Spotify | `playerctl -p spotify` + `cava` for visualizer |

### SpotifyPill specifics

- Runs `cava` as a subprocess (only while `status === "Playing"`) reading from `cava.cfg`
- `cava.cfg` uses `bars = 24, channels = mono` — the QML takes `slice(0, 12)` to get the non-mirrored half
- Popup shows full-bleed album art with a gradient scrim and info overlay

## Key Quickshell APIs

- `PanelWindow` — anchored top bar
- `PopupWindow` — tooltip popups anchored to pill items
- `GlobalShortcut` — global keybind registration
- `Process` + `SplitParser` — spawn shell commands, read stdout line-by-line
- `Hyprland.workspaces`, `Hyprland.focusedWorkspace`, `Hyprland.dispatch` — workspace state/control
- `Qt5Compat.GraphicalEffects.ColorOverlay` — SVG icon tinting
- `Qt5Compat.GraphicalEffects.OpacityMask` — rounded image clipping (used in pill thumbnails)
