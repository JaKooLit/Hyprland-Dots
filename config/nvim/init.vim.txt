" Basic Configurations
" FernuDev Github - https://github.com/Fernu292

set number
set mouse=a
syntax enable
set showcmd
set encoding=utf-8
set showmatch
set relativenumber

set expandtab
set tabstop=4
set shiftwidth=0
set softtabstop=0
set autoindent
set smarttab

call plug#begin()
	Plug 'nvim-lualine/lualine.nvim'
	Plug 'nvim-tree/nvim-web-devicons'
	Plug 'navarasu/onedark.nvim'
	Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
call plug#end()

" Calling the Lualine pluggin

colorscheme onedark 

lua << END
require('lualine').setup {
	options = {
		icons_enabled = true,
		theme = 'material'
	}
}

require('onedark').setup {
	style = "dark",
	transparent = true,
}

require('onedark').load()

END
