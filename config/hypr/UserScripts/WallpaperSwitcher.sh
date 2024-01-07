#!/bin/bash
cd $1
result=$(find . -type f|fzf \
--reverse --header="WallPaperSwitcher" --preview-window=44% \
--preview='kitten icat --clear --transfer-mode=memory --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES"@$(math $COLUMNS+5)x1 --align center --stdin=no -z -1 {}')
#?? Maybe its a good idea to make a global function for changing wallpaper, something like :$hypr_dir/Scirpt/ChangeWallpapper.sh "SomePic.jpg"
#so if you change wallpaper somewhere else,the workflow stay the same.
#and you can move SWWW_PARAMS to the Wallpaper.conf so user can change that without touching the scirpt
swww img "$result"
exit 0
