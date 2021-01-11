syntax enable
set background=dark " so colors are easier to read
set encoding=utf-8
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
set shiftwidth=4    " number of spaces in indent (><)
set expandtab       " tabs are spaces
"set number              " show line numbers
"set relativenumber      " relative line numbers
set showcmd             " show command in bottom bar
"set cursorline          " highlight current line
set showmatch           " highlight matching [{()}]
set incsearch           " search as characters are entered
set hlsearch            " highlight matches
set matchpairs+=<:>,«:»,‹:›,‘:’,“:”,⟨:⟩,⟪:⟫
set autoread            " detect changed file and read (load) it
set listchars=tab:>·    " show tab as >···
set list
set textwidth=0         " do not physically break long lines
set wrapmargin=0        " do not physically break pasted text
set foldmethod=indent   " fold by indent level
set foldlevelstart=99   " ... but keep all folds open from start
set ruler               " show cursor position and relative file position
"set visualbell          " do not beep

" default leader is \  Change with: let mapleader = ","
map <space> <Leader>
nnoremap <Leader><space> :set hlsearch!<cr>
nnoremap <Leader>v :vsplit **/*
nnoremap <Leader>s :split **/*
nnoremap <Leader>e :edit **/*
nnoremap <Leader>t :tabnew **/*
nnoremap <Leader>w :w<cr>
" insert newline above:
nnoremap <Leader>O v<Esc>O<Esc>`<
" insert newline below:
nnoremap <Leader>o v<Esc>o<Esc>`<
" insert space:
nnoremap <Leader>i i<Space><Esc>l

"<Esc> = Alt
inoremap <Esc>a å
inoremap <Esc>A Å
inoremap <Esc>' æ
inoremap <Esc>" Æ
inoremap <Esc>o ø
"<Esc>O interferes with arrow keys, and I cannot get <Esc>O<nop> working
inoremap <Esc>: Ø

"augroup configgroup
"    autocmd!
"    autocmd FileType sh setlocal noexpandtab
"augroup END

