<h3 align="center">
<img align="center" width="80%" src=https://github.com/user-attachments/assets/bc18bd4d-944b-4d5f-a119-7578fa38f9b4 />
</h3>

<p align="center">
  <img src="https://raw.githubusercontent.com/JaKooLit/Hyprland-Dots/main/assets/latte.png" width="400" />
</p>

<h3 align="center">

## 💌 KooL's Ubuntu Hyprland Dotfiles 💌
### This repo is Hyprland Dotfiles for Ubuntu 24.04 Only

</h3>


<div align="center">
<br>
  <a href="#installation"><kbd> <br> Installation <br> </kbd></a>&ensp;&ensp;
  <a href="https://www.youtube.com/playlist?list=PLDtGd5Fw5_GjXCznR0BzCJJDIQSZJRbxx"><kbd> <br> Youtube <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/wiki"><kbd> <br> Wiki <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/discussions"><kbd> <br> Discussions <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/wiki/Keybinds"><kbd> <br> Keybinds <br> </kbd></a>&ensp;&ensp;
  <a href="https://github.com/JaKooLit/Hyprland-Dots/wiki/FAQ"><kbd> <br> FAQ <br> </kbd></a>&ensp;&ensp;
  <a href="https://discord.gg/kool-tech-world"><kbd> <br> Discord <br> </kbd></a>
</div><br>

<div align="center">

![GitHub Repo stars](https://img.shields.io/github/stars/JaKooLit/Hyprland-Dots?style=for-the-badge&color=cba6f7) ![GitHub last commit](https://img.shields.io/github/last-commit/JaKooLit/Hyprland-Dots?style=for-the-badge&color=b4befe) ![GitHub repo size](https://img.shields.io/github/repo-size/JaKooLit/Hyprland-Dots?style=for-the-badge&color=cba6f7) <a href="https://discord.gg/kool-tech-world"> <img src="https://img.shields.io/discord/1151869464405606400?style=for-the-badge&logo=discord&color=cba6f7&link=https%3A%2F%2Fdiscord.gg%kool-tech-world"> </a>

<br/>
</div>

<h3 align="center">
	<img src="https://github.com/JaKooLit/Telegram-Animated-Emojis/blob/main/Activity/Sparkles.webp" alt="Sparkles" width="38" height="38" />
	KooL's Hyprland Dotfiles Showcase 
	<img src="https://github.com/JaKooLit/Telegram-Animated-Emojis/blob/main/Activity/Sparkles.webp" alt="Sparkles" width="38" height="38" />
</h3>

<div align="center">

https://github.com/user-attachments/assets/49bc12b2-abaf-45de-a21c-67aacd9bb872

</div>

#### 📹 A video walkthroughs
- at the bottom

#### 🎞️ AGS Overview DEMO
- in case you wonder, here is a short demo of AGS overview [Youtube LINK](https://youtu.be/zY5SLNPBJTs)

</details>

## 🚩 🏁 Auto Distro-Hyprland install scripts cloning and starting 🇵🇭
- NOTE: you need package `curl` for this to work

```bash
sh <(curl -L https://raw.githubusercontent.com/JaKooLit/Hyprland-Dots/main/Distro-Hyprland.sh)
```
- if you are using say fish or a non-POSIX compliant
```bash
curl -sL https://raw.githubusercontent.com/JaKooLit/Hyprland-Dots/main/Distro-Hyprland.sh | bash
```

- you can now use above command to automatically clone the Distro-Hyprland install scripts below
- it will clone the install scripts and start the `install.sh` 😎

## Installation 
### 👁️‍🗨️ Kool's Hyprland install Scripts for Ubuntu 24.04 Hyprland install scripts   👁️‍🗨️
- [Ubuntu 24.04](https://github.com/JaKooLit/Ubuntu-Hyprland/tree/24.04)


### 🪧 Attention 🪧
- This repo does NOT contain or will NOT install any packages. These are only pre-configured-hyprland configs or dotfiles
- This  branch was created so its easier to bring some minor tweaks to Ubuntu 24.04 Hyprland installs scripts
- refer to install scripts above what packages needed to install... but atleast, Hyprland packages are needed 😏😏😏 duh!!
- This repo will be pulled by the Ubuntu 24.04-Hyprland install scripts above if you opt to download pre-configured dots

### 👀 Screenshots 👀
- All screenshots are collected here [Screenshots](https://github.com/JaKooLit/screenshots/tree/main/Hyprland-ScreenShots)

### 📦 Whats new?
- To easily track changes, I will be updating the [CHANGELOGS](https://github.com/JaKooLit/Hyprland-Dots/wiki/Changelogs)  Screenshots will be included if worth mentioning the changes!

### 💥 Copying / Installation / Update instructions 💥
- [`MORE INFO HERE`](https://github.com/JaKooLit/Hyprland-Dots/wiki/Install_&_Update) 
> [!Note] 
> The auto copy script "copy.sh" will create backups of intended folders to be copied. However, still a good idea to manually backup just incase script failed to backup!
- clone this repo by using git. Change directory, make executable and run the script

> to download from `Ubuntu-24.04-Dots` branch
```bash
git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git -b Ubuntu-24.04-Dots ~/Hyprland-Dots-Ubuntu-24.04
cd Hyprland-Dots-Ubuntu-24.04
```
- automatic copy/install of pre-configured dots
```bash
chmod +x copy.sh
./copy.sh
```

## ❗❗❗ DEBIAN AND UBUNTU HEADS UP!
- I am getting ridiculously amount of messages for updating your KooL Hyprland dotfiles. I have made a BIG note on [`WIKI`](https://github.com/JaKooLit/Hyprland-Dots/wiki/Install_&_Update)


#### ⚠️⚠️⚠️ ATTENTION - BACKUPS CREATED by SCRIPT
> [!CAUTION]
> copy.sh, release.sh and even upgrade.sh creates a backup!
> Kindly investigate manually contents on your $HOME/.config
> Delete manually all the backups which you dont need

#### 🛎️ a small note on wallpapers
- by default, only few wallpapers will be copied (1 each dark and light plus 3 more). You will be offered to download more wallpapers. You can preview/check the additional wallpapers from [`THIS`](https://github.com/JaKooLit/Wallpaper-Bank/tree/main/wallpapers) Link


#### ⚠️⚠️⚠️ A MUST! after copying  / Installing these dots
+ Press SUPER W and set a wallpaper. This is also to initiate wallust for waybar, kitty (tty) and rofi themes. However, If you use the copy.sh or the release.sh, there will be a preset initial Wallpaper and you dont have to do this

+ Nvidia Owners. Make sure to edit your `~/.config/hypr/UserConfigs/ENVariables.conf` (highly recommended).
- NVIDIA users / owners, after installation, check [`THIS`](https://github.com/JaKooLit/Hyprland-Dots/wiki/Notes_to_remember#--for-nvidia-gpu-users)

+ If you have already set your own keybinds, monitors, etc.... Just copy over from backup created before log-out or reboot. (recommended)


#### 📖 Known issues and possible solutions
- check out this page [FAQ](https://github.com/JaKooLit/Hyprland-Dots/wiki/FAQ) and [UNSOLVED ISSUES](https://github.com/JaKooLit/Hyprland-Dots/wiki/Known_Issues)


#### 🙋 QUESTIONS ?!?! ⁉️
- FAQ! Yes you can use these dotfiles to other distro! Just ensure to install proper packages first! If it makes you feel better, I use same config on my Gentoo:)
- QUICK HINT! Click the HINT! Waybar module (note only available in Waybar default and Simple-L [TOP] layout). Can be launched by Keybind `SUPER H`
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
- kindly join my [Discord](https://discord.com/invite/kool-tech-world)


### 💖 Support
- a Star on my Github repos would be nice 🌟

- Subscribe to my Youtube Channel [YouTube](https://www.youtube.com/@Ja.KooLit) 

- you can also give support through coffee's or btc 😊

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/jakoolit)

or

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/JaKooLit)

Or you can donate cryto on my btc wallet :)  
> 1N3MeV2dsX6gQB42HXU6MF2hAix1mqjo8i

![Bitcoin](https://github.com/user-attachments/assets/7ed32f8f-c499-46f0-a53c-3f6fbd343699)


                        
## 🫰	Thank you for the stars 🩷

<a href="https://star-history.com/#JaKooLit/Hyprland-Dots&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=JaKooLit/Hyprland-Dots&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=JaKooLit/Hyprland-Dots&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=JaKooLit/Hyprland-Dots&type=Date" />
 </picture>
</a>