# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Windows dotfiles repository that provides automated setup and configuration for a Windows development environment. It includes PowerShell configurations, AutoHotkey scripts, and various system setup utilities.

## Key Components

### Main Entry Points
- `init.ps1` - Main installation script that sets up the entire environment
- `init-software.ps1` - Extended software installation script
- `functions.ps1` - Core PowerShell utility functions used throughout the repository

### PowerShell Configuration
- `powershell/Profile.ps1` - Main PowerShell profile that sources all configurations
- `powershell/modules/` - Custom PowerShell modules (aliases, helpers, PSFzf)
- `powershell/completions/` - Tab completion scripts for various tools
- `powershell/starship.toml` - Starship prompt configuration

### AutoHotkey Scripts
- `hotkeys.ahk` - Main AutoHotkey script for system hotkeys
- `configs/autohotkey-v2/` - AutoHotkey v2 configurations and desktop switcher

### Setup Scripts
All located in `scripts/` directory:
- `Setup-Powershell.ps1` - Configures PowerShell environment
- `Setup-Terminal.ps1` - Sets up Windows Terminal
- `Setup-Autohotkey.ps1` - Installs and configures AutoHotkey
- `Setup-Software.ps1` - Installs additional software packages
- `Bloatware-Removal.ps1` - Removes unwanted Windows software
- `Cleanup.ps1` - System cleanup utilities

## Common Commands

### Installation
```powershell
# Full installation
iwr https://raw.githubusercontent.com/asolopovas/winconf/refs/heads/main/init.ps1 | iex

# With additional software
iwr https://raw.githubusercontent.com/asolopovas/winconf/refs/heads/main/init-software.ps1 | iex
```

### Development
```powershell
# Source main functions
. .\functions.ps1

# Test if a command exists
Test-CommandExists git

# Create symbolic links
CreateSymLink $source $target

# Set file permissions
SetPermissions $directory
```

## Architecture

### PowerShell Module System
The repository uses a custom PowerShell module system:
- `powershell/modules/aliases/` - Custom command aliases
- `powershell/modules/helpers/` - Utility functions for system management
- `powershell/modules/PSFzf/` - Fuzzy finder integration

### Configuration Management
- Configurations are stored in `configs/` directory
- Terminal settings in `configs/winterminal/`
- AutoHotkey configurations in `configs/autohotkey-v2/`

### Installation Flow
1. `init.ps1` installs essential software via winget
2. Clones repository to `$env:userprofile\winconf`
3. Executes setup scripts in sequence
4. Configures PowerShell profile and modules
5. Sets up AutoHotkey scripts and shortcuts

## Environment Variables

- `$DOTFILES` - Points to the winconf directory
- `$SCRIPTS_DIR` - Points to the scripts directory
- `$STARSHIP_CONFIG` - Points to starship configuration file

## File Structure Notes

- PowerShell profiles are symlinked to the repository files
- AutoHotkey scripts use version 2 syntax
- All setup scripts are idempotent and can be run multiple times
- The repository uses Git for version control with safe directory configuration