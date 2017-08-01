syntax enable
set encoding=utf-8
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
set shiftwidth=4    " number of spaces in indent (><)
set expandtab       " tabs are spaces
set number              " show line numbers
set showcmd             " show command in bottom bar
set cursorline          " highlight current line
set showmatch           " highlight matching [{()}]
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
set matchpairs+=<:>,«:»,‹:›,‘:’,“:”,⟨:⟩,⟪:⟫
set autoread            " detect changed file and read (load) it
set listchars=tab:>-    " show tab as >---
set list
set textwidth=0         " do not physically break long lines
set wrapmargin=0        " do not physically break pasted text

"augroup configgroup
"    autocmd!
"    autocmd FileType sh setlocal noexpandtab
"augroup END

