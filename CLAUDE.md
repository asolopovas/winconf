# CLAUDE.md

Project instructions for Claude Code when working with this Windows dotfiles repository

## Repository Overview

Windows development environment setup with PowerShell, AutoHotkey v2, and terminal configurations

## Key Rules
- **NEVER** run `taskkill` commands for AutoHotkey
- **NEVER** run AutoHotkey scripts directly
- No comments in code
- Follow `~/docs` for syntax and best practices
- `*.ahk` Scripts always use AutoHotkey V2 syntax

### Entry Points
- `init.ps1` - Main Install
- `init-software.ps1` - Software Installation
- `init-autohotkey.ahk` - AutoHotkey initialization
- `functions.ps1` - Core utility functions

## Project Structure

### Directories
- `scripts/` - Setup and configuration scripts
- `powershell/` - PowerShell profiles, modules, completions
- `autohotkey/` - AutoHotkey v2 automation scripts
- `terminal/` - Windows Terminal configuration
- `bin/` - Command-line utilities and scripts
- `configs/` - Configuration files (WezTerm, PowerShell, Starship)
- `logs/` - Log files and debug output
- `tmp/` - Temporary files

### PowerShell System
Custom module architecture with:
- `modules/aliases/` - Command shortcuts and Git integration
- `modules/helpers/` - Utility modules (environment, Git, admin tools)
- `modules/PSFzf/` - Fuzzy finder integration
- `completions/` - Tab completion for docker and git
- Profile files: `Microsoft.Powershell_profile.ps1`
- Configuration: `powershell.config.json`, `starship.toml`

### AutoHotkey
- `helpers.ahk` - Core utility functions
- `hotkeys.ahk` - Shortcuts
- `terminal.ahk` - Terminal tracking and toggle system
- `window-management.ahk` - Window management utilities
- `system.ahk` - System Helper Function
- `fast-scroll.ahk` - Fast scrolling behavior
- `debug.ahk` - Debugging utilities
- `runasuser.ahk` - User privilege utilities
- `desktop-switcher/` - Virtual desktop utilities with DLL integration
- `registry/` - Registry modification files

### Scripts Directory
Key setup scripts:
- `Setup-*.ps1` - Application-specific setup (WezTerm, Barrier, DirectoryOpus, etc.)
- `Bloatware-Removal.ps1` - Remove Windows bloatware
- `Cleanup.ps1` - System cleanup utilities
- `Disable-IPv6.ps1` - Network configuration
- `Fix-Ssh-Permissions.ps1` - SSH permission fixes
- `wsl-exclusions.ps1` - WSL-specific exclusions
- `dotfiles-auth.ps1` - Authentication setup

### Key Configuration Files
- `configs/.wezterm.lua` - WezTerm terminal configuration
- `bin/ssh-copy-id.cmd` - SSH key copy utility
- `terminal/settings.json` - Windows Terminal settings

## Development Instructions

### Running Powershell Commands from WSL

- `powershell.exe -Command "& 'C:\Program Files\AutoHotkey\v2\AutoHotkey.exe' '<script_path>' /ErrorStdOut"`

Use `wslpath` for path translation:
- `wslpath -w /mnt/c/Users/file.txt` → `C:\Users\file.txt` (WSL→Windows)
- `wslpath 'C:\Users\file.txt'` → `/mnt/c/Users/file.txt` (Windows→WSL)
- `wslpath -m /mnt/c/Users` → `C:/Users` (forward slashes)

