-- Config from Drew @justaguylinux small mods

local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.enable_wayland = true

-- Enable if starship prompt won't start
-- config.default_prog = { "/usr/bin/env zsh" }

-- General appearance and visuals
config.hide_tab_bar_if_only_one_tab = true
-- Set primary font with fallbacks

config.font = wezterm.font_with_fallback({
  { family = "Fira Code", weight = 250, stretch = "Normal", style = "Normal" }, -- Thin variant
  "Fira Code",
  "JetBrains Mono",
  "Hack",
})

-- Previous font config
--  font = wezterm.font("Maple Mono NF")
font_size = 14

config.colors = {
  tab_bar = {

    active_tab = {
      bg_color = "#80bfff", -- col_gray2 (selected tab in bright blue)
      fg_color = "#00141d", -- contrast text on active tab
    },

    inactive_tab = {
      bg_color = "#1a1a1a", -- col_gray4 (dark background for inactive tabs)
      fg_color = "#FFFFFF", -- col_gray3 (white text on inactive tabs)
    },

    new_tab = {
      bg_color = "#1a1a1a", -- same as inactive
      fg_color = "#4fc3f7", -- col_barbie (for the "+" button)
    },
  },
}

config.window_background_opacity = 1.0
-- config.color_scheme = "nightfox"
-- config.color_scheme = 'AdventureTime'
-- config.color_scheme = 'Advark Blue'
config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = 'Dracula'
config.font_size = 12
config.font = wezterm.font("FiraCode", { weight = "Regular", italic = false })

config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

config.use_fancy_tab_bar = true
config.window_frame = {
  -- font = wezterm.font({ family = "FiraCode Nerd Font Mono", weight = "Regular" }),
  font = wezterm.font({ family = "JetBrainsMono Nerd Font Mono", weight = "Regular" }),
}

config.default_cursor_style = "BlinkingUnderline"
config.cursor_blink_rate = 500
config.term = "xterm-256color"
config.bold_brightens_ansi_colors = false
config.max_fps = 120
config.animation_fps = 30

-- Keybindings using ALT for tabs & splits
config.keys = {
  -- Tab management
  { key = "t", mods = "ALT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "ALT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  { key = "n", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
  { key = "p", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },

  -- Pane management
  { key = "v", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "q", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

  -- Pane navigation (move between panes with ALT + Arrows)
  { key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
}

-- Disable missing glyph warnings, since we have fallback fonts now
config.warn_about_missing_glyphs = false

-- function for nvidia_gpu
local function is_nvidia_gpu()
  local handle = io.popen("lspci | grep -i nvidia")
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

-- NVIDIA optimization settings
-- config.enable_wayland = not is_nvidia_gpu() -- Disable Wayland if NVIDIA GPU is detected
-- config.front_end = "OpenGL"  -- More stable than WebGPU with NVIDIA
-- config.webgpu_power_preference = "HighPerformance"
-- config.prefer_egl = true
-- config.freetype_load_target = "Light"
-- config.freetype_render_target = "HorizontalLcd"

return config
