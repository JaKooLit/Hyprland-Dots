# Check for available updates and count them
updates=$(dnf check-update --quiet | grep -E '^[a-zA-Z0-9]' | wc -l)
updatesFlatpak=$(flatpak remote-ls --updates | wc -l)
updatesFlatpak=$((updatesFlatpak - 1))

updates=$((updates + updatesFlatpak))

echo "# $updates"
