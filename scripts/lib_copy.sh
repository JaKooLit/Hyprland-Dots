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
  install_terminal_configs "$log"
}

# Restore Animations and Monitor Profiles plus key hypr files from backup
restore_hypr_assets() {
  local log="$1"
  local express_mode="$2"

  local HYPR_DIR="$HOME/.config/hypr"
  local BACKUP_DIR
  BACKUP_DIR=$(get_backup_dirname)
  local BACKUP_HYPR_PATH="$HYPR_DIR-backup-$BACKUP_DIR"

  if [ -d "$BACKUP_HYPR_PATH" ]; then
    if [ "$express_mode" -eq 1 ]; then
      echo "${NOTE:-[NOTE]} Express mode: skipping automatic restoration of animations and monitor profiles." 2>&1 | tee -a "$log"
      return
    fi

    echo -e "\n${NOTE:-[NOTE]} Restoring ${SKY_BLUE:-}Animations & Monitor Profiles${RESET:-} into ${YELLOW:-}$HYPR_DIR${RESET:-}..."

    local DIR_B=("Monitor_Profiles" "animations" "wallpaper_effects")
    for DIR_RESTORE in "${DIR_B[@]}"; do
      local BACKUP_SUBDIR="$BACKUP_HYPR_PATH/$DIR_RESTORE"
      if [ -d "$BACKUP_SUBDIR" ]; then
        cp -r "$BACKUP_SUBDIR" "$HYPR_DIR/" 2>&1 | tee -a "$log"
        echo "${OK:-[OK]} - Restored directory: ${MAGENTA:-}$DIR_RESTORE${RESET:-}" 2>&1 | tee -a "$log"
      fi
    done

    local FILE_B=("monitors.conf" "workspaces.conf")
    for FILE_RESTORE in "${FILE_B[@]}"; do
      local BACKUP_FILE="$BACKUP_HYPR_PATH/$FILE_RESTORE"
      if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$HYPR_DIR/$FILE_RESTORE" 2>&1 | tee -a "$log"
        echo "${OK:-[OK]} - Restored file: ${MAGENTA:-}$FILE_RESTORE${RESET:-}" 2>&1 | tee -a "$log"
      fi
    done
  fi
}

# Helper to extract overlay additions/disables from previous user file vs base
compose_overlay_from_backup() {
  local type="$1" # startup|windowrules
  local base_file="$2"
  local old_user_file="$3"
  local new_user_file="$4"
  local disable_file="$5"

  mkdir -p "$(dirname "$new_user_file")"
  : >"$new_user_file"
  : >"$disable_file"

  if [ "$type" = "startup" ]; then
    grep -E '^\s*exec-once\s*=' "$old_user_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$old_user_file.tmp.exec"
    grep -E '^\s*exec-once\s*=' "$base_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$base_file.tmp.exec"
    comm -23 "$old_user_file.tmp.exec" "$base_file.tmp.exec" >"$new_user_file"
    grep -E '^\s*#\s*exec-once\s*=' "$old_user_file" |
      sed -E 's/^\s*#\s*exec-once\s*=\s*//' |
      sed -E 's/^\s+//;s/\s+$//' |
      grep -Ev '^\$scriptsDir/KeybindsLayoutInit\.sh$' |
      sort -u >"$disable_file"
    rm -f "$old_user_file.tmp.exec" "$base_file.tmp.exec"
  elif [ "$type" = "windowrules" ]; then
    grep -E '^(windowrule|layerrule)\s*=' "$old_user_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$old_user_file.tmp.rules"
    grep -E '^(windowrule|layerrule)\s*=' "$base_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$base_file.tmp.rules"
    comm -23 "$old_user_file.tmp.rules" "$base_file.tmp.rules" >"$new_user_file"
    grep -E '^\s*#\s*(windowrule|layerrule)\s*=' "$old_user_file" | sed -E 's/^\s*#\s*//' | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$disable_file"
    rm -f "$old_user_file.tmp.rules" "$base_file.tmp.rules"
  fi
}

cleanup_duplicate_userconfigs() {
  local current_version="$1"
  local log="$2"

  if [ -z "$current_version" ]; then
    return
  fi
  if ! version_gte "$current_version" "2.3.18"; then
    return
  fi

  local HYPR_DIR="$HOME/.config/hypr"
  local BASE_DIR="$HYPR_DIR/configs"
  local USER_DIR="$HYPR_DIR/UserConfigs"

  local STARTUP_BASE="$BASE_DIR/Startup_Apps.conf"
  local STARTUP_USER="$USER_DIR/Startup_Apps.conf"
  local WINDOW_BASE="$BASE_DIR/WindowRules.conf"
  local WINDOW_USER="$USER_DIR/WindowRules.conf"

  if [ -f "$STARTUP_BASE" ] && [ -f "$STARTUP_USER" ]; then
    local tmp_startup
    local backup_startup
    backup_startup="$STARTUP_USER.backup-dupfix-$(date +%Y%m%d-%H%M%S)"
    tmp_startup=$(mktemp)
    awk '
      function trim(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      FNR==NR {
        if ($0 ~ /^[ \t]*exec-once[ \t]*=/) {
          line=trim($0)
          base[line]=1
        }
        next
      }
      {
        if ($0 ~ /^[ \t]*exec-once[ \t]*=/) {
          line=trim($0)
          if (line in base) next
        }
        print
      }
    ' "$STARTUP_BASE" "$STARTUP_USER" >"$tmp_startup"
    if ! cmp -s "$STARTUP_USER" "$tmp_startup"; then
      cp "$STARTUP_USER" "$backup_startup"
      mv "$tmp_startup" "$STARTUP_USER"
      echo "${NOTE:-[NOTE]} - Removed duplicate Startup_Apps entries matching base config." 2>&1 | tee -a "$log"
    else
      rm -f "$tmp_startup"
    fi
  fi

  if [ -f "$WINDOW_BASE" ] && [ -f "$WINDOW_USER" ]; then
    local tmp_window
    local backup_window
    backup_window="$WINDOW_USER.backup-dupfix-$(date +%Y%m%d-%H%M%S)"
    tmp_window=$(mktemp)
    awk '
      function trim(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      FNR==NR {
        if ($0 ~ /^[ \t]*(windowrule|layerrule)[ \t]*=/) {
          line=trim($0)
          base[line]=1
        }
        next
      }
      {
        if ($0 ~ /^[ \t]*(windowrule|layerrule)[ \t]*=/) {
          line=trim($0)
          if (line in base) next
        }
        print
      }
    ' "$WINDOW_BASE" "$WINDOW_USER" >"$tmp_window"
    if ! cmp -s "$WINDOW_USER" "$tmp_window"; then
      cp "$WINDOW_USER" "$backup_window"
      mv "$tmp_window" "$WINDOW_USER"
      echo "${NOTE:-[NOTE]} - Removed duplicate WindowRules entries matching base config." 2>&1 | tee -a "$log"
    else
      rm -f "$tmp_window"
    fi
  fi
}
restore_user_configs() {
  local log="$1"
  local express_mode="$2"

  local DIRPATH="$HOME/.config/hypr"
  local BACKUP_DIR
  BACKUP_DIR=$(get_backup_dirname)
  local BACKUP_DIR_PATH="$DIRPATH-backup-$BACKUP_DIR/UserConfigs"

  if [ -z "$BACKUP_DIR" ]; then
    echo "${ERROR:-[ERROR]} - Backup directory name is empty. Exiting." 2>&1 | tee -a "$log"
    exit 1
  fi

  if [ -d "$BACKUP_DIR_PATH" ] && [ "$express_mode" -eq 1 ]; then
    echo "${NOTE:-[NOTE]} Express mode: skipping UserConfigs restoration prompts." 2>&1 | tee -a "$log"
    return
  fi

  if [ -d "$BACKUP_DIR_PATH" ] && [ "$express_mode" -eq 0 ]; then
    local VERSION_FILE
    VERSION_FILE=$(find "$DIRPATH" -maxdepth 1 -name "v*.*.*" | head -n 1)
    local CURRENT_VERSION="999.9.9"
    if [ -n "$VERSION_FILE" ]; then
      CURRENT_VERSION=$(basename "$VERSION_FILE" | sed 's/^v//')
    fi

    local TARGET_VERSION="2.3.19"

    echo -e "${NOTE:-[NOTE]} Restoring previous ${MAGENTA:-}User-Configs${RESET:-}... " 2>&1 | tee -a "$log"
    printf "${WARNING:-}\
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█\n\
            NOTES for RESTORING PREVIOUS CONFIGS\n\
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█\n\n\
    The 'UserConfigs' directory is for all your personal settings.\n\
    Files in this directory will override the default configurations,\n\
    so your customizations are not lost when you update.\n\
" >&2

    if version_gte "$CURRENT_VERSION" "$TARGET_VERSION"; then
      read -r -p "${CAT:-[ACTION]} Do you want to restore your previous UserConfigs directory? (Y/n): " restore_userconfigs_dir
      if [[ "$restore_userconfigs_dir" != [Nn]* ]]; then
        echo "${NOTE:-[NOTE]} Restoring UserConfigs directory..." 2>&1 | tee -a "$log"
        rsync -a "$BACKUP_DIR_PATH/" "$DIRPATH/UserConfigs/" 2>&1 | tee -a "$log"
        echo "${OK:-[OK]} - UserConfigs directory restored." 2>&1 | tee -a "$log"
      else
        echo "${NOTE:-[NOTE]} - Skipped restoring UserConfigs." 2>&1 | tee -a "$log"
      fi
    else
      echo -e "${NOTE:-[NOTE]} Detected version ${YELLOW:-}v$CURRENT_VERSION${RESET:-} (older than v$TARGET_VERSION). Using legacy restoration mode." 2>&1 | tee -a "$log"

      local FILES_TO_RESTORE=(
        "01-UserDefaults.conf"
        "ENVariables.conf"
        "LaptopDisplay.conf"
        "Laptops.conf"
        "Startup_Apps.conf"
        "UserDecorations.conf"
        "UserAnimations.conf"
        "UserKeybinds.conf"
        "UserSettings.conf"
        "WindowRules.conf"
      )

      for FILE_NAME in "${FILES_TO_RESTORE[@]}"; do
        local BACKUP_FILE="$BACKUP_DIR_PATH/$FILE_NAME"
        if [ -f "$BACKUP_FILE" ]; then
          if [ "$FILE_NAME" = "Startup_Apps.conf" ]; then
            compose_overlay_from_backup "startup" "$DIRPATH/configs/Startup_Apps.conf" "$BACKUP_FILE" "$DIRPATH/UserConfigs/Startup_Apps.conf" "$DIRPATH/UserConfigs/Startup_Apps.disable"
            echo "${OK:-[OK]} - Migrated overlay for ${YELLOW:-}$FILE_NAME${RESET:-}" 2>&1 | tee -a "$log"
            continue
          fi
          if [ "$FILE_NAME" = "WindowRules.conf" ]; then
            compose_overlay_from_backup "windowrules" "$DIRPATH/configs/WindowRules.conf" "$BACKUP_FILE" "$DIRPATH/UserConfigs/WindowRules.conf" "$DIRPATH/UserConfigs/WindowRules.disable"
            echo "${OK:-[OK]} - Migrated overlay for ${YELLOW:-}$FILE_NAME${RESET:-}" 2>&1 | tee -a "$log"
            continue
          fi

          printf "\n${INFO:-[INFO]} Found ${YELLOW:-}$FILE_NAME${RESET:-} in hypr backup...\n"
          read -r -p "${CAT:-[ACTION]} Do you want to restore ${YELLOW:-}$FILE_NAME${RESET:-} from backup? (Y/n): " file_restore

          if [[ "$file_restore" != [Nn]* ]]; then
            if cp "$BACKUP_FILE" "$DIRPATH/UserConfigs/$FILE_NAME"; then
              echo "${OK:-[OK]} - $FILE_NAME restored!" 2>&1 | tee -a "$log"
            else
              echo "${ERROR:-[ERROR]} - Failed to restore $FILE_NAME!" 2>&1 | tee -a "$log"
            fi
          else
            echo "${NOTE:-[NOTE]} - Skipped restoring $FILE_NAME." 2>&1 | tee -a "$log"
          fi
        fi
      done
    fi
  fi

  if [ -n "$CURRENT_VERSION" ]; then
    cleanup_duplicate_userconfigs "$CURRENT_VERSION" "$log"
  else
    local detected_version
    detected_version=$(get_installed_dotfiles_version)
    if [ -n "$detected_version" ]; then
      cleanup_duplicate_userconfigs "$detected_version" "$log"
    fi
  fi
}

restore_user_scripts() {
  local log="$1"
  local express_mode="$2"

  local DIRSHPATH="$HOME/.config/hypr"
  local BACKUP_DIR
  BACKUP_DIR=$(get_backup_dirname)
  local BACKUP_DIR_PATH_S="$DIRSHPATH-backup-$BACKUP_DIR/UserScripts"
  local SCRIPTS_TO_RESTORE=("RofiBeats.sh" "Weather.py" "Weather.sh")

  if [ -d "$BACKUP_DIR_PATH_S" ] && [ "$express_mode" -eq 1 ]; then
    echo "${NOTE:-[NOTE]} Express mode: skipping UserScripts restoration prompts." 2>&1 | tee -a "$log"
    return
  fi

  if [ -d "$BACKUP_DIR_PATH_S" ] && [ "$express_mode" -eq 0 ]; then
    echo -e "${NOTE:-[NOTE]} Restoring previous ${MAGENTA:-}User-Scripts${RESET:-}..." 2>&1 | tee -a "$log"

    for SCRIPT_NAME in "${SCRIPTS_TO_RESTORE[@]}"; do
      local BACKUP_SCRIPT="$BACKUP_DIR_PATH_S/$SCRIPT_NAME"
      if [ -f "$BACKUP_SCRIPT" ]; then
        printf "\n${INFO:-[INFO]} Found ${YELLOW:-}$SCRIPT_NAME${RESET:-} in hypr backup...\n"
        read -r -p "${CAT:-[ACTION]} Do you want to restore ${YELLOW:-}$SCRIPT_NAME${RESET:-} from backup? (y/N): " script_restore

        if [[ "$script_restore" == [Yy]* ]]; then
          if cp "$BACKUP_SCRIPT" "$DIRSHPATH/UserScripts/$SCRIPT_NAME"; then
            echo "${OK:-[OK]} - $SCRIPT_NAME restored!" 2>&1 | tee -a "$log"
          else
            echo "${ERROR:-[ERROR]} - Failed to restore $SCRIPT_NAME!" 2>&1 | tee -a "$log"
          fi
        else
          echo "${NOTE:-[NOTE]} - Skipped restoring $SCRIPT_NAME." 2>&1 | tee -a "$log"
        fi
      fi
    done
  fi
}

restore_hypr_files() {
  local log="$1"
  local express_mode="$2"

  local DIRPATH="$HOME/.config/hypr"
  local BACKUP_DIR
  BACKUP_DIR=$(get_backup_dirname)
  local BACKUP_DIR_PATH_F="$DIRPATH-backup-$BACKUP_DIR"
  local FILES_2_RESTORE=("hyprlock.conf" "hypridle.conf")

  if [ -d "$BACKUP_DIR_PATH_F" ] && [ "$express_mode" -eq 1 ]; then
    echo "${NOTE:-[NOTE]} Express mode: skipping individual hypr file restoration prompts." 2>&1 | tee -a "$log"
    return
  fi

  if [ -d "$BACKUP_DIR_PATH_F" ] && [ "$express_mode" -eq 0 ]; then
    echo -e "${NOTE:-[NOTE]} Restoring some files in ${MAGENTA:-}$HOME/.config/hypr directory${RESET:-}..." 2>&1 | tee -a "$log"

    for FILE_RESTORE in "${FILES_2_RESTORE[@]}"; do
      local BACKUP_FILE="$BACKUP_DIR_PATH_F/$FILE_RESTORE"
      if [ -f "$BACKUP_FILE" ]; then
        echo -e "\n${INFO:-[INFO]} Found ${YELLOW:-}$FILE_RESTORE${RESET:-} in hypr backup..."
        read -r -p "${CAT:-[ACTION]} Do you want to restore ${YELLOW:-}$FILE_RESTORE${RESET:-} from backup? (y/N): " file2restore

        if [[ "$file2restore" == [Yy]* ]]; then
          if cp "$BACKUP_FILE" "$DIRPATH/$FILE_RESTORE"; then
            echo "${OK:-[OK]} - $FILE_RESTORE restored!" 2>&1 | tee -a "$log"
          else
            echo "${ERROR:-[ERROR]} - Failed to restore $FILE_RESTORE!" 2>&1 | tee -a "$log"
          fi
        else
          echo "${NOTE:-[NOTE]} - Skipped restoring $FILE_RESTORE." 2>&1 | tee -a "$log"
        fi
      else
        echo "${ERROR:-[ERROR]} - Backup file $BACKUP_FILE does not exist." 2>&1 | tee -a "$log"
      fi
    done
  fi
}
