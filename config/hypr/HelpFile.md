# Welcome to my Hyprland help, and tips and tricks #
# If you have questions, or need help you can open issue on my github
# Or you can reach me in or join on Discord that I admin
# Discord link https://discord.gg/V2SJ92vbEN  
# Github page: https://github.com/JaKooLit

  Super = Windows Key

# common operations
  Super Shift    H        *keyhint* (THIS DOCUMENT)
  Super          Return   *term* (`kitty`)
  Super          q        *quit* (kill focused window)
  Super   Shift  q        *quit* (kill focused window)
  Super          d        *show app menu* (`rofi`)

# Scripts (Power menu, waybar-layout menu, wallpaper menu, etc, have small box)
  - All the scripts all located in ~/.config/hypr/scripts.
  
# wallpaper / styling stuff
  Super           w       *wallpaper shuffle* (right click on wallpaper   waybar module)
  Super   Shift   w       *waybar style-change* (middle click on wallpaper   waybar module)
  Super   Ctrl    w       *wallpaper select* (click on wallpaper waybar    module) add more wallpaper in ~/Pictures/wallpapers
  
  - right click on update   waybar module  *wallpaper cycle using swww*
  
  - for the wallpaper styles and configurations, you can watch my video about it *https://youtu.be/6ZGzOjMJBe4*
  
  - scripts for wallpaper stuff are located in *~/.config/hypr/scripts* file names `DarkLight.sh` `Wallpaper.sh` `WallpaperSelect.sh` `WaybarStyles.sh` (last one for waybar)

# Monitor, executables, keybindings, window rules, 
  files are located in *~/.config/hypr/configs* . View with SUPER E
  Keybindings file is located here *~/.config/hypr/configs/Keybinds.conf*

# screenshot may need to hold down the function (`fn`) key. You can change keybinds in *~/.config/hypr/configs/Keybinds.conf* 
  Super PrintScr(button)       *full screenshot*
  Super Shift PrintSrc(button) *active window screenshot*         
  Super CTRL SHIFT PrintScr    *full screenshot + timer (5s)*
  Super Alt PrintScr           *full screenshot + timer (10s)*
  Super Shift S                *screenshot with swappy* (NOT AVAILABLE FOR DEBIAN/UBUNTU)

# clipboard manager (cliphist)
  Super Alt V   *launch the rofi menu of clipboard manager* 
    - click to select the clipboard. And paste as normal (CTRL V or right click menu)
    - to clean up clipboard manager, launch kitty (super enter) then type ```cliphist wipe```

# applications shortcuts
  Super   T		  *file manager* (`thunar`) - if installed
    
# container layout
  Super   Shift   Space       *toggle tiling/floating mode*
  Super   Shift   F           *toggle all windows in float mode*
  Super   left mouse button   *move window*
  Super   right mouse button  *resize window* (note! only in float mode)

# workspaces
  Super         1 .. 0    *switch to workspace 1 .. 10*
  Super  Shift  1 .. 0    *move container to workspace 1 .. 10*
  Super   Tab             *cycle through workspaces*
  Super Shift Tab         *cycle previous workspaces*

# waybar customizations
  - waybar font too big or too small. Edit the font-size in waybar styles located in ~/.config/waybar/styles/ . By default, it is set to 98%. After adjusting the GTK font scaling to your liking, edit all the waybar styles. Reduce or increase according to your needs. NOTE that its on percent %. You can also change to px whichever suits you. Note: This corresponds well with nwg-look

  - if you want 12h format instead of 24H format, edit the ~/.config/waybar/modules look for clock. delete the // and add // or delete the previous one

  - CPU Temperature:
    - a.) to change from deg C to deg F , edit the ~/.config/waybar/modules look for "temperature". Change the format to "format": "{temperatureF}°F {icon}",
    - b.) to fix the temperature if not showing correctly, comment "thermal zone": 0 by putting // before. Delete the // on the "hwmon path". Refresh waybar by pressing SUPER SHIFT W or SUPER ALT W If still not showing correctly, navigate to /sys/class/hwmon/ and open each hwmon. Look for k10temp for amd. Not sure about intel cpu. and edit accordingly the hwmon path in the "temperature" waybar module.
    - b.1) use this function to easily identify the hwmon path. Ran this in your terminal    ``` for i in /sys/class/hwmon/hwmon*/temp*_input; do echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*})) $(readlink -f $i)"; done ```
  
  - Weather.sh (Default weather app in waybar) edit ~/.config/hypr/scripts/Weather.sh or Weather.py and add your city. Make sure a major city in your Area. Delete rbn folder in ~/.cache and refresh waybar by either pressing SUPER SHIFT W or choose waybar layout SUPER ALT W. If wanted to use Weather.py for weather, edit weather module located in  ~/.config/waybar/modules.

# Hyprland configurations
  - *Hyprland* configuration files are in `~/.config/hypr/configs` Can view using SUPER E
  - files located in this folder can be edited using editor of your choice.

# notes for nvidia gpu users
  - Do note that you need to enable or disable some items in ENVariables.conf file located in `~/.config/hypr/configs/ENVariables.conf`
  
  - a guide on wiki - https://wiki.hyprland.org/Nvidia/

# other notes
  - *Multimedia keys* - may not work for every keyboard may need to hold down the function (`fn`) key
  - Follow the wiki - https://wiki.hyprland.org/
  - Follow the github - https://github.com/hyprwm/Hyprland

# If you dont like kitty or in your tty to get the pywal colors, edit ~/.config/kitty/kitty.conf or .zshrc (for zsh)

# HIDDEN FEATURES!

  - ROFI BEATS or ONLINE Music ( SUPER SHIFT S)
  - EMOTICONS (SUPER ALT E) - useful for chats or messages )
