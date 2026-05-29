# Desktop switcher

Vendored AutoHotkey virtual desktop helper loaded by `autohotkey/hotkeys.ahk` through `autohotkey/desktop-switcher/init.ahk`.

## Owns

- Desktop switching.
- Moving active windows between desktops.
- `VirtualDesktopAccessor.dll` integration.

Repo keybindings live in `autohotkey/hotkeys.ahk` and are listed in `docs/help.md`.

## Maintenance

- Keep compatible with AutoHotkey v2 callers.
- If a Windows update breaks desktop movement, update `VirtualDesktopAccessor.dll` from upstream.
- Do not downgrade the DLL unless the current Windows build requires it.

## Upstream

- `pmb6tz/windows-desktop-switcher`
- `Ciantic/VirtualDesktopAccessor`
