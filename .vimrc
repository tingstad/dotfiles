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
set laststatus=2        " always show status line
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c,%o%V%)\ %P  " show (line,column),byte offset (+1)

set timeout timeoutlen=1000 ttimeoutlen=50
autocmd InsertEnter * set timeoutlen=20
autocmd InsertLeave * set timeoutlen=1000

" default leader is \  Change with: let mapleader = ","
map <space> <Leader>
nnoremap <Leader><space> :set hlsearch!<cr>
nnoremap <Leader>v :vsplit <C-r>=expand("%:p:h")<Enter>/**/*
nnoremap <Leader>s :split <C-r>=expand("%:p:h")<Enter>/**/*
nnoremap <Leader>e :edit <C-r>=expand("%:p:h")<Enter>/**/*
nnoremap <Leader>t :tabnew <C-r>=expand("%:p:h")<Enter>/**/*
nnoremap <Leader>w :w<cr>
" insert newline above:
nnoremap <Leader>O v<Esc>O<Esc>`<
" insert newline below:
nnoremap <Leader>o v<Esc>o<Esc>`<
" insert em dash:
nnoremap <Leader>- i—<Esc>
" insert space:
nnoremap <Leader>i i<Space><Esc>l
" inline variable:
nnoremap <Leader>n #2dWy$dd<C-o>viw"0p
" search for selection (use register s):
vnoremap <leader>/ "sy/\V<C-R>=escape(@s,'/\')<CR><CR>

" insert one letter (<Esc> = Alt):
nnoremap <Leader>a a<Space><Esc>r
nnoremap <Leader>i i<Space><Esc>r
nnoremap <Leader>A A<Space><Esc>r

"<Esc> = Alt
inoremap <Esc>a å
inoremap <Esc>A Å
inoremap <Esc>' æ
inoremap <Esc>" Æ
inoremap <Esc>o ø
inoremap <Esc>O Ø
"<Esc>O interferes with arrow keys, but this helps:
inoremap <Esc>OD <Left>

"augroup configgroup
"    autocmd!
"    autocmd FileType sh setlocal noexpandtab
"augroup END

