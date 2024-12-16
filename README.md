<h3 align="center">
<img align="center" width="80%" src=https://github.com/user-attachments/assets/bc18bd4d-944b-4d5f-a119-7578fa38f9b4 />
</h3>

<div align="center">
<br>
  <a href="#installation"><kbd> <br> Installation <br> </kbd></a>&ensp;&ensp;
  <a href="https://www.youtube.com/playlist?list=PLDtGd5Fw5_GjXCznR0BzCJJDIQSZJRbxx"><kbd> <br> Youtube <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/wiki"><kbd> <br> Wiki <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/discussions"><kbd> <br> Discussions <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/wiki/Keybinds"><kbd> <br> Keybinds <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/wiki/FAQ"><kbd> <br> FAQ <br> </kbd></a>&ensp;&ensp;
  <a href="https://discord.gg/9JEgZsfhex"><kbd> <br> Discord <br> </kbd></a>
</div><br>

<div align="center">

![GitHub Repo stars](https://img.shields.io/github/stars/JaKooLit/Hyprland-Dots?style=for-the-badge&color=cba6f7) ![GitHub last commit](https://img.shields.io/github/last-commit/JaKooLit/Hyprland-Dots?style=for-the-badge&color=b4befe) ![GitHub repo size](https://img.shields.io/github/repo-size/JaKooLit/Hyprland-Dots?style=for-the-badge&color=cba6f7) <a href="https://discord.gg/9JEgZsfhex"> <img src="https://img.shields.io/discord/1151869464405606400?style=for-the-badge&logo=discord&color=cba6f7&link=https%3A%2F%2Fdiscord.gg%9JEgZsfhex"> </a>

<br/>
</div>

<h3 align="center">
	<img src="https://github.com/JaKooLit/Telegram-Animated-Emojis/blob/main/Activity/Sparkles.webp" alt="Sparkles" width="38" height="38" />
	KooL's Hyprland Dotfiles Showcase 
	<img src="https://github.com/JaKooLit/Telegram-Animated-Emojis/blob/main/Activity/Sparkles.webp" alt="Sparkles" width="38" height="38" />
</h3>

<div align="center">

https://github.com/JaKooLit/Hyprland-Dots/assets/85185940/50d53755-0f11-45d6-9913-76039e84a2cd

</div>

#### 📹 A video walkthroughs
<details>
  <summary>YT Videos</summary>

- [Walkthough](https://youtu.be/fO-RBHvVEcc)

- [V1-Changes](https://youtu.be/upDl1ns05eg)

- [v2-Changes](https://youtu.be/yaVurRoXc-s)

#### 📽️ A video coverage by other users. Pls watch and subscribe to their channel
- [`Link`](https://github.com/JaKooLit/Hyprland-Dots/wiki/Videos_and_Reviews)

</details>

## Installation 
### 👁️‍🗨️ My Hyprland install Scripts 👁️‍🗨️
- Automated Hyprland Scripts for Distro of choices:

- [Arch-Linux](https://github.com/JaKooLit/Arch-Hyprland)

- [OpenSUSE(Tumbleweed)](https://github.com/JaKooLit/OpenSuse-Hyprland)

- [Fedora-Linux](https://github.com/JaKooLit/Fedora-Hyprland)

- [Debian Trixie / SiD](https://github.com/JaKooLit/Debian-Hyprland)

- [Ubuntu 24.04 LTS](https://github.com/JaKooLit/Ubuntu-Hyprland/tree/24.04)

- [NixOS](https://github.com/JaKooLit/NixOS-Hyprland)

#### Hyprland Install scripts on alpha/beta stage

- [Ubuntu 24.10)](https://github.com/JaKooLit/Ubuntu-Hyprland/tree/24.10)

- refer to install scripts what packages needed to install... but atleast, Hyprland packages is needed 😏😏😏 duh!!
- When using the install scripts above, it will pull the releases (stable) of this dotfiles, except for Nixos where it pulls from main


### 🪧 Attention 🪧
- This repo does NOT contain or will NOT install any packages. These are only hyprland configs or dotfiles
- This repo will be pulled by the Distro-Hyprland install scripts above if you opt to download pre-configured dots

### 👀 Screenshots 👀
- All screenshots are collected here [Screenshots](https://github.com/JaKooLit/screenshots/tree/main/Hyprland-ScreenShots)

### 📦 Whats new?
- To easily track changes, I will be updating the [CHANGELOGS](https://github.com/JaKooLit/Hyprland-Dots/wiki/Changelogs)  Screenshots will be included if worth it!

### 💥 Copying / Installation / Update instructions 💥
- [`MORE INFO HERE`](https://github.com/JaKooLit/Hyprland-Dots/wiki/Install_&_Update) 
> [!Note] 
> The auto copy script "copy.sh" will create backups of intended folders to be copied. However, still a good idea to manually backup just incase script failed to backup!
- ~/.config (ags btop cava hypr kitty Kvantum qt5ct qt6ct rofi swappy swaync wallust waybar wlogout) - These are folders to be copied.
- ~/Pictures/wallpapers - Will be backed up
- clone this repo by using git. Change directory, make executable and run the script

> to download from Master branch
```bash
git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git
cd Hyprland-Dots
```

> to download from Development branch (development and testing)
```bash
git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git -b development
cd Hyprland-Dots
```

- automatic copy of pre-configured dots
```bash
chmod +x copy.sh
./copy.sh
```

- to copy/install from releases (stable)
```bash
chmod +x release.sh
./release.sh
```

- UPGRADE.sh function
> [!IMPORTANT]
> You need rsync for it to work
> you should have already up and running KooL's Hyprland before using this function
```bash
chmod +x upgrade.sh
./upgrade.sh
```

## ⚠️⚠️⚠️ ATTENTION - BACKUPS CREATED by SCRIPT
> [!CAUTION]
> copy.sh, release.sh and even upgrade.sh creates a backup!
> Kindly investigate manually contents on your ~/.config
> Delete manually all the backups which you dont need

#### 🛎️ a small note on wallpapers
- by default, only few wallpapers will be copied (1 each dark and light plus 3 more). You will be offered to download more wallpapers. You can preview/check the additional wallpapers from [`THIS`](https://github.com/JaKooLit/Wallpaper-Bank/tree/main/wallpapers) Link


#### ⚠️⚠️⚠️ A MUST! after copying  / Installing these dots
+ Press SUPER W and set a wallpaper. This is also to initiate wallust for waybar, kitty (tty) and rofi themes. However, If you use the copy.sh or the release.sh, there will be a preset initial Wallpaper and you dont have to do this

+ Nvidia Owners. Make sure to edit your `~/.config/hypr/UserConfigs/ENVariables.conf` (recommended). Below env's will be activated if automatic copy is used
> WLR_NO_CURSORS,1 , LIBVA_DRIVER_NAME,nvidia ,  __GLX_VENDOR_LIBRARY_NAME,nvidia 
- NVIDIA users / owners, after installation, check [`THIS`](https://github.com/JaKooLit/Hyprland-Dots/wiki/Notes_to_remember#--for-nvidia-gpu-users)

+ If you have already set your own keybinds, monitors, etc.... Just copy over from backup created before log-out or reboot. (recommended)


#### 📖 Known issues and possible solutions
- check out this page [FAQ](https://github.com/JaKooLit/Hyprland-Dots/wiki/FAQ) and [UNSOLVED ISSUES](https://github.com/JaKooLit/Hyprland-Dots/wiki/Known_Issues)


#### 🙋 QUESTIONS ?!?! ⁉️
- FAQ! Yes you can use these dotfiles to other distro! Just ensure to install proper packages first! If it makes you feel better, I use same config on my Gentoo and NixOS :)
- QUICK HINT! Click the HINT! Waybar module (note only available in Waybar default and Simple-L [TOP] layout). Can be launched by Keybind SUPER H
- More question? click here browse through this [WIKI](https://github.com/JaKooLit/Hyprland-Dots/wiki/)
- If you want the old configs, it is collected on my "Archive" repo. See [HERE](https://github.com/JaKooLit/Hyprland-Dots-releases-Archive)

#### ⌨ Keybinds
- Keybinds [`CLICK`](https://github.com/JaKooLit/Hyprland-Dots/wiki/Keybinds)

#### 🙏 Special request
- If you have improvements on the dotfiles or configuration, feel free to submit a PR for improvement. I always welcome improvements as I am also just learning just like you guys!
- Waybar styles (all those new panel styles require some tweaking) - I kindly request assistance 🙏


#### 🤷‍♂️ TO DO!
- [ ] Tweak dots - 🚧 in constant progress 
- ~~[ ] Quite possibly switch to starship? Although starship has limited themes compared to oh-my-zsh.~~ no plans for now


#### 🔮 Discord Server
- kindly join my [Discord](https://discord.com/invite/9JEgZsfhex)


### 💖 Support
- a Star on my Github repos would be nice 🌟

- Subscribe to my Youtube Channel [YouTube](https://www.youtube.com/@Ja.KooLit) 

- You can also buy me Coffee Through ko-fi.com or Coffee.com 🤩

<a href='https://ko-fi.com/jakoolit' target='_blank'><img height='35' style='border:0px;height:46px;' src='https://az743702.vo.msecnd.net/cdn/kofi3.png?v=0' border='0' alt='Buy Me a Coffee at ko-fi.com' />

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/JaKooLit)


                        
## 🫰	Thank you for the stars 🩷

<a href="https://star-history.com/#JaKooLit/Hyprland-Dots&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=JaKooLit/Hyprland-Dots&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=JaKooLit/Hyprland-Dots&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=JaKooLit/Hyprland-Dots&type=Date" />
 </picture>
</a>

