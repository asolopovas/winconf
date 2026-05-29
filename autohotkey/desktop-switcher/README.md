# Desktop switcher

Vendored AutoHotkey virtual desktop helper used by `autohotkey/hotkeys.ahk`.

## Role in this repo

- Loaded through `autohotkey/desktop-switcher/init.ahk`.
- Provides desktop switching and moving active windows between desktops.
- Uses `VirtualDesktopAccessor.dll` for Windows virtual desktop APIs.
- Repo keybindings are defined in `autohotkey/hotkeys.ahk`, not here.

## winconf bindings

| Key | Action |
|---|---|
| `Win+1..9` | Go to desktop |
| `Win+Shift+1..9` | Move active window to desktop |
| `Win+h/j/k/l` | Windows desktop navigation |

## Maintenance notes

- Keep this directory compatible with AutoHotkey v2 usage from the parent scripts.
- If a Windows update breaks desktop movement, update `VirtualDesktopAccessor.dll` from the upstream project.
- Do not replace the DLL with an older build unless the current Windows build requires it.
- Prefer changing repo hotkeys in `autohotkey/hotkeys.ahk`.

## Upstream

- Original desktop switcher: `pmb6tz/windows-desktop-switcher`
- DLL provider: `Ciantic/VirtualDesktopAccessor`
