---
name: win-screenshot
description: "Screenshot a specific application window on Windows and save it as a PNG you can read/analyze. Use when asked to capture, screenshot, or visually inspect any running app's window — including GPU/Chromium/WebView2/Electron apps and hidden or minimized windows. Selects the window by process name, title, class, PID, handle, or foreground; handles DPI, GPU black-frames, and Win10/11 invisible borders."
created: "2026-06-21"
---

# /win-screenshot

Capture a real native window on Windows to a PNG. Built to be accurate on the cases that
break naive screenshots: hardware-accelerated apps (Chrome, Edge, Electron, VS Code,
WebView2, Steam), high-DPI scaling, and Win10/11 windows whose `GetWindowRect` includes an
invisible drag-border.

## Quick start

```powershell
$S = "$env:USERPROFILE/winconf/.agents/skills/win-screenshot/scripts/Capture-Window.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S -List          # discover windows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S -Process notepad
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $S -Title "Settings" -Out C:\tmp\s.png
```

Then `Read` the PNG path printed in the JSON result.

Always run under **`powershell.exe`** (Windows PowerShell 5.1) — it has `System.Drawing`
built in. Under `pwsh` 7 it needs the `System.Drawing.Common` package.

## Selecting the window (filters are AND-combined)

- `-Process <name>` — process name without `.exe` (e.g. `Code`, `notepad`).
- `-Title <regex>` — matches the window title (regex; substring works).
- `-Class <name>` — exact window class (e.g. `Chrome_WidgetWin_1`).
- `-ProcessId <pid>` / `-Hwnd <handle>` — exact process or window handle.
- `-Foreground` — the window currently in focus.
- `-List` — print candidates (Hwnd, Pid, Process, Size, Class, Title) and exit. **Start here
  when unsure** which window to target.

If several windows match, the **largest** is captured and the rest are listed on stderr.

## Options

- `-Out <path>` — output file (default `<OutDir>/<process>-<hwnd>.png`).
- `-OutDir <dir>` — output folder (default `%TEMP%`).
- `-IncludeHidden` — also consider hidden/zero-size/cloaked windows (needed for tray apps
  and launchers that stay hidden until a hotkey).
- `-Show` — restore (if minimized) and bring to foreground before capturing. Use for hidden
  or minimized targets, or anything the screen-fallback must capture.
- `-NoScreenFallback` — disable the on-screen fallback (PrintWindow only).

## Result

One JSON line: `Status` (`ok` | `blank` | `no-size`), `Method` (`printwindow` | `screen`),
`Hwnd`, `Pid`, `Process`, `Title`, `Size`, `Path`. Exit code `0` on success, `2` if the
frame could not be captured, `1` on no match / bad input.

## How it captures (and why it's accurate)

1. **Primary — `PrintWindow(hwnd, dc, PW_RENDERFULLCONTENT=0x2)`.** The `0x2` flag (Win8.1+)
   is what makes GPU-composited windows (Chromium/WebView2/Electron) render instead of
   returning black. Works even when the window is occluded or partly off-screen, and does not
   require focus.
2. **Fallback — bring to foreground + `Graphics.CopyFromScreen`.** For the rare app whose
   PrintWindow still comes back black (some D3D/exclusive surfaces). Requires the window
   on-screen and unobscured, so it's only used when needed.
3. **Blank detection.** The result is pixel-sampled; an all-black frame triggers the fallback
   (and never overwrites a good capture).
4. **DPI awareness.** The script declares Per-Monitor-V2 awareness before measuring, so window
   rects are true physical pixels on scaled displays.
5. **Accurate bounds.** Cropping uses `DwmGetWindowAttribute(DWMWA_EXTENDED_FRAME_BOUNDS)`,
   which excludes the ~7px invisible resize border Win10/11 reports in `GetWindowRect` — so
   the PNG is exactly the visible window, no dead margin.

## Gotchas this skill already handles

- **Unicode class/title** must be read with `CharSet=Unicode`; ANSI marshaling truncates
  every name to its first character.
- **Injected-input rejection.** Some apps' global-hotkey hooks ignore synthetic keystrokes
  (`LLKHF_INJECTED`), so you cannot reveal such a window with `SendKeys`. Use `-IncludeHidden
  -Show` to reveal it via `ShowWindow` instead.
- **Dev browser views are not the native window.** A web/dev-server view renders the DOM but
  not native window chrome; screenshot the real window, which this skill targets.

## Examples

```powershell
# A hidden, hotkey-only launcher (WebView2), revealed and captured:
... -Class LynLauncherWindow -IncludeHidden -Show

# Whatever I'm looking at right now:
... -Foreground

# A specific browser tab window by title:
... -Process brave -Title "Claude Directory"
```
