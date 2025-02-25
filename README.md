# Windows Dotfiles

## Installation
```
iwr https://raw.githubusercontent.com/asolopovas/winconf/refs/heads/main/init.ps1 | iex
```

## Include Setup-Software.ps script
```
iwr https://raw.githubusercontent.com/asolopovas/winconf/refs/heads/main/init.ps1 --software | iex
```

This script will by default install the following application using winget:
 - [Microsoft Windows Terminal](https://github.com/microsoft/terminal) - Powerful terminal application
 - [Microsoft PowerToys](https://github.com/microsoft/PowerToys) - Powerful tool to customize your Windows experience
 - [Void Tools Everything](https://www.voidtools.com/) - Powerfull File Search Engine
 - [Junegunn FZF](https://github.com/junegunn/fzf) - Powerfull File Search Engine
 - [Git](https://git-scm.com) - Version Control System
 - [Starship](https://starship.rs) - Prompt Styling
 - [Autohotkey v2](https://www.autohotkey.com/v2) - Hotkey Engine

The link will autoconfigure the basic setup using the following powershell scripts from `scripts` folder:
 - [Bloatware-Removal](https://github.com/asolopovas/winconf/blob/main/scripts/Bloatware-Removal.ps1)
 - [Cleanup](https://github.com/asolopovas/winconf/blob/main/scripts/Cleanup.ps1)
 - [Setup-EnvironmentPaths](https://github.com/asolopovas/winconf/blob/main/scripts/Setup-EnvironmentPaths.ps1)
 - [Setup-NerdFornts](https://github.com/asolopovas/winconf/blob/main/scripts/Setup-NerdFonts.ps1)
 - [Setup-Powershell](https://github.com/asolopovas/winconf/blob/main/scripts/Setup-Powershell.ps1)
 - [Setup-Terminal](https://github.com/asolopovas/winconf/blob/main/scripts/Setup-Terminal.ps1)
 - [Setup-Autohotkey](https://github.com/asolopovas/winconf/blob/main/scripts/Setup-Autohotkey.ps1)


# AutoHotkey Shortcuts for Desktop Switching and App Management
These dotfiles contain autohotkey script that provides a set of AutoHotkey (AHK) shortcuts to improve window and workspace management, allowing for quick desktop navigation, application launching, and window manipulation.

## 📌 Features
- **Virtual Desktop Navigation** using `hjkl` keys (Vim-style)
- **Quick App Switching** (Alt+Tab alternatives)
- **PowerShell and Ubuntu Launchers** (normal and admin modes)
- **Default Browser & Media Player Activation**
- **Window Maximization and Restoration**
- **Window Closing and Reloading Scripts**
- **Restarting Windows Explorer**
- **Cycling Through Windows of the Same Application**

## 🔥 Hotkeys and Their Functions

### 🌍 Push Windows Around
| Hotkey | Action |
|--------|--------|
| `Win + H` | Push Window Left |
| `Win + J` | Push Window Up |
| `Win + K` | Push Window Down |
| `Win + L` | Push Window Right |

### 🖥️ Virtual Desktop Shortcuts -  Desktops must be created first
| Hotkey | Action |
|--------|--------|
| `Win + 1-9`         | Switch to Desktop **(1-9)** |
| `Win + Shift + 1-9` | Move current window to Desktop **(1-9)** |

### 🔄 Window Switching
| Hotkey | Action |
|--------|--------|
| `Win + .` | Switch to Next window  (`Alt+Tab` alternative) |
| `Win + ,` | Switch to previous window (`Shift+Alt+Tab` altinative) |

### 🖥️ Terminal Shortcuts
| Hotkey | Action |
|--------|--------|
| `Win + F12` | Open **Priviledged Terminal** |
| `Win + Enter` | Open or activate **Ubuntu** terminal |
| `Win + Shift + Enter` | Open **Ubuntu** in new terminal tab |

### 🌐 Browser & Media Player
| Hotkey | Action |
|--------|--------|
| `Win + C` | Open or activate the **default browser** |
| `Win + M` | Open or activate **AIMP media player** |

### 🪟 Window Management
| Hotkey | Action |
|--------|--------|
| `Win + F` | Maximize/Restore the active window |
| `Win + Q` | Close the active window |

### 🛠️ Script & System Management
| Hotkey | Action |
|--------|--------|
| `Ctrl + S` | Reload AHK script if editing in Visual Studio Code |
| `Alt + Shift + F11` | Restart Windows Explorer |
| `Alt + .` | Cycle to the **previous** window of the same app |
| `Alt + ,` | Cycle to the **next** window of the same app |

## 📝 Notes
- Ensure applications like **PowerShell, Ubuntu, AIMP, and your browser** are properly installed.
- This script is optimized for **Windows** users who frequently switch between virtual desktops and applications.
- The `Win + M` hotkey is currently set for **AIMP**. If you prefer **Spotify**, uncomment and modify the respective section.

Feel free to customize the script to fit your workflow! 🚀
