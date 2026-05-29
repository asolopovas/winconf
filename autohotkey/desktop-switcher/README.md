# Desktop switcher

Vendored AutoHotkey v2 virtual desktop helper loaded by `autohotkey/hotkeys.ahk` via `autohotkey/desktop-switcher/init.ahk`.

## Owns

- Desktop switching.
- Moving active windows between desktops.
- `VirtualDesktopAccessor.dll` integration.

Keybindings live in `autohotkey/hotkeys.ahk` and `docs/help.md`.

## Maintenance

- Keep AutoHotkey v2 compatibility.
- Update `VirtualDesktopAccessor.dll` from upstream when Windows breaks desktop movement.
- Do not downgrade the DLL unless required by the current Windows build.

## Upstream

- `pmb6tz/windows-desktop-switcher`
- `Ciantic/VirtualDesktopAccessor`
