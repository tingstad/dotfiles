syntax enable
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
set expandtab       " tabs are spaces
set number              " show line numbers
set showcmd             " show command in bottom bar
set cursorline          " highlight current line
set showmatch           " highlight matching [{()}]
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
set matchpairs+=<:>,«:»,‹:›,‘:’,“:”,⟨:⟩,⟪:⟫

augroup configgroup
    autocmd!
    autocmd FileType sh setlocal noexpandtab
augroup END

