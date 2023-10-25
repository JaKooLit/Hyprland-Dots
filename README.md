<div align="center">

# 💌 ** JaKooLit Hyprland Dot Files ** 💌

![GitHub Repo stars](https://img.shields.io/github/stars/JaKooLit/Hyprland-Dots?style=for-the-badge&color=cba6f7) ![GitHub last commit](https://img.shields.io/github/last-commit/JaKooLit/Hyprland-Dots?style=for-the-badge&color=b4befe) ![GitHub repo size](https://img.shields.io/github/repo-size/JaKooLit/Hyprland-Dots?style=for-the-badge&color=cba6f7)

<br/>
</div>

## 👁️‍🗨️ My Hyprland install Scripts 👁️‍🗨️

- [Arch-Linux](https://github.com/JaKooLit/Hyprland-v4)

- [Fedora-Linux](https://github.com/JaKooLit/Fedora-Hyprland)

- [Debian/Ubuntu-Linux](https://github.com/JaKooLit/Debian-Hyprland)


### ❗❗ This is basically to re-construct my previous hyprland dot files
- why? Generally, alot of users, especially new users are confused with my original layout. In which waybar, dunst, swaylock, etc are inside ~/.config/hypr , which is originally meant for Hyprland configuration only.

- This would ultimately mean much easier for users to use other waybar, or hyprland dots from other Hyprland users who are sharing their dotfiles. - (Make me sad, although, I am still glad you tried my install script and dotfiles)

- But my main reason for creating this repo, is that, in the future, I will be focusing only into one repo, as I aimed to just download and install this repo for any install script that I will be using or wanted to share. Less maintainance for me and to avoid errors.

- Users of my Hyprland install scripts, Arch-Hyprlands, Fedora-Hyprland, Debian/Ubuntu-Hyprland, upgrade to these dotfiles/configuration to replace their previous dots.

### 📦 Changelogs
- To easily track changes, I will be updating the changelogs. [CHANGELOGS](https://github.com/JaKooLit/Hyprland-Dots/blob/main/CHANGELOG.md)  Screenshots will be included if worth it!


## ✨ Copying instructions. 
- Note! The auto copy script will create backups of intended folders to be copied. However, still a good idea to manually backup just incase script failed to backup!

- ~/.config (btop, cava, dunst, foot, hypr, swappy, swaylock, waybar, wofi) - These are folders to be copied.
- ~/Pictures/wallpapers - Will be backed up

### 🔔 Automatic copy of configurations
> clone this repo by using git. Change directory, make executable and run the script
```bash
git clone https://github.com/JaKooLit/Hyprland-Dots.git
cd Hyprland-Dots
chmod +x copy.sh
./copy.sh
```
### 🐌 Manual installation (not recommended for newbies)
- Backup your existing folders in ~/.config (advisable)
- copy all contents of configs into ~/.config, overwriting all
- copy contents of wallpapers into ~/Pictures/wallpapers/ (create wallpapers folder if required)
- make the Hyprland scripts executable 
```bash
chmod +x $HOME/.config/hypr/scripts/*
```
- Make sure to execute initial symlinks else dunst, wofi and waybar will fail to launch
```bash
ln -sf "$HOME/.config/waybar/configs/config-default" "$HOME/.config/waybar/config"
ln -sf "$HOME/.config/waybar/style/style-dark.css" "$HOME/.config/waybar/style.css"
ln -sf "$HOME/.config/dunst/styles/dunstrc-dark" "$HOME/.config/dunst/dunstrc"
ln -sf "$HOME/.config/wofi/styles/style-dark.css" "$HOME/.config/wofi/style.css"
ln -sf "$HOME/.config/wofi/configs/config-default" "$HOME/.config/wofi/config"
```

### ⚠️⚠️⚠️ A MUST! after copying these dots
- By default I have not set a wallpaper. If using swww, just press SUPER CTRL W and choose wallpaper. Once you reboot or logged out, the last wallpaper will be loaded by swww automatically.
- If not using swww, edit ~/.config/hypr/Execs.conf and set using swaybg
- Nvidia Owners. Make sure to edit your ~/.config/hypr/configs/ENVariables.conf if you have set a proper environment already. (recommended). WLR_NO_CURSORS will be activated if nvidia gpu is detected.
- If you have already set your own keybinds, monitors, etc.... Just copy over from backup created before log-out or reboot. (recommended)

### 📖 Known issues and possibly solutions
- Foot tty fonts after copying dots is broken - Install Fira Code or just restore your previous foot configuration in ~/.config/foot
- Themes are broken when changing dark light - Ensure you have Tokyo Night Dark and Light themes installed and Tokyo Night SE icons or adjust the Dark Light script located in ~/.config/hypr/scripts/DarkLight.sh
- Keyboard shortcuts or customized Keybinds are broken! - Just copy over your previous Keybinds.conf from the hypr-backup in ~/.config/

### 🙋 QUESTIONS ?!?! ⁉️
- Maybe answered already in Help File! SUPER H to launch it!
- If you still have, kindly join my discord for faster communication. See invite link below. If not, open an issue on github

### 🙏 Special request
- If you have improvements on the dotfiles or configuration, feel free to submit a PR for improvement. I always welcome improvements as I am also just learning just like you guys!
- Waybar styles (all those new panel styles require some tweaking) - I kindly request assistance 🙏

### 🤷‍♂️ TO DO!
- [ ] After Arch update the hyprland package, will uncomment line 38 to 44 in ~/.config/hypr/configs/Settings.conf. Users of hyprland-git or if compiled from source, you can safely uncomment these lines (group and groupbar)
- [ ] Tweak waybar layouts and Themes
- [ ] Integrate these dotfiles into my Hyprland install scripts for a centralized configurations

### 🔮 Discord Server
- kindly join my Discord Server https://discord.gg/V2SJ92vbEN

## 💖 Support
- a Star on my Github repos would be nice 🌟

- Subscribe to my Youtube Channel [YouTube](https://www.youtube.com/@Ja.KooLit) 

- You can also buy me Coffee Through ko-fi.com 🤩

<a href='https://ko-fi.com/jakoolit' target='_blank'><img height='35' style='border:0px;height:46px;' src='https://az743702.vo.msecnd.net/cdn/kofi3.png?v=0' border='0' alt='Buy Me a Coffee at ko-fi.com' />