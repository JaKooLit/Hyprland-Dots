# Welcome to my Hyprland help, and tips and tricks #
# If you have questions, or need help you can open issue on my github
# Or you can reach me in or join on Discord that I admin
# Discord link https://discord.gg/V2SJ92vbEN  
# Github page: https://github.com/JaKooLit

  Super = Windows Key

# common operations
  Super          h        *keyhint* (THIS DOCUMENT)
  Super          Return   *term* (`foot`)
  Super          q        *quit* (kill focused window)
  Super   Shift  q        *quit* (kill focused window)
  Super          d        *show app menu* (`wofi small`)
  Super   Shift  d        *show app menu* (`wofi large`)

# wallpaper / styling stuff
  Super           w       *wallpaper shuffle* (right click on wallpaper   waybar module)
  Super   Shift   w       *waybar style-change* (middle click on wallpaper   waybar module)
  Super   Ctrl    w       *wallpaper switcher* (click on wallpaper waybar    module)
  
  - right click on update   waybar module  *wallpaper cycle using swaybg* (no animations)
  
  - To change permanently the wallpaper edit the file in *~/.config/hypr/configs/Execs.conf*
  - For a persistent wallpaper after dark-light mode, edit your Execs.conf. Either delete or put # before exec-once=swww query | swww init and delete the # before exec-once = swww init (Lines 6 and 7 on Execs.conf )
  
  - for the wallpaper styles and configurations, you can watch my video about it *https://youtu.be/6ZGzOjMJBe4*
  
  - scripts for wallpaper stuff are located in *~/.config/hypr/scripts* file names `DarkLight.sh` `DarkLight-swaybg.sh` `Wallpaper.sh` `WallpaperSelect.sh` `WaybarStyles.sh` (last one for waybar)

  - swww is broken if you use fractional scaling. Use swaybg as your wallpaper provider.
  - Sample of swaybg for wallpaper is located in ~/.config/hypr/configs/Execs.conf

# Monitor, executables, keybindings, window rules, 
  files are located in *~/.config/hypr/configs*
  Keybindings file is located here *~/.config/hypr/configs/Keybinds.conf*

# screenshot may need to hold down the function (`fn`) key. You can change keybinds in *~/.config/hypr/configs/Keybinds.conf* 
  Super PrintScr(button)       *full screenshot*
  Super Shift PrintSrc(button) *active window screenshot*         
  Super CTRL SHIFT PrintScr    *full screenshot + timer (5s)*
  Super Alt PrintScr           *full screenshot + timer (10s)*
  Super Shift S                *screenshot with swappy*

# clipboard manager (cliphist)
  Super Alt V   *launch the wofi menu of clipboard manager* 
    - double click to select the clipboard. And paste as normal
    - to clean up clipboard manager, launch foot (super enter) then type cliphist wipe

# applications shortcuts
  Super   T		  *file manager* (`thunar`) - if installed

    
# container layout
  Super   Shift   Space       *toggle tiling/floating mode*
  Super   left mouse button   *move window*
  Super   right mouse button  *resize window* (note only in float mode)


# workspaces
  Super         1 .. 0    *switch to workspace 1 .. 10*
  Super  Shift  1 .. 0    *move container to workspace 1 .. 10*
  Super   Tab             *cycle through workspaces*

# waybar customizations
  - waybar font too big or too small. Edit the font-size in waybar styles located in ~/.config/hypr/waybar/styles/ . By default, it is set to 100%. After adjusting the GTK font scaling to your liking, edit all the waybar styles. Reduce or increase according to your needs. NOTE that its on percent %. You can also change to px whichever suits you.

  - if you want 12h format instead of 24H format, edit the ~/.config/hypr/waybar/modules look for clock. delete the // and add // or delete the previous one

  - CPU Temperature:
    - a.) to change from deg C to deg F , edit the ~/.config/hypr/waybar/modules look for "temperature". Change the format to "format": "{temperatureF}°F {icon}",
    - b.) to fix the temperature if not showing correctly, comment "thermal zone": 0 by putting // before. Delete the // on the "hwmon path". Refresh waybar by pressing CTRL SHIFT w. If still not showing correctly, navigate to /sys/class/hwmon/ and open each hwmon. Look for k10temp for amd. Not sure about intel cpu. and edit accordingly the hwmon path in the "temperature" waybar module.
    - b.1) use this function to easily identify the hwmon path. Ran this in your terminal    ``` for i in /sys/class/hwmon/hwmon*/temp*_input; do echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*})) $(readlink -f $i)"; done ```
  
  - Weather.sh (Default weather app in waybar) edit ~/.config/hypr/scripts/Weather.sh and add your city. Make sure a major city in your Area. Delete rbn folder in ~/.cache and refresh waybar by either pressing super shift w or choose waybar layout super alt w.

# Hyprland configurations
  - *Hyprland* configuration files are in `~/.config/hypr/`
  - files located in this folder can be edited using editor of your choice.

# notes for nvidia gpu users
  - Do note that you need to enable or disable some items in ENVariables.conf file located in `~/.config/hypr/configs/ENVariables.conf`
  
  - a guide on wiki - https://wiki.hyprland.org/Nvidia/


# other notes
  - *Multimedia keys* - may not work for every keyboard may need to hold down the function (`fn`) key
  - Follow the wiki - https://wiki.hyprland.org/
  - Follow the github - https://github.com/hyprwm/Hyprland



TO CLOSE THIS DOCUMENT - Super q or Super Shift q or if vim, press esc :q!
