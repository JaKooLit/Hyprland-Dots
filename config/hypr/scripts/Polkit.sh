#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for polkits, it will start from top and will stop if the top is executed

# Polkit possible paths files to check
polkit=(
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
  "/usr/libexec/hyprpolkitagent"
  "/usr/lib/hyprpolkitagent"
  "/usr/lib/polkit-kde-authentication-agent-1"
  "/usr/lib/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-mate-authentication-agent-1"
  "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
)

executed=false  # Flag to track if a file has been executed

# Loop through the list of files
for file in "${polkit[@]}"; do
  if [ -e "$file" ]; then
    echo "File $file found, executing command..."
    exec "$file"  
    executed=true
    break
  fi
done

# If none of the files were found, you can add a fallback command here
if [ "$executed" == false ]; then
  echo "None of the specified files were found. Install a Polkit"
fi
