#!/usr/bin/env bash
# Detection and environment adjustment helpers shared by copy.sh.

# Nvidia tweaks: uncomments envs and adjusts hardware cursor setting.
detect_nvidia_adjust() {
  local log="$1"
  if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    echo "${INFO:-[INFO]} Nvidia GPU detected. Setting up proper env's and configs" 2>&1 | tee -a "$log" || true
    sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' config/hypr/configs/ENVariables.conf
    sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^#//' config/hypr/configs/ENVariables.conf
    sed -i '/env = NVD_BACKEND,direct/s/^#//' config/hypr/configs/ENVariables.conf
    sed -i '/env = GSK_RENDERER,ngl/s/^#//' config/hypr/configs/ENVariables.conf
    sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1 1/' config/hypr/configs/SystemSettings.conf
  fi
}

# VM tweaks: enable software renderer envs and virtual monitor defaults.
detect_vm_adjust() {
  local log="$1"
  if hostnamectl | grep -q 'Chassis: vm'; then
    echo "${INFO:-[INFO]} System is running in a virtual machine. Setting up proper env's and configs" 2>&1 | tee -a "$log" || true
    sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1 1/' config/hypr/configs/SystemSettings.conf
    sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' config/hypr/configs/ENVariables.conf
    sed -i '/monitor = Virtual-1, 1920x1080@60,auto,1/s/^#//' config/hypr/monitors.conf
  fi
}

# NixOS tweaks: ensure polkit overlay is enabled and default disabled.
detect_nixos_adjust() {
  local log="$1"
  if hostnamectl | grep -q 'Operating System: NixOS'; then
    echo "${INFO:-[INFO]} NixOS Distro Detected. Setting up proper env's and configs." 2>&1 | tee -a "$log" || true
    local OVERLAY_SA="config/hypr/configs/Startup_Apps.conf"
    local DISABLE_SA="config/hypr/configs/Startup_Apps.disable"
    mkdir -p "$(dirname "$OVERLAY_SA")"
    touch "$OVERLAY_SA" "$DISABLE_SA"
    grep -qx 'exec-once = $scriptsDir/Polkit-NixOS.sh' "$OVERLAY_SA" || echo 'exec-once = $scriptsDir/Polkit-NixOS.sh' >>"$OVERLAY_SA"
    grep -qx '\$scriptsDir/Polkit.sh' "$DISABLE_SA" || echo '$scriptsDir/Polkit.sh' >>"$DISABLE_SA"
  fi
}

# Decide waybar config/style based on chassis type. Echoes chosen config path.
detect_waybar_config() {
  if hostnamectl | grep -q 'Chassis: desktop'; then
    echo "desktop"
  else
    echo "laptop"
  fi
}
