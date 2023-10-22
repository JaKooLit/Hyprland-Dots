<div align="center">

# 💌 ** JaKooLit Hyprland Dot Files ** 💌

![GitHub Repo stars](https://img.shields.io/github/stars/JaKooLit/Hyprland-Dots?style=for-the-badge&color=E08BCA) ![GitHub last commit](https://img.shields.io/github/last-commit/JaKooLit/Hyprland-Dots?style=for-the-badge&color=E08BCA) ![GitHub repo size](https://img.shields.io/github/repo-size/JaKooLit/Hyprland-Dots?style=for-the-badge&color=E08BCA)

<br/>
</div>

My Hyprland install Scripts
[Arch-Linux](https://github.com/JaKooLit/Hyprland-v4)
[Fedora-Linux](https://github.com/JaKooLit/Fedora-Hyprland)
[Debian/Ubuntu-Linux](https://github.com/JaKooLit/Debian-Hyprland)


### ❗❗ This is basically to re-construct my previous hyprland dot files
- why? Generally, alot of users, especially new users are confused with my original layout. In which waybar, dunst, swaylock, etc are inside ~/.config/hypr , which is originally mean for Hyprland configuration only.

- This would ultimately mean much easier for users to use other waybar, or hyprland dots from other Hyprland users who are sharing their dotfiles. - (Make me sad, although but I am still glad you tried my install script and dotfiles)

- But one of my reason for creating this repo, so that in the future, I will be focusing only into one repo, as I aimed to just download and install this repo for any install script that I will be using or wanted to share in the future.

- Users of my Hyprland install scripts, Arch-Hyprlands, Fedora-Hyprland, Debian/Ubuntu-Hyprland, can use this dotfiles to replace their previous dots.

### 📦 Changelogs
- In order for you to easily track changes, I will be updating the changelogs
[CHANGELOGS](https://github.com/JaKooLit/Hyprland-Dots/blob/main/CHANGELOG.md)

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
### 🐌 Manual installation
- Backup your existing folders in ~/.config (advisable)
- copy all contents of configs into ~/.config, overwriting all
- copy contents of wallpapers into ~/Pictures/wallpapers (create wallpapers folder if required)
- make the Hyprland scripts executable 
```bash
chmod +x ~/.config/hypr/scripts/*
```

### ⚠️⚠️⚠️ A MUST! after copying these dots
- By default I have not set a wallpaper. If using swww, just press SUPER CTRL W and choose wallpaper. Once you reboot, the last wallpaper will be loaded by swww
- If not using swww, edit ~/.config/hypr/Execs.conf and set using swaybg
- Nvidia Owners. Make sure to edit your ~/.config/hypr/configs/ENVariables.conf and uncomment atleast env = WLR_NO_HARDWARE_CURSORS,1 before log out or reboot. 
- If you have already set your own keybinds, monitors, etc.... Just copy over from backup created.

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
- <a href='https://ko-fi.com/jakoolit' target='_blank'><img height='35' style='border:0px;height:46px;' src='https://az743702.vo.msecnd.net/cdn/kofi3.png?v=0' border='0' alt='Buy Me a Coffee at ko-fi.com' />