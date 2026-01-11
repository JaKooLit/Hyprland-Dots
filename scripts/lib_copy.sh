#!/usr/bin/env bash
# Copy helpers split into phases to keep copy.sh lean.

copy_phase1() {
  local log="$1"
  local dirs="fastfetch kitty rofi swaync"
  for DIR2 in $dirs; do
    local DIRPATH="$HOME/.config/$DIR2"
    if [ -d "$DIRPATH" ]; then
      while true; do
        printf "\n${INFO:-[INFO]} Found ${YELLOW:-}$DIR2${RESET:-} config found in ~/.config/\n"
        echo -n "${CAT:-[ACTION]} Do you want to replace ${YELLOW:-}$DIR2${RESET:-} config? (y/n): "
        read DIR1_CHOICE
        case "$DIR1_CHOICE" in
          [Yy]*) BACKUP_DIR=$(get_backup_dirname)
                 mv "$DIRPATH" "$DIRPATH-backup-$BACKUP_DIR" 2>&1 | tee -a "$log"
                 echo -e "${NOTE:-[NOTE]} - Backed up $DIR2 to $DIRPATH-backup-$BACKUP_DIR." 2>&1 | tee -a "$log"
                 cp -r "config/$DIR2" "$HOME/.config/$DIR2" 2>&1 | tee -a "$log"
                 echo -e "${OK:-[OK]} - Replaced $DIR2 with new configuration." 2>&1 | tee -a "$log"
                 if [ "$DIR2" = "rofi" ]; then
                   if [ -d "$DIRPATH-backup-$BACKUP_DIR/themes" ]; then
                     for file in "$DIRPATH-backup-$BACKUP_DIR/themes"/*; do
                       [ -e "$file" ] || continue
                       cp -n "$file" "$HOME/.config/rofi/themes/" >>"$log" 2>&1 || true
                     done || true
                   fi
                   if [ -f "$DIRPATH-backup-$BACKUP_DIR/0-shared-fonts.rasi" ]; then
                     cp "$DIRPATH-backup-$BACKUP_DIR/0-shared-fonts.rasi" "$HOME/.config/rofi/0-shared-fonts.rasi" >>"$log" 2>&1
                   fi
                 fi
                 break ;;
          [Nn]*) echo -e "${NOTE:-[NOTE]} - Skipping ${YELLOW:-}$DIR2${RESET:-}" 2>&1 | tee -a "$log"; break ;;
          *) echo -e "${WARN:-[WARN]} - Invalid choice. Please enter Y or N." ;;
        esac
      done
    else
      cp -r "config/$DIR2" "$HOME/.config/$DIR2" 2>&1 | tee -a "$log"
      echo -e "${OK:-[OK]} - Copy completed for ${YELLOW:-}$DIR2${RESET:-}" 2>&1 | tee -a "$log"
    fi
  done
}

copy_waybar() {
  local log="$1"
  local DIRW="waybar"
  local DIRPATHw="$HOME/.config/$DIRW"
  if [ -d "$DIRPATHw" ]; then
    while true; do
      echo -n "${CAT:-[ACTION]} Do you want to replace ${YELLOW:-}$DIRW${RESET:-} config? (y/n): "
      read DIR1_CHOICE
      case "$DIR1_CHOICE" in
        [Yy]*) BACKUP_DIR=$(get_backup_dirname)
               cp -r "$DIRPATHw" "$DIRPATHw-backup-$BACKUP_DIR" 2>&1 | tee -a "$log"
               echo -e "${NOTE:-[NOTE]} - Backed up $DIRW to $DIRPATHw-backup-$BACKUP_DIR." 2>&1 | tee -a "$log"
               rm -rf "$DIRPATHw" && cp -r "config/$DIRW" "$DIRPATHw" 2>&1 | tee -a "$log"
               for file in "config" "style.css"; do
                 symlink="$DIRPATHw-backup-$BACKUP_DIR/$file"
                 target_file="$DIRPATHw/$file"
                 if [ -L "$symlink" ]; then
                   symlink_target=$(readlink "$symlink")
                   if [ -f "$symlink_target" ]; then
                     rm -f "$target_file" && cp -f "$symlink_target" "$target_file"
                   fi
                 fi
               done
               for dir in "$DIRPATHw-backup-$BACKUP_DIR/configs"/*; do
                 [ -e "$dir" ] || continue
                 if [ -d "$dir" ]; then
                   target_dir="$HOME/.config/waybar/configs/$(basename "$dir")"
                   [ -d "$target_dir" ] || cp -r "$dir" "$HOME/.config/waybar/configs/"
                 fi
               done
               for file in "$DIRPATHw-backup-$BACKUP_DIR/configs"/*; do
                 [ -e "$file" ] || continue
                 target_file="$HOME/.config/waybar/configs/$(basename "$file")"
                 [ -e "$target_file" ] || cp "$file" "$HOME/.config/waybar/configs/"
               done || true
               for file in "$DIRPATHw-backup-$BACKUP_DIR/style"/*; do
                 [ -e "$file" ] || continue
                 if [ -d "$file" ]; then
                   target_dir="$HOME/.config/waybar/style/$(basename "$file")"
                   [ -d "$target_dir" ] || cp -r "$file" "$HOME/.config/waybar/style/"
                 else
                   target_file="$HOME/.config/waybar/style/$(basename "$file")"
                   [ -e "$target_file" ] || cp "$file" "$HOME/.config/waybar/style/"
                 fi
               done || true
               BACKUP_FILEw="$DIRPATHw-backup-$BACKUP_DIR/UserModules"
               [ -f "$BACKUP_FILEw" ] && cp -f "$BACKUP_FILEw" "$DIRPATHw/UserModules"
               break ;;
        [Nn]*) echo -e "${NOTE:-[NOTE]} - Skipping ${YELLOW:-}$DIRW${RESET:-} config replacement." 2>&1 | tee -a "$log"; break ;;
        *) echo -e "${WARN:-[WARN]} - Invalid choice. Please enter Y or N." ;;
      esac
    done
  else
    cp -r "config/$DIRW" "$DIRPATHw" 2>&1 | tee -a "$log"
    echo -e "${OK:-[OK]} - Copy completed for ${YELLOW:-}$DIRW${RESET:-}" 2>&1 | tee -a "$log"
  fi
}

copy_phase2() {
  local log="$1"
  local DIR="btop cava hypr Kvantum qt5ct qt6ct swappy wallust wlogout"
  for DIR_NAME in $DIR; do
    local DIRPATH="$HOME/.config/$DIR_NAME"
    if [ -d "$DIRPATH" ]; then
      echo -e "\n${NOTE:-[NOTE]} - Config for ${YELLOW:-}$DIR_NAME${RESET:-} found, attempting to back up."
      BACKUP_DIR=$(get_backup_dirname)
      mv "$DIRPATH" "$DIRPATH-backup-$BACKUP_DIR" 2>&1 | tee -a "$log"
    fi
    if [ -d "config/$DIR_NAME" ]; then
      cp -r "config/$DIR_NAME/" "$HOME/.config/$DIR_NAME" 2>&1 | tee -a "$log"
      echo "${OK:-[OK]} - Copy of config for ${YELLOW:-}$DIR_NAME${RESET:-} completed!" 2>&1 | tee -a "$log"
    else
      echo "${ERROR:-[ERROR]} - Directory config/$DIR_NAME does not exist to copy." 2>&1 | tee -a "$log"
    fi
  done
  # Ghostty
  local GHOSTTY_SRC="config/ghostty/ghostty.config"
  local GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
  local GHOSTTY_DEST="$GHOSTTY_DIR/config"
  if [ -f "$GHOSTTY_SRC" ]; then
    mkdir -p "$GHOSTTY_DIR"
    install -m 0644 "$GHOSTTY_SRC" "$GHOSTTY_DEST" 2>&1 | tee -a "$log"
    if [ -f "$GHOSTTY_DIR/wallust.conf" ]; then
      sed -i -E 's/^(\\s*palette\\s*=\\s*)([0-9]{1,2}):/\\1\\2=/' "$GHOSTTY_DIR/wallust.conf" 2>&1 | tee -a "$log" || true
    fi
  else
    echo "${ERROR:-[ERROR]} - $GHOSTTY_SRC not found; skipping Ghostty config install." 2>&1 | tee -a "$log"
  fi
  # WezTerm
  local WEZTERM_SRC="config/wezterm/wezterm.lua"
  local WEZTERM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm"
  local WEZTERM_DEST="$WEZTERM_DIR/wezterm.lua"
  if [ -f "$WEZTERM_SRC" ]; then
    mkdir -p "$WEZTERM_DIR"
    install -m 0644 "$WEZTERM_SRC" "$WEZTERM_DEST" 2>&1 | tee -a "$log"
  else
    echo "${ERROR:-[ERROR]} - $WEZTERM_SRC not found; skipping WezTerm config install." 2>&1 | tee -a "$log"
  fi
}
