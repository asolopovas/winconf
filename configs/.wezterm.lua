local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Color scheme - Custom Legacy scheme matching Windows Terminal
config.color_schemes = {
  ['Legacy'] = {
    ansi = {
      '#000000', -- black
      '#FF5555', -- red
      '#269685', -- green
      '#FFB86C', -- yellow
      '#0049a3', -- blue
      '#6272A4', -- purple
      '#6272A4', -- cyan
      '#AEC2E0', -- white
    },
    brights = {
      '#555555', -- bright black
      '#FF5555', -- bright red
      '#50FA7B', -- bright green
      '#FFF361', -- bright yellow
      '#4565AD', -- bright blue
      '#FF79C6', -- bright purple
      '#8BE9FD', -- bright cyan
      '#FFFFFF', -- bright white
    },
    foreground = '#F8F8F2',
    background = '#14191F',
    cursor_bg = '#FFFFFF',
    cursor_fg = '#14191F',
    cursor_border = '#FFFFFF',
    selection_fg = '#000000',
    selection_bg = '#FFFFFF',
  },
}

config.color_scheme = 'Legacy'

-- Font configuration
config.font = wezterm.font('FiraMono Nerd Font Mono')
config.font_size = 14.0

-- Window configuration
config.window_background_opacity = 0.95
config.window_decorations = "TITLE | RESIZE"
config.initial_cols = 140
config.initial_rows = 35
config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}

-- Tab configuration
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Shell configuration
config.default_prog = { 'powershell.exe' }
config.skip_close_confirmation_for_processes_named = { 'bash', 'sh', 'zsh', 'fish', 'tmux', 'nu', 'cmd.exe', 'pwsh.exe', 'powershell.exe' }
config.window_close_confirmation = 'NeverPrompt'

-- Terminal behavior
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.alternate_buffer_wheel_scroll_speed = 1
config.treat_east_asian_ambiguous_width_as_wide = false

-- Launch menu
config.launch_menu = {
  {
    label = 'PowerShell (Admin)',
    args = { 'powershell.exe' },
    domain = { DomainName = 'local' },
  },
}

-- Keybindings
config.keys = {
  {
    key = 'F11',
    action = wezterm.action.ToggleFullScreen,
  },
  {
    key = 'Enter',
    mods = 'ALT',
    action = wezterm.action.ToggleFullScreen,
  },
}

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  local gui_window = window:gui_window()

  if gui_window then
    local screen = wezterm.gui.screens().active
    local window_width = 1536
    local window_height = 864

    local x = math.floor((screen.width - window_width) / 2)
    local y = math.floor((screen.height - window_height) / 2)

    gui_window:set_position(x, y)
    gui_window:set_inner_size(window_width, window_height)
  end
end)

return config
