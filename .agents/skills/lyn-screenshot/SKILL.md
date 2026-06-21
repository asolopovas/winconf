---
name: lyn-screenshot
description: "Screenshot the Lyn launcher (frameless, hidden until hotkey) and/or its settings window on Windows. Use when asked to capture, screenshot, or visually verify the Lyn launcher or settings UI. The launcher's global hotkey ignores injected input, so SendKeys cannot trigger it — this skill shows and captures the real native windows directly."
created: "2026-06-21"
---

# /lyn-screenshot

Capture the real Lyn native windows on Windows and save them as PNGs you can read.

Lyn's launcher is a frameless, always-on-top window that stays hidden until the global
hotkey (Ctrl+Space) fires. Two things make naive screenshotting fail:

- The launcher's low-level keyboard hook **rejects injected keystrokes**
  (`event.Flags & llkhfInjected == 0`), so `SendKeys`/`SendInput` of the hotkey never
  shows it. Triggering the hotkey programmatically is impossible from user mode.
- The launcher is translucent; a Wails dev **browser** view (localhost:34115) renders the
  same DOM but **not** native window chrome, so window-frame bugs are invisible there.
  Always capture the native window, not the browser.

This skill sidesteps both: it finds the window by its **class name**, shows it with native
`ShowWindow` + `SetForegroundWindow`, and grabs pixels with `PrintWindow` (flag
`PW_RENDERFULLCONTENT` = `0x2`, required for WebView2 content).

## Usage

```
/lyn-screenshot                 # capture the launcher
/lyn-screenshot settings        # capture the settings window
/lyn-screenshot both            # capture both
```

Run the script directly:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "<skill>/scripts/capture-lyn.ps1" -Target both -OutDir "$env:TEMP"
```

Then `Read` the resulting PNGs:

- `<OutDir>/lyn-launcher.png`
- `<OutDir>/lyn-settings.png`

The script prints one JSON line per capture (`Class`, `Hwnd`, `Width`, `Height`, `Path`).

## Parameters

- `-Target` — `launcher` (default), `settings`, or `both`.
- `-OutDir` — output folder (default `%TEMP%`).
- `-KeepSettingsOpen` — leave the settings window open after capture (default: close it if
  this skill spawned it).

## How each target is shown

- **Launcher** (`LynLauncherWindow`): the process is already running, so the window exists
  even while hidden. The script locates it by class and `ShowWindow`s it.
- **Settings** (`LynSettingsWindow`): a separate process. If not already open, the script
  launches `<lyn-exe> --settings-window` (exactly what the app's `OpenSettingsWindow` does),
  waits for the window, captures, then closes it again.

## Requirements

- Lyn must be running (`just dev` in `lyn-tools`, or an installed `lyn.exe`). The script
  finds the executable from the running `lyn-dev` or `lyn` process.
- Windows only. Uses Windows PowerShell (`powershell.exe`) for built-in `System.Drawing`;
  do not run under `pwsh` unless `System.Drawing.Common` is available.

## Robustness

`PrintWindow` on a translucent WebView2 window occasionally returns an unpainted (all-black)
frame. The script samples the result and retries (re-show + longer settle) up to 3 times,
warning in its JSON if the frame still looks blank.

## Class names (source of truth)

Defined in `lyn-tools/lyn/window.go`:

- `LynLauncherWindow` — launcher
- `LynSettingsWindow` — settings

If these change, update `scripts/capture-lyn.ps1`.
