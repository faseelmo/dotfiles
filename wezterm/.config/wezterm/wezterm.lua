local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font setup
config.font = wezterm.font('JetBrains Mono', {weight = 'Light'})
config.font_size = 20.0

-- Color scheme
config.color_scheme = 'Tokyo Night'

-- Window
config.window_background_opacity = 0.90  -- (0.0 = transparent, 1.0 = opaque)
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- Key bindings --
config.keys = {
  -- Split Right / Vertically (Terminator: Ctrl + Shift + E)
  {
    key = 'E',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Split Down / Horizontally (Terminator: Ctrl + Shift + O)
  {
    key = 'O',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Close Pane (Terminator: Ctrl + Shift + W)
  {
    key = 'W',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- Pane Navigation
  {
    key = 'LeftArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'ALT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
}

-- AUTOMATED TAB SWITCHING (Alt + 1 through Alt + 9)
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'ALT',
    action = wezterm.action.ActivateTab(i - 1), -- Subtract 1 because Lua is 1-indexed and WezTerm tabs are 0-indexed
  })
end

return config
